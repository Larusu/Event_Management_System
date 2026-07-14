# Campus App — Backend

[![style: dart frog lint][dart_frog_lint_badge]][dart_frog_lint_link]
[![License: MIT][license_badge]][license_link]
[![Powered by Dart Frog](https://img.shields.io/endpoint?url=https://tinyurl.com/dartfrog-badge)](https://dart-frog.dev)

REST API for the Campus Event App, built with [Dart Frog](https://dart-frog.dev). All frontend data access flows through this service — the Flutter app never talks to Firestore or Cloudinary directly. It handles authentication, user profiles, and event browsing/management on top of the Firebase Admin SDK (Firestore), with Cloudinary for image storage.

[dart_frog_lint_badge]: https://img.shields.io/badge/style-dart_frog_lint-1DF9D2.svg
[dart_frog_lint_link]: https://pub.dev/packages/dart_frog_lint
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT

---

## Prerequisites

### macOS

<details>
<summary>Click to expand macOS setup</summary>
1. Install [Homebrew](https://brew.sh) if you don't have it:
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. Install the Dart SDK:
   ```bash
   brew tap dart-lang/dart
   brew install dart
   ```

3. Verify the install:
   ```bash
   dart --version
   ```

4. Install the Dart Frog CLI:
   ```bash
   dart pub global activate dart_frog_cli
   ```

5. Add the pub cache bin to your PATH. Open `~/.zshrc` in any editor and add:
   ```bash
   export PATH="$PATH:$HOME/.pub-cache/bin"
   ```
   Then reload:
   ```bash
   source ~/.zshrc
   ```

6. Verify:
   ```bash
   dart_frog --version
   ```
</details>

### Windows

<details>
<summary>Click to expand Windows setup</summary>
1. Download and run the Dart SDK installer from [dart.dev/get-dart](https://dart.dev/get-dart) — pick the **Windows** tab and download the `.exe`.

2. The installer adds Dart to your PATH automatically. Open a **new** Command Prompt or PowerShell and verify:
   ```powershell
   dart --version
   ```

3. Install the Dart Frog CLI:
   ```powershell
   dart pub global activate dart_frog_cli
   ```

4. Add the pub cache bin to your PATH:
   - Search **"Edit the system environment variables"** in the Start menu
   - Click **Environment Variables**
   - Under **User variables**, find `Path` → click **Edit** → **New**
   - Add: `%APPDATA%\Pub\Cache\bin`
   - Click OK and close all dialogs

5. Open a **new** PowerShell window and verify:
   ```powershell
   dart_frog --version
   ```

> **Windows tip:** Use **PowerShell** or **Windows Terminal** — not Command Prompt — for a better experience. Git Bash also works.

</details>

### Linux

<details>
<summary>Click to expand Linux setup</summary>

1. Install the Dart SDK:
   ```bash
   sudo apt-get update
   sudo apt-get install apt-transport-https
   wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/dart.gpg
   echo 'deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main' | sudo tee /etc/apt/sources.list.d/dart_stable.list
   sudo apt-get update
   sudo apt-get install dart
   ```

2. Install the Dart Frog CLI:
   ```bash
   dart pub global activate dart_frog_cli
   ```

3. Add to PATH in `~/.bashrc`:
   ```bash
   export PATH="$PATH:$HOME/.pub-cache/bin"
   ```
   Then reload:
   ```bash
   source ~/.bashrc
   ```

</details>

---

## Firebase Setup

The backend uses Firebase Admin SDK with credentials managed via environment variables in a `.env` file.

### Getting Access

All backend developers' Gmail accounts already have access to the Firebase project. You can generate your own service account key directly:

1. Go to the [Firebase Console](https://console.firebase.google.com), sign in with the Gmail account that has project access, and open the project.
2. Go to **Project Settings → Service Accounts**.
3. Click **Generate new private key**. This downloads a JSON file containing all the values you need.

> If you sign in and don't see the project, ask Jeff to add your Gmail to the Firebase project's IAM permissions — don't share a single key file around.
 
### Creating Your `.env`
 
1. Copy the template:

```bash
   cd backend
   cp .env.example .env
```
2. Open the downloaded service account JSON and the new `.env` side by side, and fill in each field:
   | `.env` variable | JSON field |
   |---|---|
   | `FIREBASE_PROJECT_ID` | `project_id` |
   | `FIREBASE_PRIVATE_KEY_ID` | `private_key_id` |
   | `FIREBASE_SERVICE_ACCOUNT_KEY` | `private_key` |
   | `FIREBASE_CLIENT_EMAIL` | `client_email` |
   | `FIREBASE_CLIENT_ID` | `client_id` |
   | `FIREBASE_WEB_API_KEY` | Firebase Web Api Key |

3. Copy `private_key` straight into `FIREBASE_SERVICE_ACCOUNT_KEY`, wrapped in quotes, exactly as it appears in the JSON file — it's already a single line with `\n` escape sequences, so no manual editing is needed:

```env
   FIREBASE_SERVICE_ACCOUNT_KEY="-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BA...\n-----END PRIVATE KEY-----\n"
```
   The app code already converts these back into real newlines on startup (`.replaceAll(r'\n', '\n')`), so this format is required.
 
#### Getting the Firebase Web API Key

You can obtain the Web API Key:

- Firebase Console
- Open Firebase Console.
- Go to Project Settings → General.
- Under 'Your Apps', select `google-services.json`.
- Copy the Web API Key value.

```
{
  "client": [
    {
      "api_key": [
        {
          "current_key": "AIza..."
        }
      ]
    }
  ]
}
```

Copy the value of current_key into:

`FIREBASE_WEB_API_KEY=AIza...`

4. Install dependencies and run:
```bash
   dart pub get
   dart_frog dev
```
 
The Firebase Admin SDK initializes automatically on the first request using the credentials from `.env`.
 
### `.env.example`
 
```env
FIREBASE_PROJECT_ID=
FIREBASE_PRIVATE_KEY_ID=
FIREBASE_SERVICE_ACCOUNT_KEY=
FIREBASE_CLIENT_EMAIL=
FIREBASE_CLIENT_ID=
FIREBASE_WEB_API_KEY=
```
 
### Security Notes
 
- ✓ `.env` is **never committed** to git (already in `.gitignore`)
- ✓ `.env.example` is committed as a reference template — keep it empty, never fill in real values
- ✓ Each developer generates their **own** service account key rather than sharing one
- ✓ Production uses Cloud Run environment variables, not a `.env` file

---

## Running Locally

```bash
# from the repo root
cd backend

# install dependencies
dart pub get

# start the dev server (hot reload enabled)
dart_frog dev
```

The server runs at `http://localhost:8080` by default.

Test it with:

```bash
curl http://localhost:8080
```

---

## Project Structure

```
backend/
├── routes/                          # Dart Frog file-based routing
│   ├── _middleware.dart             # Firebase Admin init (first request) + CORS
│   ├── index.dart                   # GET /            (health string)
│   ├── health.dart                  # GET /health      (JSON health check)
│   ├── auth/
│   │   ├── index.dart               # GET  /auth       (lists auth endpoints)
│   │   ├── register.dart            # POST /auth/register
│   │   ├── signin.dart              # POST /auth/signin
│   │   └── forgot-password.dart     # POST /auth/forgot-password  (public)
│   ├── events/
│   │   ├── _middleware.dart         # auth middleware for /events/*
│   │   ├── index.dart               # GET /events      (feed / filter / search / paginate)
│   │   └── [eventId]/
│   │       └── index.dart           # GET /events/{eventId}
│   └── users/
│       ├── _middleware.dart         # token verify → user lookup → deactivation → role
│       ├── me/
│       │   ├── index.dart           # GET /users/me · PATCH /users/me
│       │   └── deactivate/
│       │       └── index.dart       # POST /users/me/deactivate
│       └── [targetUID]/
│           └── role/
│               └── index.dart       # PATCH /users/{targetUID}/role
├── lib/
│   ├── constants/
│   │   ├── error_codes.dart         # AUTH* codes
│   │   └── event_error_codes.dart   # EVT* codes
│   ├── firebase_config.dart         # loads credentials from .env
│   ├── middleware/
│   │   └── auth_middleware.dart
│   ├── models/                      # *.g.dart are generated by build_runner
│   │   ├── auth_request.dart
│   │   ├── event.dart
│   │   └── user.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── event_service.dart
│   │   ├── firebase_auth_service.dart
│   │   └── firebase_event_service.dart
│   └── utils/
│       ├── response_helper.dart
│       └── validators.dart
├── .env                             # not committed (see Firebase Setup)
├── .env.example                     # committed template
├── firebase.json                    # Firebase CLI config
├── firestore.rules                  # deny-all rules (Admin SDK bypasses them)
└── pubspec.yaml
```

> **Regenerating models:** the `*.g.dart` files (`@JsonSerializable`) are generated. After editing a model, run `dart run build_runner build --delete-conflicting-outputs`.

---

## Running with Docker

Dart Frog generates the production `Dockerfile` for you — there is no hand-written Dockerfile in the repo. From `backend/`:

```bash
# generate the production build (creates build/ with a Dockerfile)
dart_frog build

# build the image
docker build -t campus-app-backend build/

# run it (pass your local .env into the container)
docker run -p 8080:8080 --env-file .env campus-app-backend
```

> This mirrors the production setup: the app reads its Firebase credentials from environment variables. On Cloud Run those are set as service env vars instead of an `.env` file.

---

## Common Issues

**`dart_frog: command not found`**
→ See the Prerequisites section for your OS. macOS/Linux: add `$HOME/.pub-cache/bin` to `.zshrc` / `.bashrc`. Windows: add `%APPDATA%\Pub\Cache\bin` to your system PATH via Environment Variables.

**Firebase credential / startup errors**
→ Make sure `backend/.env` exists and every variable from `.env.example` is filled in. `FIREBASE_SERVICE_ACCOUNT_KEY` must be the full `private_key` in quotes, with its `\n` escape sequences left intact (see Firebase Setup).

**Port 8080 already in use**
→ macOS/Linux: `lsof -ti:8080 | xargs kill`. Windows: `netstat -ano | findstr :8080` then `taskkill /PID <pid> /F`. Or just change the port: `dart_frog dev --port 8081`.

**Firebase permission denied errors**
→ Your service account might not have the right roles. It needs `Firebase Admin SDK Administrator Service Agent` in GCP IAM.
