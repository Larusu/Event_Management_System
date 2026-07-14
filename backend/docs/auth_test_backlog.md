# Authentication & Registration — Test-Driven Development Backlog

**Test file:** `backend/test/routes/auth_test.dart` (45/45 passing)  
**Generated:** 2026-07-08

---

## How to Use This Backlog

Each issue is categorized by **Component** and **Severity**, with a clear **Remediation** step for sprint planning. Issues marked **Test Gap** require new automated tests; issues marked **Code Defect** require source changes.



## Component: Validators

### AUTH-001 — Email with spaces fails at regex, never at `contains(' ')`
- **Severity:** Medium
- **Status:** Open
- **Type:** Code Defect
- **Test Status:** Verified (test confirms dead-code behavior)
- **Description:** `AuthValidationService.validateEmail` runs `RegExp` before `trimmed.contains(' ')`. Because the regex forbids spaces, any address with a space returns `Invalid email format` before reaching the explicit space guard. The `contains(' ')` branch is unreachable.
- **Expected Behavior:** When a space is present in the email, the user should receive a targeted message: `Email cannot contain spaces`.
- **Actual Behavior:** Returns the generic `Invalid email format` message. The explicit space-check is dead code.
- **Location:** `lib/utils/validators.dart:15-21`
- **Remediation:** Refactor validator to check `contains(' ')` before the regex, or remove the dead branch.

---

### AUTH-002 — Whitespace-only email returns generic format error
- **Severity:** Low
- **Status:** Open
- **Type:** Code Defect
- **Test Status:** Verified (test confirms misleading error message)
- **Description:** `validateEmail('   ')` trims to an empty string, then falls through to the regex check and returns `Invalid email format`. The UX would be clearer if the validator detected the empty-after-trim state and returned a specific whitespace error.
- **Expected Behavior:** Return `Email cannot be empty or whitespace only` when the input is only whitespace.
- **Actual Behavior:** Returns `Invalid email format`, which is misleading for inputs that are structurally empty.
- **Location:** `lib/utils/validators.dart:9-17`
- **Remediation:** Add an early guard: if `trimmed.isEmpty` after trim, return the whitespace-specific message.

---

### AUTH-008 — No explicit test for email case normalization
- **Severity:** Medium
- **Status:** Open
- **Type:** Test Gap
- **Test Status:** Not covered (implicit only)
- **Description:** Both `registerUser` and `signInUser` call `.trim().toLowerCase()` on the email before passing it downstream. While this behavior is implicit in the validators and service layer, there is no dedicated unit test that asserts `Test@Example.COM` is normalized to `test@example.com`.
- **Expected Behavior:** Email is stored and queried in lowercase regardless of client casing.
- **Actual Behavior:** Behavior is correct but only verified indirectly; a future refactor could break normalization without a failing test.
- **Location:** `lib/utils/validators.dart:13`, `lib/services/firebase_auth_service.dart:60,133`
- **Remediation:** Add a pure-unit test asserting lowercase normalization in `AuthValidationService.validateEmail` or in the service layer.



## Component: Registration

### AUTH-004 — No happy-path coverage for registration endpoint
- **Severity:** High
- **Status:** Pending
- **Type:** Test Gap
- **Test Status:** Pending — requires Firebase mocking / service-layer abstraction
- **Description:** The existing test suite exercises only validation failures (400 AUTH005), malformed JSON (500 AUTH009), and method-not-allowed (405). There is no route-level test verifying that a valid `POST /auth/register` returns `201`, a `custom_token`, and a correctly shaped `user` object with role auto-detection (`student` vs `guest`).
- **Expected Behavior:** `201 Created` with `custom_token`, `user.uid`, `user.email`, `user.role`, and `created_at`.
- **Actual Behavior:** Not testable in the current unit-test harness because `FirebaseAuthService.registerUser` is a static method that requires a live or deeply mocked Firebase Admin environment.
- **Location:** `routes/auth/register.dart:33-51`
- **Remediation:** Introduce a service-layer abstraction (e.g., `AuthService` interface) or use a mock harness to test the happy path end-to-end.

---

### AUTH-009 — No race-condition test for duplicate registration
- **Severity:** Medium
- **Status:** Pending
- **Type:** Test Gap
- **Test Status:** Pending — requires Firebase integration tests
- **Description:** `FirebaseAuthService.registerUser` correctly maps `auth/email-already-exists` to `409 AUTH002`. However, there is no test simulating two concurrent registration requests for the same email to confirm that the second request is rejected with the correct status and error code.
- **Expected Behavior:** Second concurrent request returns `409 AUTH002: An account with this email already exists.`
- **Actual Behavior:** Cannot be verified without Firebase integration tests or integration tests.
- **Location:** `lib/services/firebase_auth_service.dart:66-82`
- **Remediation:** Add an integration test using integration tests against a test project to verify idempotency.

---

### AUTH-011 — Authorization header parsing is whitespace-sensitive
- **Severity:** Medium
- **Status:** Open
- **Type:** Code Defect
- **Test Status:** Not covered
- **Description:** `auth_middleware.dart` extracts the token via `authHeader.substring(7)`, assuming exactly one space after `Bearer`. A client sending `Authorization:  Bearer <token>` (double space) or `Bearer  <token>` will have a leading space included in the token string, causing `verifyIdToken` to fail and returning `401 AUTH001`.
- **Expected Behavior:** `Authorization: Bearer <token>` is parsed robustly even with extra whitespace.
- **Actual Behavior:** `substring(7)` assumes exactly one space after `Bearer`. Extra whitespace breaks token verification.
- **Location:** `middleware/auth_middleware.dart:25-26`
- **Remediation:** Replace `substring(7)` with a regex or `split(' ')` that tolerates variable whitespace, e.g., `authHeader.replaceFirst('Bearer ', '')`.



## Component: Sign-In

### AUTH-005 — No happy-path coverage for sign-in endpoint
- **Severity:** High
- **Status:** Pending
- **Type:** Test Gap
- **Test Status:** Pending — requires Firebase mocking / service-layer abstraction
- **Description:** Similar to registration, the sign-in tests only cover validation failures, wrong credentials, and deactivated accounts. There is no test asserting that valid credentials return `200`, a `custom_token`, and a `user` object populated from Firestore (`name`, `contact`, `role`).
- **Expected Behavior:** `200 OK` with `custom_token` and populated `user` fields.
- **Actual Behavior:** Not testable without Firebase Admin + Identity Toolkit REST mocking.
- **Location:** `routes/auth/signin.dart:41-61`
- **Remediation:** Introduce a service-layer abstraction or integration test for the happy path.

---

### AUTH-006 — No regression test for deactivated-account sign-in
- **Severity:** High
- **Status:** Pending
- **Type:** Test Gap
- **Test Status:** Pending — requires service-layer mocking
- **Description:** The sign-in flow checks `is_deleted` in Firestore and returns `403 AUTH006: This account has been deactivated`. This is a security-critical guardrail — if it regresses, deactivated users could regain access. Yet there is no automated test covering this branch.
- **Expected Behavior:** `403 AUTH006` when `is_deleted == true`.
- **Actual Behavior:** Only verified via ad-hoc or exploratory testing. A regression could pass unnoticed.
- **Location:** `routes/auth/signin.dart:62-70`, `lib/services/firebase_auth_service.dart:147-153`
- **Remediation:** Mock `FirebaseAuthService.signInUser` to throw `AccountDeactivated` and assert the 403 response.

---

### AUTH-007 — No test coverage for Auth-orphan rollback on sign-in
- **Severity:** Medium
- **Status:** Pending
- **Type:** Test Gap
- **Test Status:** Pending — requires service-layer mocking / integration test
- **Description:** When an Auth account exists but no Firestore document is found (`userDoc == null`), `signInUser` maps this to `404 AUTH004: User not found`. This prevents leaking that an Auth account exists with a broken profile. Both the rollback logic (orphan cleanup on registration failure) and the sign-in guard are logically sound but lack automated coverage.
- **Expected Behavior:** `404 AUTH004` for an Auth account with no matching Firestore document.
- **Actual Behavior:** Not covered in automated tests.
- **Location:** `lib/services/firebase_auth_service.dart:141-145`, `lib/services/firebase_auth_service.dart:97-106`
- **Remediation:** Add an integration test (or service-layer mock) that creates an Auth user without a Firestore doc and asserts the 404 on sign-in.



## Component: Forgot Password

### AUTH-003 — No route tests for forgot-password deactivated / not-found transitions
- **Severity:** High
- **Status:** Pending
- **Type:** Test Gap
- **Test Status:** Pending — requires service-layer mocking
- **Description:** The existing `forgot-password` tests cover only `405 Method Not Allowed` and `400 AUTH005` for invalid email format. The `404 AUTH004` (user not found) and `403 AUTH006` (account deactivated) branches are implemented but untested at the route level.
- **Expected Behavior:** `404 AUTH004` for unknown email; `403 AUTH006` for deactivated account; `200` with reset link for active account.
- **Actual Behavior:** Only verified via ad-hoc testing; these branches lack regression coverage.
- **Location:** `routes/auth/forgot-password.dart:38-52`, `lib/services/firebase_auth_service.dart:284-301`
- **Remediation:** Add mocked route tests (or integration tests) that simulate Firestore returning null or `is_deleted == true` and assert the correct status codes.

---

### AUTH-010 — Forgot-password intentionally leaks email existence
- **Severity:** Low
- **Status:** Info
- **Type:** Security / Product Decision
- **Test Status:** Not covered (by design)
- **Description:** The docstring in `forgot-password.dart` explicitly notes that the endpoint returns `AUTH004` (user not found) instead of a generic `If an account exists, an email was sent` message. This enables email enumeration: an attacker can probe which emails are registered.
- **Expected Behavior:** Generic `200 OK` regardless of whether the email exists, preventing enumeration.
- **Actual Behavior:** Returns distinct `404 AUTH004` for unknown emails.
- **Location:** `routes/auth/forgot-password.dart:16-17`
- **Remediation:** Review with security team. If the product decision is to hide existence, change to always return `200` and adjust Firestore lookup accordingly.



## Component: Middleware & Token Handling

### AUTH-012 — No test coverage for non-JSON Content-Type handling
- **Severity:** Medium
- **Status:** Open
- **Type:** Test Gap
- **Test Status:** Not covered
- **Description:** `register.dart` and `signin.dart` call `await context.request.json()` without first checking `Content-Type`. If a client sends `Content-Type: text/plain` with a JSON body, `dart_frog` may coerce the parse; if it sends XML or form data, the parse will fail with a `FormatException` and return `500 AUTH009`. It is unclear whether the API should reject non-JSON content types explicitly (e.g., `415 Unsupported Media Type`) or accept the current behavior.
- **Expected Behavior:** Either return `415 Unsupported Media Type` for non-JSON content, or gracefully return `500 AUTH009` with a clear message.
- **Actual Behavior:** Not tested. Behavior depends on `dart_frog`'s internal coercion logic.
- **Location:** `routes/auth/register.dart:28`, `routes/auth/signin.dart:27`
- **Remediation:** Add a test (or middleware) asserting the response when `Content-Type` is not `application/json`. Decide on API contract (415 vs 500) and document it.

---

### AUTH-013 — No regression test for missing `FIREBASE_WEB_API_KEY`
- **Severity:** Low
- **Status:** Info
- **Type:** Test Gap
- **Test Status:** Not covered
- **Description:** `FirebaseAuthService._requireApiKey` throws `AUTH009: Server misconfigured: missing FIREBASE_WEB_API_KEY` if the environment variable is absent. This is a deployment-time safeguard, but there is no test asserting that the route returns `500` with this message when the key is missing.
- **Expected Behavior:** `500 AUTH009` with a clear server-misconfiguration message.
- **Actual Behavior:** Verified only via manual QA or deployment-time checks.
- **Location:** `lib/services/firebase_auth_service.dart:358-367`
- **Remediation:** Add an environment-test harness that unsets the API key and asserts the 500 response.



## Prioritized Development Backlog

### P0 — Critical Security / Happy-Path Breakage (Next Sprint)

| Rank | Bug ID | Action |
|------|--------|--------|
| 1 | AUTH-006 | Deactivated-account sign-in test (security-critical guardrail). |
| 2 | AUTH-004 | Happy-path registration route test. |
| 3 | AUTH-005 | Happy-path sign-in route test. |

### P1 — High Confidence / Regression Coverage (Current Sprint)

| Rank | Bug ID | Action |
|------|--------|--------|
| 4 | AUTH-003 | Forgot-password `404` / `403` route tests. |
| 5 | AUTH-007 | Auth-orphan sign-in rollback test. |
| 6 | AUTH-011 | Harden `Authorization` header parsing. |
| 7 | AUTH-008 | Explicit email normalization test. |

### P2 — Medium Confidence / Edge Robustness (Backlog)

| Rank | Bug ID | Action |
|------|--------|--------|
| 8 | AUTH-001 | Refactor dead-code email space check. |
| 9 | AUTH-012 | Define Content-Type policy for auth routes. |
| 10 | AUTH-009 | Duplicate-registration race-condition test. |
| 11 | AUTH-013 | Missing API-key configuration test. |

### P3 — Low / Informational / Technical Debt (Icebox)

| Rank | Bug ID | Action |
|------|--------|--------|
| 12 | AUTH-002 | Whitespace-only email error message. |
| 13 | AUTH-010 | Email-enumeration exposure review. |



## Test Results Summary

### Passing (Automated, 2026-07-08)

**Validators — 20/20 passing**
- Email: empty, invalid-format, space-in-middle, all-whitespace, valid
- Password: empty, <8, exactly 7, exactly 8, unicode-length-ok
- Name: empty, whitespace-only (including tab), valid
- Contact: empty, whitespace-only, 09-valid, 10 digits, 12 digits, +09 prefix, letters, dashes, non-09 prefix

**Register Route — 14/14 passing**
- 405 non-POST
- 400 AUTH005: invalid email, empty email, password <8, missing fn, whitespace fn, missing ln, whitespace ln, missing contact, whitespace contact, invalid contact, +09 contact, lettered contact, dashed contact
- 500 AUTH009: malformed JSON
- Extra-field tolerance (`role` ignored by model)

**Sign-In Route — 6/6 passing**
- 405 non-POST
- 400 AUTH005: invalid email, empty email, empty password
- 500 AUTH009: malformed JSON

**Forgot-Password Route — 5/5 passing**
- 405 non-POST
- 400 AUTH005: invalid email, empty email

**Request Models — 1/1 passing**
- Extra fields ignored (RegisterRequest ignores `role`)

### Pending / Not Yet Covered

- AUTH-004, AUTH-005: Happy-path route tests pending service-layer abstraction.
- AUTH-006, AUTH-007, AUTH-009, AUTH-003: Service-layer tests require mocking `FirebaseAuthService` or integration harness.
- AUTH-011, AUTH-012, AUTH-013: Middleware / env tests pending additional harness work.
