# Campus App — Backend

[![style: dart frog lint][dart_frog_lint_badge]][dart_frog_lint_link]
[![License: MIT][license_badge]][license_link]
[![Powered by Dart Frog](https://img.shields.io/endpoint?url=https://tinyurl.com/dartfrog-badge)](https://dart-frog.dev)

An example application built with dart_frog

[dart_frog_lint_badge]: https://img.shields.io/badge/style-dart_frog_lint-1DF9D2.svg
[dart_frog_lint_link]: https://pub.dev/packages/dart_frog_lint
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT

---

## Prerequisites

### macOS

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

---

### Windows

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

---

### Linux

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

---

## Firebase Setup

The backend uses Firebase Admin SDK. You need a service account key to run it locally.

**Get the file from a teammate** — it's not in the repo for security reasons.

1. Ask for `service-account.json` file (or download it yourself from Firebase Console → Project Settings → Service Accounts → Generate new private key)
2. Place it in the `backend/` root:

```
backend/
└── service-account.json   ← put it here
```

> **Never commit this file.** It's already in `.gitignore`.

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

## Environment Variables

Create a `.env` file in `backend/` (also not committed):

```env
FIREBASE_PROJECT_ID=project-id
SERVICE_ACCOUNT_PATH=service-account.json
```

---

## Project Structure

```
backend/
├── routes/
│   ├── auth/
│   │   ├── signin.dart         # POST /auth/signin
│   │   └── register.dart       # POST /auth/register
│   └── users/
│       ├── _middleware.dart    # token verify → user lookup → deactivation check
│       ├── me.dart             # GET /users/me · PATCH /users/me
│       ├── me/
│       │   └── deactivate.dart # POST /users/me/deactivate
│       └── [targetUID]/
│           └── role.dart       # PATCH /users/{targetUID}/role
├── lib/
│   ├── middleware/
│   │   └── auth_middleware.dart
│   ├── services/
│   │   ├── firebase_service.dart
│   │   ├── auth_service.dart
│   │   └── user_service.dart
│   ├── models/
│   │   └── user_model.dart
│   ├── utils/
│   │   ├── validators.dart
│   │   └── response_helper.dart
│   └── constants/
│       └── error_codes.dart
├── service-account.json        # not committed
├── .env                        # not committed
└── pubspec.yaml
```

---

## Running with Docker

If you don't want to install Dart locally, or you're testing the production build:

```bash
# build the image
docker build -t campus-app-backend .

# run it
docker run -p 8080:8080 campus-app-backend
```

Or from the repo root using Docker Compose (recommended):

```bash
docker compose up
```

> Make sure your `service-account.json` and `.env` are in `backend/` before building.

---

## Common Issues

**`dart_frog: command not found`**
→ See the Prerequisites section for your OS. macOS/Linux: add `$HOME/.pub-cache/bin` to `.zshrc` / `.bashrc`. Windows: add `%APPDATA%\Pub\Cache\bin` to your system PATH via Environment Variables.

**`service-account.json` not found error on startup**
→ Make sure the file is in `backend/` and the path in `.env` matches.

**Port 8080 already in use**
→ macOS/Linux: `lsof -ti:8080 | xargs kill`. Windows: `netstat -ano | findstr :8080` then `taskkill /PID <pid> /F`. Or just change the port: `dart_frog dev --port 8081`.

**Firebase permission denied errors**
→ Your service account might not have the right roles. It needs `Firebase Admin SDK Administrator Service Agent` in GCP IAM.
