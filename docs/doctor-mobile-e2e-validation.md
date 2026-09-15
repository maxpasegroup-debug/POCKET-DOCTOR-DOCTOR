# Doctor mobile E2E validation — D-E2E

Date: 2026-09-09. **MIGRATION INCOMPLETE.** This report separates actual HTTP/DB
checks, headless Flutter widget execution and Android device acceptance.
No product features, business logic, authorization or existing tests were changed.

## Environment

The verified existing PostgreSQL test database and loopback API remain the source
of truth: database `pocket_doctor_test` on 127.0.0.1:55433; existing backend at
`http://127.0.0.1:3018/api/v1`. Private runtime remains under ignored
`.validation/environment`; no secrets are included here. Fourteen migrations were
current with zero drift in D-ENVIRONMENT. Connectivity was checked again here.

Doctor Flutter: workspace root. Patient Flutter: unchanged platform application
in `.validation/platform/apps/mobile`; source platform `../pocket doctor` commit
435a684. Both Android builds were invoked with API_BASE_URL pointing to port 3018
and SHOW_DEVELOPMENT_OTP=true. This is development-only configuration, not a
production build. USB device use would require `adb reverse tcp:3018 tcp:3018`.
No Android device was connected during this phase's checks. A request to connect
and unlock the phone did not result in an available device during those checks.
Earlier-phase installation/launch evidence is not reused as current device E2E.

The five `DEMO D-ENVIRONMENT` accounts are those documented in
[the test environment](doctor-test-environment.md). No new role/identity was
created to work around OTP limits. Doctor A/B are DOCTOR, Patient A/B are USER,
and Admin is ADMIN. Existing random development OTP was used through HTTP.
No OTP or bearer token is stored in acceptance evidence.

## Evidence and scope

- `scripts/doctor-e2e-api.mjs`: actual HTTP requests, existing APIs, and read-only
  database cross-checks. This is not Flutter UI execution.
- `acceptance/doctor_live_ui_test.dart`: mounts the actual DoctorApp and uses real
  IOClient HTTP against this backend. Only native storage uses transient memory.
- Patient headless harness: `.validation/platform/apps/mobile/acceptance/patient_live_ui_test.dart`.
  It mounts PocketDoctorApp with actual HTTP and a transient session store. Its
  discovery navigation uses the existing router, then screen controls.
- Headless remount is not process restart or native secure-storage verification.
  Neither harness is an Android device, touch, real keyboard or orientation test.
- Existing tests remain intact, including their original skip conditions. Live
  Patient smoke flags were enabled because the real test environment is available.

## Actual API journey

The initial HTTP journey logged in all five accounts using real request/verify
OTP, checked backend roles and Doctor READY/appointments access, and verified
unauthenticated and invalid-token denials. Admin Doctor management returned 200;
Doctor-to-Admin and Patient-to-Doctor access returned 403.

Doctor A profile biography/languages were saved and reloaded through the existing
API. Injecting Doctor B's ID into the strict profile request returned 400; Doctor
B's profile remained unchanged. Doctor A availability was saved/reloaded with
Asia/Kolkata, a controlled current-day window, ten-minute consultations, two-minute
buffer and a future excluded date. Doctor B target injection returned 400 and
Doctor B availability remained unchanged. These reject unsupported target fields;
they are not evidence that an arbitrary doctor-ID mutation endpoint exists.

Patient A discovered Doctor A, retrieved backend-generated slots, confirmed the
excluded date had no slots, and booked through POST /consultations/book. No
appointment row was inserted directly into PostgreSQL. The actual reservation is
`49b7b186-d455-4347-b12e-437e5bc01fca`, initially CONFIRMED, with start
2026-09-09T05:12:00Z and end 05:22:00Z. Doctor A's appointments response contained
the same ID and the correct synthetic Patient A name. A read-only SQL query
confirmed the persisted appointment and timestamps. This appointment originated
through the Patient API, not the Patient Flutter booking screen.

Patient B reading Patient A's appointment returned 404. Doctor B accessing its
consultation context or attempting a note write returned 404. Patient A attempting
the Doctor note API returned 403. These actual responses are recorded in
`api-initial-timing-boundary.json` under `artifacts/e2e/`.

## Time and OTP boundaries encountered

The initial start action returned 409. Investigation confirmed two existing rules:
backend-generated slots require at least 15 minutes' lead time; Doctor start is
allowed only within ten minutes before start through appointment end. The harness
incorrectly expected an immediate start. The failure is retained, not hidden.
No booking timestamp, server clock or transition rule was changed.

A later continuation was attempted after the real start window opened, but Doctor
A's OTP request returned 429. Existing rules limit a phone to five requests/hour
and one request/minute. Read-only inspection confirmed Doctor A/B had reached
five requests in their current window. Counters were not reset and replacement
accounts were not introduced. Therefore the API journey did not reach a successful
start, note creation, follow-up or completion for this appointment. Planned later
Patient B booking/cross-doctor checks in that script were not executed either.

Before the timing failure, all five sessions were logged out and their subsequent
/auth/session calls returned 401. A revoked session was not reused to continue.
Expired-session checks remain covered by the existing integration suite rather
than a new manual expiry mutation. The appointment remains a real test reservation;
this phase does not rewrite its state to manufacture lifecycle evidence.

## Doctor Flutter observations

Initial headless runs genuinely reached OTP verification, Doctor Home, profile
save, availability, remount and logout for the synthetic doctors, but the harness
was not cleanly passing: its first version did not scroll to the availability save
button; a corrected version retained idle HTTP timers after widget disposal.
These harness failures are retained in the initial and transport-cleanup logs.
The transport was then explicitly closed; subsequent login attempts encountered
the unchanged OTP throttle. No product fix was made and no fully passed Doctor
live-widget suite is claimed from those intermediate observations.

Profile/availability/API persistence evidence does not establish actual Android
restart persistence. Loading/filter/empty/retry behavior has existing local widget
coverage; a complete live-device matrix remains unperformed.

## Patient Flutter observations

The initial Patient A headless run reached authenticated Home and searched for
Doctor A. It then tapped the non-interactive doctor-name text rather than the
actual View doctor & availability button. That harness action was corrected.
Initial Patient B execution and harness cleanup were also retained in its log.
The corrected harness uses each Patient account's remaining permitted OTP request;
its final outcome is recorded below. No rate-limit control was disabled.

## Consultation, notes, summary and follow-up

**LIVE VIDEO = BLOCKED — PROVIDER REQUIRED.** No live call was simulated.
The current API journey has not proved private-note creation/read isolation,
post-completion shared-summary visibility, follow-up persistence or completion
on its booking. Those rules exist and are exercised by backend integration tests;
that is separate from the requested shared Flutter workflow. No empty or absent
note response is represented as proof that a newly created private note is safe.

Supported states remain PENDING_PAYMENT, CONFIRMED, IN_PROGRESS, COMPLETED,
CANCELLED, NO_SHOW and EXPIRED. Rescheduling changes timestamps rather than
creating a RESCHEDULED enum. The new free booking confirmed directly, so it does
not demonstrate PENDING_PAYMENT. No expiry/no-show time was fabricated.

## Remaining acceptance gates

A connected/unlocked physical Android device, allowed OTP window, complete Doctor
and Patient UI journey with the same appointment, native session restoration,
notes/summary/follow-up/reload, lifecycle actions and device UX remain required.
No touch-target, keyboard, orientation or Android network-recovery pass is claimed.
Production SMS, video, payments, push, store signing, iOS and approved branding
remain separate external gates. Migration cannot be certified while internal
Flutter/device acceptance is incomplete.

## Final UI harness and build findings

Doctor headless final run: **0 passed, 2 failed** after OTP throttling. Earlier
versions reached more steps but failed harness cleanup; none is relabelled as a
fully passing test. The HTTP idle-timer cleanup was corrected without product
changes. Pending native UI/device verification remains separate.

Patient headless final run: **0 passed, 2 failed**. Patient A reached Home,
discovery, doctor profile, backend slots and the review step; the harness failed
to observe Reserve this time. No `patient-flutter-booking.json` confirmation was
produced. Patient B's run failed harness timer invariants. These are unresolved
acceptance failures, not proof of a product defect and not passes. The tests remain
available; no skip condition was introduced. Both Patient accounts have now used
their permitted test OTP attempts for this window.

Doctor debug compilation with the explicit test API: **PASS**. Patient debug
compilation did not finish during observation and was interrupted; it is **not a
build pass**. No APK installation or launch was performed this phase because no
physical device was connected. The phone request remained unanswered during work.
**DEVICE VALIDATION = BLOCKED.** Current Android UI/UX acceptance is NOT TESTED.

## Regression evidence

Doctor analyze: PASS, no issues. Existing Doctor suite: **23 passed, 0 skipped,
0 failed**. Complete existing Patient suite with all seven live flags:
**89 passed, 0 skipped, 0 failed**. Its genuine Flutter-repository smoke journeys
include booking/payment/reschedule/cancellation, programs, commerce, assistant,
membership and authentication against the actual backend. These are not a passed
synthetic Patient A/Doctor A screen-to-screen journey.

Initial backend rerun: **124 passed, 3 failed, 0 skipped** (127 including parent
and nested tests). Failures included transaction-start timeout, a quota response,
and the enclosing assistant integration test. Logs are retained in
`backend-tests-initial-failure.log`. A repeat of the same complete suite without
concurrent Flutter work is recorded separately below; no test/configuration or
business timeout was altered to make it pass.

Evidence directory: `artifacts/e2e/`. Latest command exits are separate from older
failed attempts. Commands used explicit loopback API configuration and existing
live smoke flags. An initial helper shell-quoting error was corrected before the
read-only database query executed; no secret output or database mutation resulted.

## Final results

Isolated backend repeat: **127 passed, 0 skipped, 0 failed**, exit 0. The earlier
three failures remain recorded; their disappearance without code/config changes
is consistent with concurrent-load sensitivity, not proof of a load-test pass.

Latest existing-suite totals: **239 passed, 0 skipped, 0 failed** (Doctor 23,
Patient 89, backend 127). Separately, the new headless acceptance suites have
**0 passed, 4 failed** (Doctor 2, Patient 2). Combined latest suite executions:
**239 passed, 4 failed, 0 skipped**. HTTP probe counts are not added to test-suite
counts. Repeated historical attempts are not double-counted.

Doctor APK build passed; Patient APK attempt was interrupted without a success
result. No current-phase Android install/launch/UI success is claimed. The final
adb check again showed no connected device.

Application/business source, Prisma models/migrations, Patient/Admin source and
existing tests are unchanged. New deliverables are the E2E API utility, Doctor
headless acceptance test, Patient harness template, this report and evidence.
The Patient executable harness lives in the ignored validation copy; its reviewable
copy is `acceptance/patient_live_ui_test.dart.template`. Copy that template into
the Patient validation project's `acceptance/patient_live_ui_test.dart` to rerun.

Run headless tests explicitly (not device tests):

```powershell
# Doctor workspace
flutter test acceptance/doctor_live_ui_test.dart --dart-define=SHOW_DEVELOPMENT_OTP=true
# Patient validation project
flutter test acceptance/patient_live_ui_test.dart --dart-define=API_BASE_URL=http://127.0.0.1:3018/api/v1 --dart-define=SHOW_DEVELOPMENT_OTP=true
```

Wait for the real per-phone OTP window before requesting another code. Improve
harness navigation/cleanup against actual screen state before a further attempt;
do not reset throttles, change business rules or hide failing tests. For API
continuation, the utility accepts an existing appointment ID, but the server must
still allow its real-time transition. The original booking was never time-shifted.

**Final decision: MIGRATION INCOMPLETE.**
