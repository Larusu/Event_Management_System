import 'dart:async';
import 'dart:convert';

import 'package:backend/constants/error_codes.dart';
import 'package:backend/firebase_config.dart';
import 'package:backend/models/user.dart';
import 'package:backend/services/firebase_id_token_verifier.dart';
import 'package:backend/services/firestore_client.dart';
import 'package:backend/utils/response_helper.dart';

import 'package:firebase_admin/firebase_admin.dart';
import 'package:http/http.dart' as http;

/// Firebase Authentication Service
///
/// Handles user operations using:
/// - Firebase Admin SDK: creating/deleting Auth users, issuing custom tokens
/// - Firebase Identity Toolkit REST API:
///   - Verifying email/password on sign-in (Admin SDK has no password-check)
/// - Firestore REST API: the ONLY source of truth for role, name, contact,
///   and is_deleted. Nothing user-facing is ever stored in custom claims.
///
/// On failure, every method throws [AuthException] - callers (routes)
/// catch this one type and hand it to [ResponseHelper.error]. Nothing in
/// this file returns a success/failure Map for the caller to re-interpret.
class FirebaseAuthService {
  static Auth? _auth;

  static Auth get _firebaseAuth {
    final config = FirebaseConfig.app;
    if (config == null) {
      throw StateError('Firebase not initialized');
    }
    return _auth ??= config.auth();
  }

  // ---------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------

  /// Register a new user.
  ///
  /// Flow:
  ///   1. Create Firebase Auth user
  ///   2. Sign in via REST to get an ID token for the new account
  ///   3. Send verification email via Identity Toolkit (requires ID token)
  ///   4. Write Firestore document
  ///
  /// If the Firestore write fails, the Auth user is deleted so no orphaned
  /// accounts are left behind. The verification email is sent before the
  /// Firestore write — if the write then fails and we roll back, the email
  /// will have already been sent but the account won't exist, which is
  /// acceptable (the user simply tries to register again).
  static Future<Map<String, dynamic>> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String contactNumber,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final role = _determineRole(normalizedEmail);

    // Step 1: create the Firebase Auth account.
    String uid;
    try {
      final userRecord = await _firebaseAuth.createUser(
        email: normalizedEmail,
        password: password,
      );
      uid = userRecord.uid;
    } on FirebaseException catch (e) {
      if (e.code == 'auth/email-already-exists') {
        throw AuthException(
          AuthErrorCode.emailAlreadyExists,
          'An account with this email already exists.',
        );
      }
      throw AuthException(
        AuthErrorCode.internalError,
        'Registration failed: ${e.message}',
      );
    }

    // Step 2: write the Firestore document.
    final name = '$firstName $lastName'.trim();
    final createdAt = DateTime.now().toUtc().toIso8601String();

    try {
      await _writeUserDocument(
        uid: uid,
        email: normalizedEmail,
        name: name,
        contact: contactNumber,
        role: role,
        createdAt: createdAt,
      );
    } catch (e) {
      // Firestore write failed - don't leave an orphaned Auth user behind.
      await _deleteAuthUserSafely(uid);
      // ignore: avoid_print
      print('AUTH009 Step 2 (Firestore write) failed: $e');
      throw AuthException(
        AuthErrorCode.internalError,
        'Registration failed, please try again',
      );
    }

    final customToken = await _firebaseAuth.createCustomToken(uid);

    final user = User(
      uid: uid,
      email: normalizedEmail,
      name: name,
      contact: contactNumber,
      role: role,
      createdAt: createdAt,
    );

    return {'user': user, 'token': customToken};
  }

  /// Sign in with email and password.
  ///
  /// Password is verified via the Identity Toolkit REST API (NOT the
  /// Admin SDK - it has no password-check method). Role/name/contact are
  /// then read fresh from Firestore - never from a token or claim - so a
  /// role change made by faculty/super_admin takes effect on the user's
  /// very next sign-in with no stale-token window.
  static Future<Map<String, dynamic>> signInUser({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    final uid = await _verifyPasswordAndGetUid(
      email: normalizedEmail,
      password: password,
    );

    final userDoc = await _getUserDocument(uid);
    if (userDoc == null) {
      // Auth user exists but no Firestore doc - treat as not found rather
      // than leaking that the Auth account exists with a broken profile.
      throw AuthException(AuthErrorCode.userNotFound, 'User not found');
    }

    final isDeleted = userDoc['is_deleted'] as bool? ?? false;
    if (isDeleted) {
      throw AuthException(
        AuthErrorCode.accountDeactivated,
        'This account has been deactivated',
      );
    }

    final customToken = await _firebaseAuth.createCustomToken(uid);

    // Fire-and-forget: update last_login_at without blocking the response.
    unawaited(_touchLastLoginAt(uid));

    final user = User(
      uid: uid,
      email: normalizedEmail,
      name: userDoc['name'] as String? ?? '',
      contact: userDoc['contact'] as String? ?? '',
      role: userDoc['role'] as String? ?? 'guest',
    );

    return {'user': user, 'token': customToken};
  }

  /// Updates last_login_at on the user's Firestore doc. Deliberately
  /// never throws past this function - sign-in must succeed even if
  /// this write fails.
  static Future<void> _touchLastLoginAt(String uid) async {
    try {
      await _patchUserDocument(uid, {
        'last_login_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      // ignore: avoid_print
      print('⚠ Failed to update last_login_at for $uid: $e');
    }
  }

  /// Verifies a Firebase ID token and returns the uid from its `sub` claim.
  /// Throws [AuthException] with AUTH001 if the token is invalid or expired.
  ///
  /// Uses [FirebaseIdTokenVerifier] (local RS256 verification against Google's
  /// cached public keys) instead of `firebase_admin`/`openid_client`, which
  /// did uncached network work on every request. This runs on every protected
  /// route, so keeping it in-memory is the main latency win.
  static Future<String> verifyIdToken(String idToken) async {
    final projectId = FirebaseConfig.envMap['FIREBASE_PROJECT_ID'];
    if (projectId == null || projectId.isEmpty) {
      throw AuthException(
        AuthErrorCode.internalError,
        'Server misconfigured: missing FIREBASE_PROJECT_ID',
      );
    }
    try {
      return await FirebaseIdTokenVerifier.verify(
        idToken,
        projectId: projectId,
      );
    } catch (_) {
      throw AuthException(
        AuthErrorCode.invalidToken,
        'Invalid or expired token.',
      );
    }
  }

  /// Reads the `users/{uid}` document and returns it merged with `uid`.
  /// Throws [AuthException] with AUTH004 if no document exists.
  static Future<Map<String, dynamic>> getUserByUid(String uid) async {
    final doc = await _getUserDocument(uid);
    if (doc == null) {
      throw AuthException(AuthErrorCode.userNotFound, 'User not found');
    }

    return {
      'uid': uid,
      ...doc,
    };
  }

  /// Allowed role transitions keyed by the target's current role. Each entry
  /// maps an assignable `new_role` to the set of requester roles permitted to
  /// perform it. Anything not listed here is rejected as an invalid transition.
  ///
  /// Model (locked):
  ///   student   -> organizer            (faculty, super_admin)
  ///   organizer -> faculty              (super_admin only)
  ///   organizer -> student  (demote)    (faculty, super_admin)
  ///   guest / faculty / super_admin     -> terminal (no transitions)
  static const Map<String, Map<String, Set<String>>> _roleTransitions = {
    'student': {
      'organizer': {'faculty', 'super_admin'},
    },
    'organizer': {
      'faculty': {'super_admin'},
      'student': {'faculty', 'super_admin'},
    },
  };

  /// Changes [targetUid]'s role to [newRole], enforcing the locked role
  /// transition graph (promotion and demotion share this one path).
  ///
  /// [requesterRole] is supplied by the caller from the middleware-resolved
  /// user document - we deliberately do NOT re-read the requester's
  /// doc here, since the middleware already verified and resolved it.
  static Future<void> changeUserRole({
    required String targetUid,
    required String requesterUid,
    required String requesterRole,
    required String newRole,
  }) async {
    const assignableRoles = {'student', 'organizer', 'faculty'};

    // Only faculty/super_admin may change roles at all. AUTH003
    if (requesterRole != 'faculty' && requesterRole != 'super_admin') {
      throw AuthException(
        AuthErrorCode.insufficientPermission,
        'You do not have permission to change roles.',
      );
    }

    // Cannot change your own role, even with privilege. AUTH003
    if (targetUid == requesterUid) {
      throw AuthException(
        AuthErrorCode.insufficientPermission,
        'You cannot change your own role.',
      );
    }

    // newRole must be a known assignable role. AUTH007
    if (!assignableRoles.contains(newRole)) {
      throw AuthException(AuthErrorCode.invalidRole, 'Invalid role specified.');
    }

    final existing = await _getUserDocument(targetUid);

    // Check target exists. AUTH004
    if (existing == null) {
      throw AuthException(AuthErrorCode.userNotFound, 'Target user not found');
    }

    final currentRole = existing['role'] as String? ?? '';

    // Is (currentRole -> newRole) a defined transition at all? AUTH007
    final allowedFromCurrent = _roleTransitions[currentRole];
    final requiredRequesterRoles = allowedFromCurrent?[newRole];
    if (requiredRequesterRoles == null) {
      throw AuthException(
        AuthErrorCode.invalidRole,
        'Cannot change a $currentRole to $newRole.',
      );
    }

    // Does the requester have the privilege for this transition? AUTH003
    if (!requiredRequesterRoles.contains(requesterRole)) {
      throw AuthException(
        AuthErrorCode.insufficientPermission,
        'You do not have permission to assign this role.',
      );
    }

    final timeNow = DateTime.now().toUtc().toIso8601String();
    await _patchUserDocument(targetUid, {
      'role': newRole,
      'updated_at': timeNow,
    });
  }

  /// Returns all active (non-deleted) users, for the faculty/super_admin
  /// user-management screen.
  ///
  /// Firestore can't do substring search or case-insensitive matching, and
  /// it would need a *composite index* to combine an equality filter with an
  /// orderBy or a second equality. To stay index-free (the same choice we
  /// made for the events feed), we ask Firestore for only the one thing it
  /// indexes for free — `is_deleted == false` — and then do the [search],
  /// [roleFilter], and sorting ourselves in Dart. At ~500 users this is
  /// perfectly fine.
  static Future<List<Map<String, dynamic>>> listUsers({
    String? search,
    String? roleFilter,
  }) async {
    final client = await _firestoreClient();
    final projectId = _firestoreProjectId();

    final uri = Uri.parse( 
      'https://firestore.googleapis.com/v1/projects/$projectId'
      '/databases/(default)/documents:runQuery',
    );

    // Single-field equality filter only -> no composite index needed
    final response = await client.post( 
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'structuredQuery': {
          'from': [
            {'collectionId': 'users'},
          ],
          'where': {
            'fieldFilter': {
              'field': {'fieldPath': 'is_deleted'},
              'op': 'EQUAL',
              'value': {'booleanValue': false},
            },
          },
        },
      }),
    );

    if (response.statusCode != 200) {
      throw StateError( 
        'Firestore query failed for ListUsers: '
        '${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    final normalizedSearch = search?.trim().toLowerCase();
    final normalizedRole = roleFilter?.trim();

    final users = <Map<String, dynamic>>[];
    for(final entry in decoded){
      final row = entry as Map<String, dynamic>;
      final document = row['document'] as Map<String, dynamic>?;
      
      if (document == null) {
        // a row with no 'document' key (bare readTime) means no match
        continue;
      }

      final fields = document['fields'] as Map<String, dynamic>? ?? {};
      // Document 'name looks like ".../documents/users/{uid}'
      final resourceName = document['name'] as String? ?? '';
      final uid = resourceName.split('/').last;

      String? stringField(String key) =>
        (fields[key] as Map<String, dynamic>?)?['stringValue'] as String?;

      final name = stringField('name') ?? '';
      final email = stringField('email') ?? '';
      final role = stringField('role') ?? 'guest';

      // Optional role filter (done in Dart to avoid a composite index)
      if (normalizedRole != null &&
          normalizedRole.isNotEmpty && 
          role != normalizedRole) {
        continue;
      }

      // Optional case-insensitive substring search on name + email
      if (normalizedSearch != null && normalizedSearch.isNotEmpty) {
        final haystack = '$name $email'.toLowerCase();
        if(!haystack.contains(normalizedSearch)) continue;
      }

      users.add({
        'uid': uid,
        'name': name,
        'email': email,
        'contact': stringField('contact') ?? '',
        'role': role,
      });
    }

    // Sort by name in Dart (alphabetical, case-insensitive)
    users.sort(
      (a, b) => (a['name'] as String)
        .toLowerCase()
        .compareTo((b['name'] as String).toLowerCase()),
    );

    return users;
  }

  /// Soft-deletes the user by setting `is_deleted` to true and bumping
  /// `updated_at`. Throws [AuthException] with AUTH004 if the user is missing.
  static Future<void> deactivateUser(String uid) async {
    final existing = await _getUserDocument(uid);

    // Check target exists. AUTH004
    if (existing == null) {
      throw AuthException(AuthErrorCode.userNotFound, 'Target user not found');
    }

    final timeNow = DateTime.now().toUtc().toIso8601String();
    await _patchUserDocument(uid, {'is_deleted': true, 'updated_at': timeNow});
  }

  /// Triggers a password reset email for [email].
  ///
  /// Looks up the users collection by email: no match -> AUTH004, a match
  /// with is_deleted == true -> AUTH006 (no email sent either way). For an
  /// active match, asks the Identity Toolkit to send the PASSWORD_RESET email
  /// (sendOobCode); Firebase sends it and hosts the reset page - no in-app
  /// reset screen.
  static Future<void> forgotPassword({required String email}) async {
    final normalizedEmail = email.trim().toLowerCase();

    final userDoc = await _getUserDocumentByEmail(normalizedEmail);
    if (userDoc == null) {
      throw AuthException(AuthErrorCode.userNotFound, 'User not found');
    }

    final isDeleted = userDoc['is_deleted'] as bool? ?? false;
    if (isDeleted) {
      throw AuthException(
        AuthErrorCode.accountDeactivated,
        'This account has been deactivated',
      );
    }

    await _sendPasswordResetEmail(normalizedEmail);
  }

  /// Updates the user's profile and/or password.
  ///
  /// Enforces the all-or-nothing rule: [currentPassword] is verified via
  /// the Identity Toolkit before any Firestore writes occur. If a [newPassword]
  /// is provided, it updates the Firebase Auth record. Then, patches Firestore.
  static Future<Map<String, dynamic>> updateOwnProfile({
    required String uid,
    required String email,
    required String currentPassword,
    String? name,
    String? contact,
    String? newPassword,
  }) async {
    // 1. ALL-OR-NOTHING: Verify current password first
    try {
      final verifiedUid = await _verifyPasswordAndGetUid(
        email: email,
        password: currentPassword,
      );
      if (verifiedUid != uid) {
        throw AuthException(
          AuthErrorCode.currentPasswordIncorrect,
          'Current password is incorrect.',
          field: 'current_password', // ADDED: field parameter
        );
      }
    } on AuthException catch (e) {
      // If it's already an AuthException, check if it's the specific invalid
      // credential one
      if (e.code == AuthErrorCode.invalidCredentials) {
        throw AuthException(
          AuthErrorCode.currentPasswordIncorrect,
          'Current password is incorrect.',
          field: 'current_password', // ADDED: field parameter
        );
      }
      // Otherwise, let it bubble up (like AUTH009 internal errors)
      rethrow;
    }

    // 2. PASSWORD CHANGE LOGIC
    if (newPassword != null && newPassword.trim().isNotEmpty) {
      if (newPassword == currentPassword) {
        throw AuthException(
          AuthErrorCode.passwordSameAsCurrent,
          'New password must be different from your current password.',
          field: 'new_password', // ADDED: field parameter
        );
      }
      // Update password via Admin SDK
      await _firebaseAuth.updateUser(uid, password: newPassword);
    }

    // 3. FIRESTORE PROFILE UPDATE
    final patchData = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (name != null && name.trim().isNotEmpty) {
      patchData['name'] = name.trim();
    }
    if (contact != null && contact.trim().isNotEmpty) {
      patchData['contact'] = contact.trim();
    }

    await _patchUserDocument(uid, patchData);

    // 4. Return the updated user map
    // Re-fetch to ensure we return the exact state, and strip any accidental
    // internal fields
    final freshDoc = await getUserByUid(uid);

    return publicUserFields(freshDoc);
  }

  /// Whitelist of user fields safe to return in any response.
  static Map<String, dynamic> publicUserFields(Map<String, dynamic> doc) => {
    'uid': doc['uid'],
    'email': doc['email'],
    'name': doc['name'],
    'contact': doc['contact'],
    'role': doc['role'],
    'updated_at': doc['updated_at'],
  };

  // ---------------------------------------------------------------------
  // Identity Toolkit REST API
  // ---------------------------------------------------------------------

  /// Verifies email/password against Firebase and returns the uid.
  /// Throws AuthErrorCode.invalidCredentials on any failure — deliberately
  /// generic so we never reveal whether the email exists or the password
  /// was wrong (that distinction lets attackers enumerate valid emails).
  static Future<String> _verifyPasswordAndGetUid({
    required String email,
    required String password,
  }) async {
    final apiKey = _requireApiKey();
    final uri = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword'
      '?key=$apiKey',
    );

    http.Response response;
    try {
      response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );
    } catch (_) {
      throw AuthException(
        AuthErrorCode.internalError,
        'Internal server error during sign in',
      );
    }

    if (response.statusCode != 200) {
      throw AuthException(
        AuthErrorCode.invalidCredentials,
        'Invalid email or password',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final uid = decoded['localId'] as String?;
    if (uid == null) {
      throw AuthException(
        AuthErrorCode.invalidCredentials,
        'Invalid email or password',
      );
    }
    return uid;
  }

  /// Returns the FIREBASE_WEB_API_KEY or throws [AuthException] if missing.
  static String _requireApiKey() {
    final apiKey = FirebaseConfig.envMap['FIREBASE_WEB_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw AuthException(
        AuthErrorCode.internalError,
        'Server misconfigured: missing FIREBASE_WEB_API_KEY',
      );
    }
    return apiKey;
  }

  // ---------------------------------------------------------------------
  // Role detection
  // ---------------------------------------------------------------------

  static String _determineRole(String email) {
    if (email.endsWith('@ciit.edu.ph')) {
      return 'student';
    }
    return 'guest';
  }

  // ---------------------------------------------------------------------
  // Orphan cleanup
  // ---------------------------------------------------------------------

  static Future<void> _deleteAuthUserSafely(String uid) async {
    try {
      await _firebaseAuth.deleteUser(uid);
    } catch (_) {
      // Best-effort cleanup. If this also fails, the orphaned Auth user
      // will simply fail to sign in later (no matching Firestore doc),
      // which is the documented fallback behavior for this edge case.
    }
  }

  // ---------------------------------------------------------------------
  // Firestore REST plumbing (shared by read + write)
  // ---------------------------------------------------------------------

  /// Builds an authenticated HTTP client for Firestore REST calls using
  /// the service account credentials (NOT the Web API key - that's only
  /// for the Identity Toolkit calls above).
  static Future<http.Client> _firestoreClient() => FirestoreClient.instance();

  static String _firestoreProjectId() => FirestoreClient.projectId();

  /// Writes (creates) the users/{uid} Firestore document.
  /// snake_case field names. is_deleted always present. last_login_at
  /// and updated_at are intentionally absent at creation time.
  static Future<void> _writeUserDocument({
    required String uid,
    required String email,
    required String name,
    required String contact,
    required String role,
    required String createdAt,
  }) async {
    final client = await _firestoreClient();
    final projectId = _firestoreProjectId();

    final uri = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId'
      '/databases/(default)/documents/users?documentId=$uid',
    );

    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fields': {
          'email': {'stringValue': email},
          'name': {'stringValue': name},
          'contact': {'stringValue': contact},
          'role': {'stringValue': role},
          'created_at': {'timestampValue': createdAt},
          'is_deleted': {'booleanValue': false},
        },
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw StateError(
        'Firestore write failed for users/$uid: '
        '${response.statusCode} ${response.body}',
      );
    }
  }

  /// Patches specific fields on the users/{uid} Firestore document
  /// without overwriting the whole document. Used for last_login_at
  static Future<void> _patchUserDocument(
    String uid,
    Map<String, dynamic> fields,
  ) async {
    final client = await _firestoreClient();
    final projectId = _firestoreProjectId();

    final fieldPaths = fields.keys
        .map((k) => 'updateMask.fieldPaths=$k')
        .join('&');
    final uri = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId'
      '/databases/(default)/documents/users/$uid'
      '?$fieldPaths',
    );

    final encodedFields = <String, dynamic>{};
    for (final entry in fields.entries) {
      final value = entry.value;
      if (value is bool) {
        encodedFields[entry.key] = {'booleanValue': value};
      } else if (value is String) {
        encodedFields[entry.key] = entry.key.endsWith('_at')
            ? {'timestampValue': value}
            : {'stringValue': value};
      } else {
        throw ArgumentError(
          'Unsupported field type for ${entry.key}: ${value.runtimeType}',
        );
      }
    }

    final response = await client.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fields': encodedFields}),
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Firestore patch failed for users/$uid: '
        '${response.statusCode} ${response.body}',
      );
    }
  }

  /// Reads the users/{uid} Firestore document.
  /// Returns null if the document does not exist. Throws on any other
  /// non-2xx response or network error.
  static Future<Map<String, dynamic>?> _getUserDocument(String uid) async {
    final client = await _firestoreClient();
    final projectId = _firestoreProjectId();

    final uri = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId'
      '/databases/(default)/documents/users/$uid',
    );

    final response = await client.get(uri);

    if (response.statusCode == 404) {
      return null;
    }
    if (response.statusCode != 200) {
      throw StateError(
        'Firestore read failed for users/$uid: '
        '${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final fields = decoded['fields'] as Map<String, dynamic>? ?? {};

    String? stringField(String key) =>
        (fields[key] as Map<String, dynamic>?)?['stringValue'] as String?;
    bool? boolField(String key) =>
        (fields[key] as Map<String, dynamic>?)?['booleanValue'] as bool?;

    return {
      'email': stringField('email'),
      'name': stringField('name'),
      'contact': stringField('contact'),
      'role': stringField('role'),
      'is_deleted': boolField('is_deleted'),
    };
  }

  /// Finds a users document by its `email` field via a Firestore
  /// structured query (runQuery). Returns the first match merged with its
  /// `uid`, or null if no document matches. Throws on any non-2xx response
  /// or network error.
  ///
  /// Email is stored normalized (trimmed + lowercased) at registration, so
  /// callers must pass an already-normalized email for the EQUAL filter to
  /// match.
  static Future<Map<String, dynamic>?> _getUserDocumentByEmail(
    String email,
  ) async {
    final client = await _firestoreClient();
    final projectId = _firestoreProjectId();

    final uri = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId'
      '/databases/(default)/documents:runQuery',
    );

    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'structuredQuery': {
          'from': [
            {'collectionId': 'users'},
          ],
          'where': {
            'fieldFilter': {
              'field': {'fieldPath': 'email'},
              'op': 'EQUAL',
              'value': {'stringValue': email},
            },
          },
          'limit': 1,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Firestore query failed for email $email: '
        '${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    for (final entry in decoded) {
      final row = entry as Map<String, dynamic>;
      final document = row['document'] as Map<String, dynamic>?;
      if (document == null) {
        // Rows without a `document` key (eg. bare readTime) mean no match
        continue;
      }

      final fields = document['fields'] as Map<String, dynamic>? ?? {};
      // Document `name` looks like ".../documents/users/{uid}".
      final resourceName = document['name'] as String? ?? '';
      final uid = resourceName.split('/').last;
      String? stringField(String key) =>
          (fields[key] as Map<String, dynamic>?)?['stringValue'] as String?;
      bool? boolField(String key) =>
          (fields[key] as Map<String, dynamic>?)?['booleanValue'] as bool?;

      return {
        'uid': uid,
        'email': stringField('email'),
        'name': stringField('name'),
        'contact': stringField('contact'),
        'role': stringField('role'),
        'is_deleted': boolField('is_deleted'),
      };
    }

    return null;
  }

  /// Asks the Identity Toolkit to send a PASSWORD_RESET email to [email].
  ///
  /// Uses accounts:sendOobCode with the Web API key (same key as the
  /// sign-in call above). Firebase generates the out-of-band code, sends
  /// the email, and hosts the reset page - the app never sees the code.
  /// Only called after an active, matching Firestore user has been found,
  /// so a non-200 here is a genuine server-side failure (AUTH009).
  static Future<void> _sendPasswordResetEmail(String email) async {
    final apiKey = _requireApiKey();
    final uri = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode'
      '?key=$apiKey',
    );

    http.Response response;
    try {
      response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requestType': 'PASSWORD_RESET',
          'email': email,
        }),
      );
    } catch (_) {
      throw AuthException(
        AuthErrorCode.internalError,
        'Internal server error while sending reset email.',
      );
    }

    if (response.statusCode != 200) {
      throw AuthException(
        AuthErrorCode.internalError,
        'Failed to send password reset email',
      );
    }
  }
}
