import 'dart:io';

import 'package:firebase_admin/firebase_admin.dart';
// ServiceAccountCredential is not re-exported from the package's public API,
// so importing it from src/ is the only way to construct it.
// ignore: implementation_imports
import 'package:firebase_admin/src/auth/credential.dart';

/// Firebase Admin SDK Configuration
///
/// This module provides Firebase Admin SDK setup for:
/// - Service account credentials initialization from .env file
/// - Connection to Firebase Authentication
/// - Firestore operations via HTTP REST API
class FirebaseConfig {
  static bool _initialized = false;
  static App? _app;
  static Map<String, String?>? _envMap;

  /// Check if Firebase is initialized
  static bool get isInitialized => _initialized;

  /// Get the Firebase App instance
  static App? get app => _app;

  /// Lazily loaded config map (platform env vard with .env overlay)
  static Map<String, String?> get envMap {
    _envMap ??= _loadConfig();
    return _envMap!;
  }

  /// Initialize Firebase Admin SDK
  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      final envMap = _loadConfig();
      _envMap = envMap;

      final projectId = envMap['FIREBASE_PROJECT_ID'];

      if (projectId == null) {
        throw Exception('Missing required Firebase credentials in .env file');
      }

      _app = FirebaseAdmin.instance.initializeApp(
        AppOptions(
          credential: ServiceAccountCredential.fromJson({
            'type': 'service_account',
            'project_id': envMap['FIREBASE_PROJECT_ID'],
            'private_key_id': envMap['FIREBASE_PRIVATE_KEY_ID'],
            'private_key': envMap['FIREBASE_SERVICE_ACCOUNT_KEY']?.replaceAll(r'\n', '\n'),
            'client_email': envMap['FIREBASE_CLIENT_EMAIL'],
            'client_id': envMap['FIREBASE_CLIENT_ID'],
          }),
        ),
      );

      _initialized = true;
    } catch (e) {
      rethrow;
    }
  }

  /// Load Configuration from platform envionment (Cloud Run / CI),
  /// with .env file for local development
  static Map<String, String?> _loadConfig() {
    // Cloud run / CI provide config via real environment variables.
    final config  = <String, String?>{}..addAll(Platform.environment);

    // Local dev convenience: overlay from a .env file if present
    final envFile = File('.env');
    if (envFile.existsSync()) {
      final lines = envFile.readAsLinesSync();
      String? currentKey;
      String? currentValue = '';

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) {
          continue;
        }

        if (trimmed.contains('=')) {
          if (currentKey != null) {
            config[currentKey] = currentValue;
          }
          final parts = trimmed.split('=');
          currentKey = parts[0].trim();
          currentValue = parts.sublist(1).join('=').trim();
        } else {
          if (currentValue != null) {
            currentValue += '\n$trimmed';
          }
        }
      }

      if (currentKey != null) {
        config[currentKey] = currentValue;
      }
    }

    return config;
  }

  /// Cleanup: Called on app shutdown to release resources
  static Future<void> cleanup() async {}
}
