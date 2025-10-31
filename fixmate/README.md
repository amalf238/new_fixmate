# FixMate

FixMate is an AI-powered Android app that connects skilled workers with customers across Sri Lanka

## Features
- Intelligent service matching, using custom ML models with sentence transformers achieving 95%+ accuracy in problem classification
- Image analysis via OpenAI API for automated service identification
- Real-time chat with Firebase Cloud Messaging, dynamic booking management, and push notifications
- Secure authentication (Google OAuth, email-based 2FA) and role-based access control (RBAC)
- Comprehensive quotation and booking management system
- Admin dashboard for user and content moderation
Implemented robust security measures including Firebase Security Rules, password encryption (bcrypt/scrypt), HTTPS/TLS 1.3, and protection against XSS/CSRF/IDOR attacks. Successfully completed 124 test cases with 97.96% functional compliance and 100% security compliance.


## Tech stack
- **Frontend:** Flutter 3 (Material 3 UI kit) with responsive layouts and animations.
- **Backend:** Firebase Authentication, Cloud Firestore, Firebase Storage, and callable Cloud Functions.
- **AI Services:** Optional OpenAI Vision API access proxied through a configurable backend.

## Prerequisites
- Flutter SDK 3.0 or newer with Dart 3 (see the `sdk` constraint in `pubspec.yaml`).【F:pubspec.yaml†L1-L25】
- Firebase CLI with access to a Firebase project (authentication, Firestore, and Storage enabled).
- Node.js 22 for running or deploying Firebase Functions.【F:functions/package.json†L1-L18】
- (Optional) Python/Node backend if you plan to proxy OpenAI requests for web deployments (see `BACKEND_URL` in `openai_service.dart`).【F:lib/services/openai_service.dart†L1-L30】

## Getting started
1. **Clone the repository**
   ```bash
   git clone <repo-url>
   cd fixmate
   ```
2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```
3. **Configure Firebase**
   - Log in with `firebase login` and set your active project: `firebase use <project-id>`.
   - Update the generated configuration if needed with `flutterfire configure`.
   - The app already references `DefaultFirebaseOptions.currentPlatform` to bootstrap Firebase on every device.【F:lib/main.dart†L1-L55】
4. **Prepare the `.env` file**
   - Duplicate `.env.example` (or create `.env`) and set `OPENAI_API_KEY=<your-key>` if you want AI image analysis.
   - Without a key, mobile builds will disable direct OpenAI calls and fall back to the optional proxy.【F:lib/services/openai_service.dart†L1-L42】
5. **Run optional Firebase emulators**
   - Storage emulator: `firebase emulators:start --only storage`. The Flutter app automatically connects in debug mode and runs a connectivity self-test.【F:lib/main.dart†L24-L75】
   - Firestore/Auth emulators can also be started if you have local seed data.
6. **Launch the app**
   ```bash
   flutter run  # add --target=lib/main.dart if needed
   ```
7. **Access sample accounts** (after importing/creating them in Firebase Auth):
   | Role      | Email                         | Password |
   |-----------|-------------------------------|----------|
   | Customer  | Zoo@gmail.com                 | 123456   |
   | Worker    | ravi.gunasekara@gmail.com     | 123456   |
   | Admin     | Manori@gmail.com              | 234567   |

## Working with Firebase Functions
```bash
cd functions
npm install
npm run serve   # Emulate locally
npm run deploy  # Deploy to Firebase (requires project access)
```
The callable function `createWorkerAccount` provisions Firebase Auth users and writes worker/customer metadata to Firestore, so ensure your Firebase project security rules allow the expected access patterns.【F:functions/index.js†L1-L120】

## Running tests and quality checks
- Unit/widget tests: `flutter test`
- Integration tests (device/emulator required): `flutter test integration_test`
- Cloud Functions linting: `cd functions && npm run lint`
- Repo helper scripts: `./scripts/run_all_tests.sh` (macOS/Linux) or `scripts\run_all_tests.bat` (Windows) to execute the full suite.

## Project structure
```
fixmate/
├─ lib/
│  ├─ constants/          # Shared UI constants and service metadata
│  ├─ models/             # Firestore-backed data models
│  ├─ screens/            # Role-specific screens and workflows
│  ├─ services/           # Firebase, AI, storage, and analytics services
│  └─ widgets/            # Reusable UI components
├─ functions/             # Firebase Cloud Functions (Node.js 22)
├─ web/, android/, ios/   # Platform-specific build scaffolding
├─ test/                  # Widget and unit tests
└─ scripts/               # Automation helpers for CI and local testing
```

## Troubleshooting
- **Missing AI responses:** Confirm `OPENAI_API_KEY` is set or that the proxy backend at `http://localhost:8000` is reachable.【F:lib/services/openai_service.dart†L1-L48】
- **Storage emulator warnings:** Ensure `firebase emulators:start --only storage --project <project-id>` is running before launching a debug build.【F:lib/main.dart†L24-L75】
- **Role-based screen access:** Verify the authenticated user belongs to the correct Firestore collection (`customers`, `workers`, or `admins`) so dashboards can load context data.【F:lib/main.dart†L66-L105】

Happy building with FixMate!
