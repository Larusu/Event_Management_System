# Frontend

Campus app Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

---

## Tech Stack

- **Framework:** Flutter
- **State Management:** Provider
- **Auth/Database:** Firebase Authentication (email/password) + Firestore
- **Backend:** Dart Frog REST API (see `backend/` repo), hosted on Google Cloud Run
- **Platform:** Android only (iOS/web not supported in this project)

---

## Architecture

This app follows a **features-based architecture**. Each feature owns its own data, state, and UI — features should not directly import internals from other features.

```
lib/
├── main.dart
├── app.dart                      # MaterialApp, routes, top-level MultiProvider
├── core/
│   ├── constants/                 # role strings, error codes, API base URL
│   ├── network/                   # http client wrapper, interceptors
│   ├── models/                    # shared models (User, ApiResponse)
│   ├── fonts/                     # font families
│   └── utils/
├── features/
│   ├── auth/
│   │   ├── data/                  # auth_repository.dart — calls backend API
│   │   ├── providers/             # auth_provider.dart — ChangeNotifier
│   │   └── presentation/
│   │       ├── screens/
│   │       └── widgets/
│   ├── events/
│   │   ├── data/
│   │   ├── providers/
│   │   └── presentation/
│   └── profile/
│       ├── data/
│       ├── providers/
│       └── presentation/
└── shared/
    └── widgets/                   # buttons, loaders, error banners reused app-wide
```

**Data flow convention:**
`Screen/Widget → Provider (ChangeNotifier) → Repository → Backend API`

UI never calls a repository directly — always go through the provider so state changes trigger rebuilds correctly.

**Provider registration:** all top-level providers are registered once in `app.dart` inside a single `MultiProvider`. When adding a new feature provider, add it there — don't create a second registration point.

---

## Getting Started

### Prerequisites

- Flutter SDK (stable channel)
- Android Studio or VS Code with Flutter/Dart plugins
- An Android emulator or physical device with USB debugging enabled
- Access to the project's Firebase console (ask the team lead)

### 1. Clone and install dependencies

```bash
git clone <repo-url>
cd frontend
flutter pub get
```

### 2. Firebase setup

1. Get `google-services.json` from the team lead (or download it yourself from the Firebase console if you have access).
2. Place it at:
   ```
   android/app/google-services.json
   ```
3. This file is **gitignored** — never commit it. Each developer needs their own copy locally.

### 3. Backend API URL

The app talks to the Dart Frog backend hosted on Cloud Run. Set the base URL in:

```
lib/core/constants/api_constants.dart
```

```dart
const String apiBaseUrl = 'https://TODO-cloud-run-url.a.run.app';
```

> **Note:** The actual Cloud Run URL is TBD and will be shared once the backend is deployed. Use the placeholder above until then. During local backend development, point this to your backend dev's local Dart Frog server instead (e.g. `http://<their-local-ip>:8080`) — `localhost` won't work since the team is fully remote.

### 4. Run the app

```bash
flutter run
```

---

## Conventions

- **State management:** Provider (`ChangeNotifier` + `MultiProvider`). Keep business/state logic in providers, not widgets.
- **API calls:** only from `data/` repository files, never directly from widgets or providers.
- **Error handling:** backend returns a standardized `{ success, message, ... }` shape — surface `message` to the user via shared error widgets in `shared/widgets/`, don't write one-off error UI per screen.
- **Pull-to-refresh:** used for event feeds (not real-time listeners). Notifications are fetched on demand, not pushed.
- **Soft deletes:** the backend never hard-deletes records. UI should treat "deactivated" users/events as hidden, not gone — don't assume a 404 means permanently deleted.
