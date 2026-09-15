# Doctor mobile device validation

Validation resumed September 9, 2026 on Windows. Existing AVD `Pixel_6` was
available; no physical Android device was discovered. No AVD was created or
wiped. The existing debug APK was used, with development API address
`http://10.0.2.2:3000/api/v1`. No configured test database/backend was available.

## Attempts

1. Saved-snapshot launch, headless and read-only: Android remained booting;
   installation was rejected. Evidence: `artifacts/closure/emulator-stdout.log`,
   `emulator-stderr.log`, `device-install.log`, `device-install-attempt2.log`.
2. Same AVD cold boot using `-no-snapshot-load -no-snapshot-save -read-only`,
   without a data wipe: initially offline, eventually `sys.boot_completed=1`
   and package service found. Streamed APK installation failed with
   `Failure calling service package: Broken pipe (32)`.
   Evidence: `emulator-cold-stdout.log`, `emulator-cold-stderr.log`,
   `device-cold-install.log` under `artifacts/closure/`.
3. Non-streaming installation retry: outcome recorded below.

## Acceptance scope

Real doctor login/OTP, Doctor Home backend loading, authenticated navigation,
profile/availability/note forms, logout and session restoration cannot be
certified without the configured test backend and accounts. Local widget tests
are separate evidence, not device acceptance. No mock backend, fake OTP,
fabricated appointment or live video was used.

## Final outcome

**DEVICE VALIDATION = BLOCKED.** The non-streaming retry transferred the APK,
but installation did not complete during the observation period. A separate
`pm path com.pocketdoctor.pocket_doctor_doctor` returned exit 1 with no package
path. The emulator was stopped with `adb emu kill`; the pending installer then
reported waiting for device and was cancelled. This was an infrastructure stall,
not a passed installation or a confirmed application defect.

Evidence: `artifacts/closure/device-cold-install-no-streaming.log`. No successful
Doctor launch, screenshot, native keyboard/scrolling/form/navigation/network
error interaction, login or logout was observed. None is claimed as validated.
The same read-only AVD was used throughout; no snapshot was saved.

## D-VALIDATION follow-up — 2026-09-09

A physical Android I2403 (Android 16/API 36) is now connected. APK installation
succeeded and Android activity launch returned Status: ok. Previous emulator
failures above remain historical evidence, but installation is no longer blocked
on this physical device. Initial UI inspection was blocked by the phone lock
screen; unlock was requested. No authenticated acceptance is claimed.
See [live validation evidence](doctor-mobile-live-validation.md) and
`artifacts/live-validation/device-install.log` / `device-launch.log`.
Current device status: PARTIAL (install/activity start only).
The physical device subsequently disconnected before visible UI revalidation.
Install and activity launch remain PASS; interactive acceptance remains BLOCKED.

## D-E2E — 2026-09-09

Repeated adb checks showed no connected Android device during D-E2E. Connection
and unlock were requested; no device became available. A test-configured Doctor
APK compiled, but no install/launch/interaction was performed this phase. Patient
APK compilation was interrupted without a completion result. Headless real-HTTP
Flutter runs are recorded separately and do not validate native storage, keyboard,
orientation, touch or restart. DEVICE VALIDATION = BLOCKED for this phase.
