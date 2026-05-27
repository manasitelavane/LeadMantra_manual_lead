# LeadMantra CRM

> **Never Miss a Lead Again — WhatsApp-First CRM Built for India**

LeadMantra CRM is a cross-platform Flutter application that delivers a streamlined lead and account management experience. It features WhatsApp-first workflows, secure authentication, session persistence, and an extensible CRM architecture designed for Indian businesses.

---

## Table of Contents

- [Features](#features)
- [Screenshots & App Flow](#app-flow)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [API Reference](#api-reference)
- [Architecture Overview](#architecture-overview)
- [Contributing](#contributing)

---

## Features

- 🔐 **Email/Password Authentication** — Secure login with token-based session management
- 💾 **Session Persistence** — Auto-restores dashboard on app relaunch using SharedPreferences
- 📋 **Policy Agreement Flow** — One-time privacy policy acceptance with WebView display
- 📊 **Dashboard** — Central hub for CRM actions after login
- 🗑️ **Delete Account** — Safe, API-backed account deletion with user confirmation
- 🌐 **In-App WebView** — Renders privacy policy without leaving the app
- 🎨 **Consistent Theming** — Centralized Material Design color scheme

---

## App Flow

```
App Start
    │
    ▼
AuthService.init()
    │
    ├─── Policy not accepted? ──► PolicyAgreementScreen (WebView + "I Agree" button)
    │                                       │
    │                                       ▼
    ├─── No saved session? ─────────► LoginScreen
    │                                       │
    │                             AuthService.login()
    │                                       │
    │                               POST /api/mobile/login
    │                                       │
    │                           Save session to SharedPreferences
    │                                       │
    └─── Session exists? ───────────► DashboardScreen
                                           │
                         ┌─────────────────┼────────────────────┐
                         ▼                 ▼                     ▼
               PrivacyPolicyScreen      Logout            DeleteAccountScreen
               (WebView)            (Clear session)     (POST /delete-account)
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart ^3.10.4) |
| HTTP Client | `http ^1.0.0` |
| Local Storage | `shared_preferences ^2.2.0` |
| Web Content | `webview_flutter ^4.13.1` |
| Linting | `flutter_lints ^6.0.0` |
| Platforms | Android · iOS · Web · Windows · macOS · Linux |

**Color Scheme:**

| Token | Hex | Usage |
|---|---|---|
| Primary | `#1B2B51` | App bar, buttons, accents |
| Accent | `#F97C32` | Highlights, CTAs |

---

## Project Structure

```
leadmantra/
├── lib/
│   ├── main.dart                          # Entry point — session routing
│   ├── core/
│   │   ├── apiendpoint.dart               # Centralized API URL constants
│   │   └── theme.dart                     # Color tokens & theme helpers
│   ├── services/
│   │   └── auth_service.dart              # Auth, session persistence, API calls
│   └── screens/
│       ├── policy_agreement_screen.dart   # First-launch privacy agreement
│       ├── login_screen.dart              # Email / password login UI
│       ├── dashboard_screen.dart          # Post-login CRM dashboard
│       ├── privacy_policy_screen.dart     # In-app WebView for policy URL
│       └── delete_account_screen.dart     # Confirmed account deletion flow
├── assets/
│   └── images/                            # App logo and UI assets
│       ├── logo.png
│       ├── logo_1 1.png
│       ├── logo_2 1.png
│       └── logo_3 1.png
├── android/                               # Android platform project
├── ios/                                   # iOS platform project
├── web/                                   # Web platform project
├── pubspec.yaml                           # Dependencies & asset declarations
└── README.md
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (stable channel)
- Dart `^3.10.4`
- Android Studio **or** Xcode (for mobile builds)
- A connected device or emulator

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/your-org/leadmantra.git
cd leadmantra

# 2. Install Flutter dependencies
flutter pub get

# 3. Run on a connected device / emulator
flutter run
```

### Build

```bash
# Android APK (release)
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS (requires macOS + Xcode)
flutter build ios --release

# Web
flutter build web

# Windows
flutter build windows
```

### Tests

```bash
flutter test
```

---

## API Reference

**Base URL:** `https://leadmantracrm.com/api/mobile`

| Endpoint | Method | Description | Auth Required |
|---|---|---|---|
| `/login` | POST | Authenticate user, receive token | No |
| `/delete-account` | POST | Delete the authenticated user's account | Yes (token) |

### Login — Request Body

```json
{
  "email": "user@example.com",
  "password": "secret"
}
```

### Login — Response (success)

```json
{
  "token": "eyJ...",
  "token_type": "Bearer",
  "user": { "id": 42, "name": "Jane Doe" },
  "company": { "id": 1, "name": "Acme Corp" }
}
```

Session fields saved to `SharedPreferences`: `user_id`, `token`, `token_type`, `user`, `company`.

---

## Architecture Overview

### `lib/core/apiendpoint.dart`
Single source of truth for all backend URLs. Add new endpoint constants here rather than hard-coding strings in screens.

### `lib/core/theme.dart`
Holds `AppColors` constants (`primary`, `accent`, etc.) consumed across all screens for visual consistency.

### `lib/services/auth_service.dart`
- Sends login / delete-account HTTP requests
- Serialises and persists the session to `SharedPreferences`
- Restores session on cold start
- Exposes `logout()` to clear persisted data

### `lib/main.dart`
Calls `AuthService.init()` synchronously before `runApp()`, then selects the correct first screen based on:
1. Policy accepted? → otherwise `PolicyAgreementScreen`
2. Valid session? → `DashboardScreen` or `LoginScreen`

---

## Contributing

1. Fork the repo and create a feature branch: `git checkout -b feature/my-feature`
2. Run `flutter analyze` and `flutter test` before committing
3. Open a pull request with a clear description of changes

---

*Built with ❤️ for India's sales teams.*
