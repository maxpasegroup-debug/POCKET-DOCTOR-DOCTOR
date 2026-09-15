# Pocket Doctor - Doctor mobile app

Dedicated Flutter Android/iOS migration of the existing Doctor web workspace.
The existing backend is the source of truth. No backend or database changes.

Read docs/doctor-web-to-flutter-migration-map.md for the source audit and
 docs/doctor-mobile-migration.md for parity evidence and unresolved acceptance.

## Run

### Hosted / staging testing

Select **Doctor - Hosted staging (Railway)** in VS Code Run and Debug.
The profile and **Doctor: build hosted testing APK** task both use
`config/hosted-testing.json`, targeting
`https://pocket-doctor-production.up.railway.app/api/v1` with no local API or USB forwarding.

    flutter run --dart-define-from-file=config/hosted-testing.json
    flutter build apk --debug --dart-define-from-file=config/hosted-testing.json

The APK is written to `build/app/outputs/flutter-apk/app-debug.apk`.
The app reads `API_BASE_URL` through `String.fromEnvironment` at compile time.
`APP_ENV=staging` on Railway or in the shell does not select a Flutter API URL.
Stop and rebuild/relaunch when changing configuration. Do not combine the hosted
file with a conflicting `--dart-define=API_BASE_URL` argument.

Development OTP display is enabled for this debug profile only when the backend
returns a development code. It does not bypass authentication. Railway's
`OTP_MODE=testing` currently rejects Doctor OTP requests with
`TEST_LOGIN_NOT_ALLOWED`; this is a separate backend authentication policy block.
These client settings do not change Railway variables, SMS, roles or verification.

### Local development

In VS Code, select **Doctor - USB phone (local test API)** in Run and Debug,
then press F5. This supplies the compile-time API address and forwards port 3018
over USB. For an emulator, select **Doctor - Android emulator (local test API)**.
The existing local test backend must be running on port 3018. Stop and relaunch
when changing the API address; hot reload does not change dart-define values.

Launching without API_BASE_URL intentionally shows the configuration message.
The Doctor app has no embedded production server address.

    flutter pub get
    flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3018/api/v1

The example address is the Android emulator route to a locally running existing
Pocket Doctor API. Use an explicit HTTPS /api/v1 URL for deployed environments.
No default doctor, fake login, embedded credential or clinical demo dataset is
included. Sign in using an existing provisioned DOCTOR account and backend OTP.
Optional development-only OTP display: --dart-define=SHOW_DEVELOPMENT_OTP=true.
This flag cannot display OTPs in release mode.

## Validate

    flutter analyze
    flutter test
    flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:3018/api/v1
    flutter build apk --release --dart-define=API_BASE_URL=https://YOUR_API_HOST/api/v1

Release signing must be configured before distribution. iOS requires macOS and
Xcode validation. The approved Pocket Doctor logo was absent from the source;
text branding is retained and native launcher assets remain provisional.

## Source provenance

Existing platform: ../pocket doctor, commit 435a684.
Last committed Doctor portal: 58658d1:apps/doctor-portal.
The source platform had already removed the portal before this migration.
.validation/platform is an ignored copy used only for regression tests.
artifacts contains validation logs. It is not a production backend.

Navigation: Home (agenda and consultations), Availability, Profile.
Riverpod handles typed repository/application state. Native secure storage holds
only the existing opaque session token. Clinical data is not persisted offline.
