# LeadMantra CRM

> **Never Miss a Lead Again — WhatsApp-First CRM Built for India**

LeadMantra CRM is a Flutter application that delivers streamlined lead management and calendar-based follow-up tracking. It features WhatsApp-first workflows, offline lead capture with background sync, secure token-based authentication, and an in-app calendar with recurring notes — built specifically for Indian sales teams.

---

## Table of Contents

- [Features](#features)
- [App Flow](#app-flow)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [API Reference](#api-reference)
- [Architecture Overview](#architecture-overview)
- [Android Release Signing](#android-release-signing)

---

## Features

- **Authentication** — Email/password login, token-based sessions, auto-restore on relaunch. Token-not-generated (403) shows a popup directing the user to their admin.
- **Lead Management** — Create, view, edit, and filter leads with pagination from the server.
- **Offline Capture** — Leads saved offline when no internet, synced in batch on the next connection.
- **Search** — Local search across uploaded and offline leads by name, phone, email, or company.
- **Phone Validation** — 10-digit validation + start-digit check (must begin 6–9 for valid Indian mobile numbers).
- **Calendar** — Month grid view with dot indicators (orange for overdue days). Tap any day to see its notes.
- **Calendar Notes CRUD** — Create, edit, and delete notes with follow-up date, recurrence, status, and assignee (admins only).
- **Recurrence** — Notes marked Done auto-generate the next occurrence; a dialog confirms the new date.
- **Security** — Automatic logout on `account_deleted`, `company_deleted`, `session_invalid`, or `user_identity_required` response codes.
- **X-User-Id Header** — Sent on every authenticated request to satisfy server-side identity checks.
- **Delete Account** — Safe, API-backed account deletion with user confirmation.

---

## App Flow

```
App Start
    │
    ▼
AuthService.init()
    │
    ├── Policy not accepted? ──► PolicyAgreementScreen (WebView + "I Agree")
    │                                    │
    ├── No saved session? ──────────► LoginScreen
    │                                    │
    │                          POST /api/mobile/login
    │                                    │
    │                        ┌── 403? ──► "Access Restricted" dialog
    │                        │            (token not generated — contact admin)
    │                        └── 200 → save token → DashboardScreen
    │
    └── Session exists? ───────────► DashboardScreen
                                          │
            ┌─────────────────────────────┼──────────────────────┐
            ▼                             ▼                       ▼
     LeadsScreen                   CalendarScreen          DeleteAccountScreen
          │                               │
    ┌─────┴──────┐              ┌─────────┴──────────┐
    ▼            ▼              ▼                     ▼
TotalLeads  OfflineLeads  Month Grid            EventListScreen
(paginated)  (local)      + Day Notes            (All Notes)
    │                          │
    ▼                     AddEditEventScreen
EditLeadScreen            (create / edit note)
    │
 POST /leads/{id}  (POST alias for edit)
```

### Calendar Note Flow

```
CalendarScreen (month grid)
    │
    ├── Tap day ──► loadNotesForDate()  ──► display notes in day panel
    │                                           │
    │                                    ┌──────┴──────┐
    │                                    ▼             ▼
    │                              Edit note      Delete note
    │                          POST /notes/{id}  POST /notes/{id}/delete
    │                                    │
    │                          recurred == true?
    │                                    │
    │                          "Next occurrence: [date]" dialog
    │
    ├── FAB / "Add Note" ──► AddEditEventScreen ──► POST /calendar/notes
    │
    └── AppBar list icon ──► EventListScreen (all notes, sorted by date)
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
| Platforms | Android · iOS |

**Color Scheme:**

| Token | Hex | Usage |
|---|---|---|
| Primary | `#1B2B51` | App bar, buttons, borders |
| Accent | `#F97C32` | Dot indicators, highlights |

---

## Project Structure

```
leadmantra/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── api_client.dart          # Central HTTP client (auth headers, logging, logout codes)
│   │   ├── apiendpoint.dart         # All API URL constants
│   │   ├── app_bar.dart             # Shared LeadMantraAppBar widget
│   │   └── theme.dart               # Color tokens
│   ├── models/
│   │   ├── lead.dart                # Lead model with toJson / fromJson
│   │   └── calendar_event.dart      # CalendarEvent model with fromJson
│   ├── services/
│   │   ├── auth_service.dart        # Login, logout, session persistence, 403 handling
│   │   ├── lead_service.dart        # Lead CRUD, offline sync, paginated fetch
│   │   └── calendar_service.dart    # Calendar API: grid, notes CRUD, dropdowns
│   └── screens/
│       ├── policy_agreement_screen.dart
│       ├── login_screen.dart
│       ├── dashboard_screen.dart
│       ├── leads_screen.dart        # Tabbed: Total / Uploaded / Offline + search
│       ├── new_lead_screen.dart
│       ├── edit_lead_screen.dart
│       ├── calendar_screen.dart     # Month grid + day panel
│       ├── add_edit_event_screen.dart
│       ├── event_list_screen.dart   # All notes list
│       ├── privacy_policy_screen.dart
│       └── delete_account_screen.dart
├── android/
├── ios/
├── pubspec.yaml
└── README.md
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (stable channel)
- Dart `^3.10.4`
- Android Studio or Xcode (for mobile builds)
- A connected device or emulator

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/your-org/leadmantra.git
cd leadmantra

# 2. Install dependencies
flutter pub get

# 3. Run on device / emulator
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
```

---

## API Reference

**Base URL:** `https://leadmantracrm.com/api/mobile`

All authenticated requests include:
```
Authorization: Bearer <token>
X-User-Id: <user_id>
Content-Type: application/json
```

### Auth

| Endpoint | Method | Description |
|---|---|---|
| `/login` | POST | Authenticate, receive token |
| `/delete-account` | POST | Delete authenticated user's account |

### Leads

| Endpoint | Method | Description |
|---|---|---|
| `/leads` | POST | Create a new lead |
| `/leads/list` | POST | Paginated lead list (search, status filter) |
| `/leads/sync` | POST | Batch sync offline leads |
| `/leads/{id}` | POST | Edit lead (POST alias — server accepts instead of PUT) |

### Calendar

| Endpoint | Method | Description |
|---|---|---|
| `/dropdowns?keys=recurrence,assignees,defaults` | GET | Recurrence options, assignee list, `can_assign_others` flag |
| `/calendar?month=YYYY-MM&timezone=Asia/Kolkata` | GET | Month grid — sparse array of days with note counts |
| `/calendar/notes?date=YYYY-MM-DD` | GET | Notes for a specific date |
| `/calendar/notes` | POST | Create a note |
| `/calendar/notes/{id}` | POST | Edit a note (POST alias) |
| `/calendar/notes/{id}/delete` | POST | Delete a note (POST alias) |

#### Note create/edit body

```json
{
  "note": "Call back about the quote",
  "follow_up_date": "2026-08-15",
  "recur_interval": "none",
  "status": "pending",
  "assign_to_user_id": 6
}
```

`recur_interval` values: `none` · `daily` · `weekly` · `monthly` · `quarterly` · `yearly`  
`status` values: `pending` · `done` · `cancelled`

#### Edit response (recurring note marked done)

```json
{
  "success": true,
  "recurred": true,
  "next_note": { "id": 12, "date": "2026-09-15" }
}
```

The app shows a dialog: *"Next occurrence created for 15 Sep 2026."*

### Automatic logout codes

The server may return `"code"` in any 401 response body. These codes trigger immediate session clear and redirect to login:

| Code | Meaning |
|---|---|
| `account_deleted` | User account was removed |
| `company_deleted` | Company account was removed |
| `session_invalid` | Token revoked or expired |
| `user_identity_required` | Missing X-User-Id header |

---

## Architecture Overview

### `ApiClient`

Central HTTP client (`lib/core/api_client.dart`). All requests go through `ApiClient.post()` or `ApiClient.get()`. It:
- Attaches `Authorization` and `X-User-Id` headers automatically
- Prints request/response to the terminal for debugging
- Calls `AuthService.handleUnauthorized()` on 401 or known logout codes

### `AuthService`

- Login, logout, session serialisation to `SharedPreferences`
- Exposes `currentUserId` (used by `ApiClient` for the `X-User-Id` header)
- Returns `AuthResult(requiresAdminContact: true)` on 403 → login screen shows an "Access Restricted" dialog

### `LeadService`

- `createLead()` — tries API first; saves locally on failure (offline-first)
- `fetchLeads()` — paginated server fetch for the Total Leads tab
- `syncOfflineLeads()` — batch sync via `/leads/sync`; prints `dev_error` and `error` to terminal for any failed operation
- `updateLead()` — calls `POST /leads/{id}` (POST alias for edit)

### `CalendarService`

- `loadDropdowns()` — fetches recurrence labels and assignee list once and caches; `canAssignOthers` controls visibility of the assignee picker (admins only)
- `loadMonthGrid()` — sparse day map keyed by `YYYY-MM-DD`; used by the calendar grid for dot indicators
- `loadNotesForDate()` — cached per-date; cleared after any write operation
- `loadAllNotes()` — full list for the All Notes screen
- `createNote()` / `updateNote()` / `deleteNote()` — return `NoteResult` which includes `recurred` and `nextNoteDate` for the recurring dialog
- All caches are invalidated after any successful write so the next read fetches fresh data

### State management

All services extend `ChangeNotifier`. Screens wrap their body in `ListenableBuilder(listenable: SomeService.instance, ...)` for reactive rebuilds without a third-party state library.

---

## Android Release Signing

| Field | Value |
|---|---|
| Keystore file | `android/app/leadmantra.jks` |
| Key alias | `leadmantra` |
| Key password | `LeadMantra@2026` |
| Keystore password | `LeadMantra@2026` |
| First & Last Name | Pratik Kulkarni |
| Organization | OnesNZeros Tech Solutions |
| City / State | Pune, Maharashtra |
| Country Code | IN |

> **Important:** Never commit `leadmantra.jks` to version control. Keep a secure offline backup — losing this keystore means you cannot publish updates to Play Store.

---

*Built with ❤️ for India's sales teams by OnesNZeros Tech Solutions.*
