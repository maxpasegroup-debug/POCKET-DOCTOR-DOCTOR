# Doctor mobile migration

Status: **MIGRATION INCOMPLETE**. Native client implementation is present, but
live backend/security acceptance, production configuration and release assets
remain unvalidated. Do not treat compilation or mocked API tests as live parity.

## Source of truth

The destination workspace was empty. Existing platform source was discovered at
`../pocket doctor`, clean commit `435a684`. That commit already deleted the Doctor
web frontend. The audited last committed frontend is
`58658d1:apps/doctor-portal`. No claim is made about an unavailable newer deployed
portal. See [the complete audit and migration map](doctor-web-to-flutter-migration-map.md).

## Client delivered

Dedicated Flutter Android/iOS project at the workspace root. Riverpod manages
session, profile, availability and appointment loading. AuthRepository and
DoctorRepository send typed requests to the existing versioned API. AppConfig
requires an explicit API URL; release accepts HTTPS only. Native secure storage
holds the existing opaque bearer token, never medical records. The app is not a
web wrapper and has no independent backend or database.

Home contains the complete Today/Upcoming/Completed agenda, assigned appointment
details and demo indicators. An additional All filter makes other returned states
accessible. Availability contains timezone, duration, buffer, accepting toggle,
weekly windows with add/remove and midnight support, breaks and excluded dates.
Profile preserves read-only credentials and edits biography/languages only.
Consultation details expose only the authorized patient name and existing note
context, demo lifecycle controls, private notes, shared summary and follow-up.

No Doctor programs, notification inbox/preferences or earnings page existed in
the recoverable portal. These were not invented from database relationships or
patient/admin functionality. Backend notifications and payment relations remain
untouched. Real consultation provider access was unavailable before migration
and remains unavailable. No fake call or production lifecycle is offered.

## UI-only adaptations

Three bottom destinations (Home, Availability, Profile); consultation is nested
inside Home. Cards, scrollable forms, SafeArea, keyboard handling, touch controls,
loading/retry/empty/error/success notices and a small-screen test replace desktop
layout. No desktop content or workflow was deliberately removed. Form edits are
not persisted when navigating away, matching the portal. Save failures preserve
in-memory input. Successful profile and note saves reload the shared providers
so returning through Home or Android Back cannot show pre-save values. No medical
data is cached to disk or shown as current after a
failed reload. Backgrounding obscures content; resume revalidates the session and
reloads data. Revalidation can discard unsaved in-memory edits.

Secure mobile session restoration replaces the historical memory-only web
session. GET /doctor/session, already implemented by the current backend, supplies
authoritative verification/account states. Native bearer requests use the
existing authentication branch; no cookie conversion or client role input is
required. Debug-only development OTP display remains opt-in with
SHOW_DEVELOPMENT_OTP=true and cannot render in release builds.

Brand colors follow the Patient App theme (green #007D38, navy #061D43). The source
has no approved logo. The existing plain-text name/tagline is retained as a
fallback. Generated native launcher artwork is provisional Flutter scaffolding,
not approved Pocket Doctor branding. Supply unmodified approved artwork before
distribution. No logo was designed or redrawn.

## Reused APIs and models

All paths below are relative to `/api/v1`:

| Method | Path | Use |
|---|---|---|
| POST | /auth/otp/request | Existing mobile challenge |
| POST | /auth/otp/verify | Existing OTP verification and opaque session |
| GET | /doctor/session | Server DOCTOR authorization, verification and restoration |
| POST | /auth/logout | Existing session revocation |
| GET/PATCH | /doctor/profile | Assigned profile; biography/languages only |
| GET/POST | /doctor/availability | Existing availability contract |
| GET | /doctor/appointments | Backend-scoped latest 100 consultations |
| POST | /doctor/consultations/:id/action | Existing demo start/complete/no-show |
| POST | /doctor/consultations/:id/notes | Existing private/shared notes and follow-up |

Reused backend models: User, Session, OtpChallenge, Doctor, DoctorAvailability,
DoctorAvailabilityException, Consultation, ConsultationNote, EnrollmentPayment,
ConsultationReminder. Program/Notification and other platform models remain in
the source platform. **No backend files, API contracts, Prisma schema or database
migrations were changed.** `.validation/platform` is an ignored regression-only
archive of the existing platform, not another production backend.

## Security validation and limitations

Client contract tests verify bearer headers, no token URL, no redirects, session
expiry cleanup, late-response rejection, generic errors, server role rejection,
verification-state gating, logout and offline revalidation. Widget tests verify
private content disappears on logout, private/shared note fields remain distinct,
and disabled follow-up sends null date and empty note. Repositories have no
arbitrary patient-ID lookup or admin API methods. These tests use fixtures and
are not evidence of database authorization enforcement.

Existing backend security code was preserved. `authenticateDoctor` verifies the
existing session; route context authorizes DOCTOR; `assignedDoctor` enforces
verified ownership; notes and actions query the consultation by both appointment
and assigned doctor; transaction locks recheck assignment. Patient DTOs omit
private notes and disclose summaries only after completion. Admin routes retain
their existing role/security guards.

The existing PostgreSQL integration suites contain cross-doctor, unrelated
patient, USER-to-Doctor, Doctor-to-Admin, note privacy and appointment ownership
checks. They were **skipped**, not passed: no isolated DATABASE_URL was configured.
Full security acceptance therefore remains BLOCKED. No source database was
accessed or mutated during this migration.

## Test results

Validation uses unchanged platform commit 435a684 in `.validation/platform`.

| Check | Result | Evidence |
|---|---|---|
| Doctor Flutter tests | 23 passed, 0 skipped | ../artifacts/flutter-test.log |
| Doctor static analysis | Passed, no issues | ../artifacts/flutter-analyze.log |
| Backend tests | 28 passed, 13 skipped, 0 failed | ../artifacts/backend-test.log |
| Backend TypeScript | Passed | ../artifacts/backend-typecheck.log |
| Patient Flutter tests | 82 passed, 7 skipped | ../artifacts/patient-test.log |
| Admin tests | 16 passed, 0 skipped | ../artifacts/admin-test.log |
| Admin production build | Passed | ../artifacts/admin-build.log |

Patient unit/widget coverage includes authentication/session/profile, programs,
consultations, commerce, assistant/AI, membership and privacy/navigation. Seven
live API smoke tests were skipped. Admin tests cover role/API guards, form and
route contracts, availability, refund prerequisites and private-column handling;
this is not live acceptance of each admin workflow. Backend dependency install
and Prisma client generation passed; no schema migration was needed or run.

Initial sandbox subprocess failures and initial Doctor test/analyzer failures
were investigated and rerun. Final logs, rather than earlier attempts, govern the
table. Test fixtures are confined to `test/` and never drive production screens.

## Build results

Android debug: **passed**, `build/app/outputs/flutter-apk/app-debug.apk`.
Evidence: `artifacts/android-debug-build.log`. Debug uses the
explicit emulator API address `http://10.0.2.2:3000/api/v1`; no backend connectivity
is implied. Final sizes and SHA-256 values are recorded in
`artifacts/android-apk-checksums.json`.

Android release compilation: **passed**,
`build/app/outputs/flutter-apk/app-release.apk` (53,066,252 bytes). Both final
artifacts include the timezone and save/refresh fixes. Checksums are recorded in
`artifacts/android-apk-checksums.json`. Evidence:
`artifacts/android-release-build.log`. The release compilation uses
`https://replace-with-deployed-api.example/api/v1` exclusively as an explicit
build-time placeholder. This is not a working deployment address.
iOS project generated; **not validated** on macOS, Xcode or a device.
No web build is required or generated for this dedicated mobile project.
Release signing is intentionally unconfigured; no debug-key release is provided.

## Closure parity matrix (historical)

Closure tests ran September 8, 2026; environment checks and reporting resumed
September 9. PASS applies only to the stated evidence. PARTIAL means implemented
with local evidence but missing live acceptance. BLOCKED identifies unavailable
validation dependencies. NOT TESTED also identifies absent source features,
without proposing new scope. API paths are relative to `/api/v1`.

| Feature | Existing Web Behavior | Flutter Implementation | Backend API | Live Test | Security Test | Status |
|---|---|---|---|---|---|---|
| Authentication | Mobile, six-digit OTP, server role gate | Phone/code forms and Doctor gate; local tests pass | /auth/otp/request, /auth/otp/verify, /doctor/session | BLOCKED: valid doctor, invalid/expired OTP and Doctor Home | Live USER denial blocked | PARTIAL |
| Session | Authorized session and logout | Secure restoration, expiry cleanup and logout locally tested | /doctor/session, /auth/logout | BLOCKED: real restoration, expiry, revocation | Session ownership blocked | PARTIAL |
| Doctor Home | Agenda, filters, assigned appointments | Lists, filters, loading, empty and retry states tested locally | /doctor/appointments | BLOCKED: authoritative records | Cross-doctor scope blocked | PARTIAL |
| Profile | Read-only credentials; editable bio/languages | Equivalent fields and save/refresh tests | /doctor/profile | BLOCKED: loading/persistence | Profile ownership blocked | PARTIAL |
| Verification | Existing backend restrictions | Backend states and access gate locally tested | /doctor/session | BLOCKED: real account states | Live role/state denial blocked | PARTIAL |
| Availability | Windows, exclusions, buffer, duration, timezone, accepting preference | Equivalent form and contract validation | /doctor/availability | BLOCKED: persistence and Patient slot discovery | Ownership/conflict integration blocked | PARTIAL |
| Appointments | Assigned details and existing states | Backend list/detail and state affordances | /doctor/appointments | BLOCKED: Patient discovery through booking to Doctor details | Appointment ownership blocked | PARTIAL |
| Consultation | Authorized existing demo lifecycle | Existing actions and provider limitation | /doctor/consultations/:id/action | BLOCKED: real transitions/completion | Participant authorization blocked | PARTIAL |
| Live video | Existing provider unavailable | No fabricated video session | Existing provider infrastructure | BLOCKED - PROVIDER REQUIRED | NOT TESTED | BLOCKED |
| Patient context | Assigned consultation context only | Scoped appointment context; no arbitrary patient lookup | /doctor/appointments | BLOCKED: real patient context | Doctor A/Patient B and Doctor B/Doctor A context denial blocked | PARTIAL |
| Notes | Private note; summary shared under existing rules | Separate fields, payload and save/refresh tests | /doctor/consultations/:id/notes | BLOCKED: persistence and patient visibility | Cross-doctor/cross-patient/private-note denial blocked | PARTIAL |
| Follow-up | Toggle/date/shared information tied to note | Equivalent editor; disabled null/empty contract tested | /doctor/consultations/:id/notes | BLOCKED: persisted relationship | Ownership/visibility blocked | PARTIAL |
| Network states | Loading, errors, retry | Local timeout, late-response, expiry and cleanup tests pass | Shared API client | Real backend recovery not tested | Local private-content cleanup tested | PARTIAL |
| API/database reuse | Existing contracts and models | Existing APIs only; no new schema/backend logic | APIs listed above | Static source comparison only | 186 source/test files unchanged; not live enforcement evidence | PASS |
| Programs | No editor in recovered portal | Not applicable to recovered scope | No portal API | NOT TESTED: absent source feature | NOT TESTED | NOT TESTED |
| Notifications | No inbox/preferences in recovered portal | Not applicable to recovered scope | No portal API | NOT TESTED: absent source feature | NOT TESTED | NOT TESTED |
| Earnings/records | No earnings page in recovered portal | Not applicable to recovered scope | No portal API | NOT TESTED: absent source feature | NOT TESTED | NOT TESTED |
| Patient regression | Existing Patient application | Unchanged; 82 passed, 7 skipped | Existing Patient APIs | Seven live smoke tests blocked | Live ownership acceptance blocked | PARTIAL |
| Admin regression | Existing Admin workflows | Unchanged; 16 tests and production build passed | Existing Admin APIs | Live lookup/verification/appointments/programs/users not tested | Local guards tested; live Doctor-to-Admin denial blocked | PARTIAL |
| Approved branding | Locked approved asset required | Plain text; generated launcher asset provisional | None | Approved asset missing | Not applicable | BLOCKED |

## Closure evidence and acceptance gates

No application, backend, database, Patient, Admin or test source changed during
closure. No tests were deleted and no skip conditions were changed.

| Closure check | Result | Evidence under `artifacts/closure/` |
|---|---|---|
| Doctor tests | 23 passed, 0 skipped, 0 failed | doctor-tests.log |
| Doctor analysis | Passed, no issues | doctor-analyze.log |
| Backend suite | 28 passed, 13 existing skips, 0 failed | backend-tests.log |
| Backend typecheck | Passed | backend-typecheck.log |
| Complete existing Patient suite | 82 passed, 7 existing live smoke skips, 0 failed | patient-tests.log |
| Admin suite | 16 passed, 0 skipped, 0 failed | admin-tests.log |
| Admin production build | Passed | admin-build.log |
| Android release compilation | Passed; placeholder HTTPS API URL, not a deployment | android-release-build.log |
| Android signature verification | Failed, exit 1: Missing META-INF/MANIFEST.MF | android-signature-check.log; android-signing-status.json |
| Configured test database | BLOCKED: no process/user/machine DATABASE_URL or actual environment files found in inspected project/API locations | environment-source-audit.json |
| Source preservation | Clean platform commit 435a684; 186 tracked Dart/TypeScript/Prisma files compared, no differences after newline normalization | environment-source-audit.json |

Total across four suites: **149 passed, 20 skipped, 0 failed (169 tests)**.
Backend integration requires existing `AUTH_INTEGRATION=true` and `DATABASE_URL`
configuration. Patient smoke tests require their existing test deployment flags.
Skipped tests were not made runnable through invented infrastructure.

**DATABASE VALIDATION = BLOCKED.** No database was created or accessed. The real
mobile-to-OTP-to-Doctor-Home flow, invalid/expired OTP, restoration/expiry/logout,
cross-app booking, availability persistence/slot discovery, notes privacy and
follow-up persistence remain unexecuted. Direct API authorization tests require
provisioned Doctor A, Doctor B and patient accounts in a configured test backend.
Doctor-to-Admin and USER-to-Doctor live denial are also unverified.

**ANDROID STORE SIGNING = BLOCKED.** Compilation passed but the APK is unsigned;
no credentials were created. Debug compilation passed during the preceding
migration (`artifacts/android-debug-build.log`); the device attempt uses that
existing APK, not a claimed fresh debug compilation.

**IOS VALIDATION = BLOCKED.** This Windows environment has no macOS/Xcode/signing
or iOS device validation. **APPROVED BRAND ASSET = REQUIRED.** No replacement logo
was invented. Live video remains **BLOCKED - PROVIDER REQUIRED**. Production SMS,
payments and push were not validated; compilation proves none of these services.

Device attempts and outcome are in
[the device validation record](doctor-mobile-device-validation.md).
Critical live acceptance gates remain blocked, so closure cannot be certified.

## Web retirement

The sibling repository removed `apps/doctor-portal` and its deployment references
in 435a684 before this task. No additional files were retired here. Backend,
Patient and Admin remain unchanged (source Git status stayed clean). The earlier
removal is not certified by this migration. Production activation and retirement
acceptance must wait for the remaining validation; Git 58658d1 preserves the old
frontend for comparison.

## Remaining acceptance work

Provide an isolated PostgreSQL test database and run backend integration with
AUTH_INTEGRATION=true and DATABASE_URL configured. Run existing Patient API smoke
tests with their documented flags against that test deployment. Validate native
OTP/session restoration, all Doctor saves/lifecycle behavior and authorization
using provisioned Doctor A, Doctor B, USER and ADMIN accounts. Do not use real
patient data for fixtures. Configure the deployed HTTPS API and production SMS;
real consultation connectivity is an existing backend provider dependency, not
something this client migration bypasses. Supply approved logo/launcher artwork,
release signing, Android device acceptance and macOS/Xcode validation for iOS.

**Final decision: MIGRATION INCOMPLETE.**

## Files delivered

The complete source/platform/configuration file inventory is
[doctor-mobile-files.txt](doctor-mobile-files.txt). All Doctor client files are
new in this previously empty workspace. Existing platform files modified: none.
The principal implementation is under `lib/core`, `lib/features`, `lib/shared`,
with tests under `test`, native projects under `android` and `ios`, example API
configuration under `config`, and audit/validation documents under `docs`.
See [validation commands](doctor-mobile-validation-commands.md) to reproduce.

Closure files: added docs/doctor-mobile-device-validation.md and artifacts/closure evidence; updated this report and docs/doctor-mobile-files.txt. Application and test source changes during closure: none.


## D-VALIDATION update â€” 2026-09-09

Previous status: **MIGRATION INCOMPLETE** (closure evidence above retained).
Validation performed: rechecked DATABASE_URL/TEST_DATABASE_URL and documented
PostgreSQL aliases; inspected historical Phase 3â€“7 reports and source utilities;
reran Doctor, Patient, backend and Admin suites, Doctor analysis, backend
typecheck, Prisma offline validation and Admin build. Compared 14 SQL migrations
and 186 source/test files against the unchanged platform.

New evidence: **149 passed, 20 skipped, 0 failed** again. Offline Prisma schema
validation passed. No configured test database or test accounts were available;
old stopped cluster directories are not a substitute for configuration.
A newly connected physical Android device accepted the APK and returned a
successful activity launch. Visible UI was initially blocked by the lock screen.
Real authentication, cross-app persistence and API ownership remain unvalidated.
No source, business logic, authorization, tests or skip conditions were changed.

Current status: **MIGRATION INCOMPLETE**. Local validation is not production
readiness. See [D-VALIDATION evidence](doctor-mobile-live-validation.md) for
current logs, database safety, case-by-case blockers and device scope.

The feature matrix above remains applicable. Additional current evidence:

| Feature | Web Source Behavior | Flutter Implementation | Backend API | Live Validation | Security Validation | Status |
|---|---|---|---|---|---|---|
| Test database acceptance | Existing database relationships | Reuses existing backend | Existing Prisma schema | No configured test connection; offline schema valid | Database-backed ownership blocked | BLOCKED |
| Android native install/launch | Web had no native installation | Dedicated APK installed; activity start successful | None required for launch | Physical Android 16; initial visible UI blocked by lock screen | Authenticated device session not tested | PARTIAL |
| Server ownership acceptance | Existing owner-scoped APIs | Existing endpoints retained | Doctor/Patient/Admin APIs | No real account requests performed | Cross-doctor/patient, notes, session, profile and availability checks blocked | BLOCKED |
| Android store signing | Not applicable to web | Unsigned release configuration | None | Signature verification previously failed | No signing credentials provided | BLOCKED |
| iOS validation | Not applicable to web | Native project present | Existing APIs | No macOS/Xcode/device evidence | NOT TESTED | BLOCKED |

**D-VALIDATION final decision: MIGRATION INCOMPLETE.**
The physical device disconnected before visible UI could be revalidated;
installation/activity-start evidence remains valid, interactive checks blocked.

## D-ENVIRONMENT update â€” 2026-09-09

The infrastructure blocker is now resolved: deeper inspection found an existing
private Phase 7 development runtime that earlier environment-variable/.env checks
missed. Its matching loopback test cluster was verified and started with the
installed PostgreSQL distribution. No production connection or new database was
created. Fourteen migrations are current, schema drift is empty, and synthetic
Doctor A/B, Patient A/B and Admin accounts are provisioned.

Real HTTP development OTP, role resolution, session/logout and Doctor READY /
appointments API checks passed. Patient/Admin identities were denied Doctor
access. The full unchanged backend suite now passes **127 tests, zero skipped**;
Doctor analysis and **23 tests** pass. No application source changed.

Environment status: **TEST ENVIRONMENT READY**. Migration remains
**MIGRATION INCOMPLETE**: real Flutter Home/device/cross-app acceptance is still
outstanding. Backend integration evidence supersedes the earlier database-blocked
result for this local environment; it does not retroactively make prior skipped
runs or unobserved UI flows pass. See [test environment](doctor-test-environment.md).


## D-E2E update — 2026-09-09

Previous migration status: MIGRATION INCOMPLETE; safe environment ready.
New evidence: real HTTP profile/availability persistence, Patient A API booking
and Doctor A recognition of the same appointment, several direct 401/403/404/400
security responses, and real headless Flutter screen execution. The requested
complete shared Flutter journey did not pass: native device unavailable, Doctor
OTP hourly limit reached, and headless acceptance harnesses failed. No protected
counter, clock, appointment state, test skip condition or product code was changed.

Current migration status: **MIGRATION INCOMPLETE**. See
[E2E evidence and failures](doctor-mobile-e2e-validation.md). Historical matrices
above remain evidence of their own runs, not claims of current full parity.

## Current E2E parity matrix

PASS is restricted to the stated evidence. PARTIAL retains missing UI/device or
workflow gates. Database-backed integration tests do not by themselves establish
complete Flutter screen parity. API paths are relative to /api/v1.

| Feature | Web Source | Flutter Screen | API | Database | E2E Test | Security Test | Status |
|---|---|---|---|---|---|---|---|
| Doctor auth A/B | Phone/OTP/server role | Login and Home | /auth/otp/*, /doctor/session | Actual sessions | Headless login observed; complete harness fails; no Android run | Actual role gates; subsequent OTP 429 | PARTIAL |
| Patient auth A/B | Existing Patient app | Login/Home | /auth/otp/*, /auth/session | Actual USER sessions | Live regression passes; headless acceptance fails | Patient denied Doctor 403 | PARTIAL |
| Session restoration | Existing session lifecycle | Session gate | /doctor/session, /auth/logout | Real revocation | Transient-store remount observed; native restart untested | Logout then session returns 401 | PARTIAL |
| Doctor Home | Agenda/filter/empty/retry | Home | /doctor/appointments | Actual assigned booking | Headless Home observed; device/loading/error matrix incomplete | Assigned ID and patient name checked | PARTIAL |
| Profile | Bio/languages; credentials read-only | Profile | /doctor/profile | Save/reload confirmed | Real API and headless edits; native restart untested | B target injection 400; B unchanged | PARTIAL |
| Verification | Server restrictions | Session status | /doctor/session | Verified demo profiles | READY observed through actual API | Role resolution checked | PARTIAL |
| Availability | Windows/buffer/duration/timezone/exclusions | Availability | /doctor/availability | Save/reload confirmed | API controls reflected in generated slots; device untested | B target injection 400; B unchanged | PARTIAL |
| Patient slots | Existing discovery/slots | Discovery/profile/booking | /doctors, /doctors/:id/slots | Backend generation | API exclusions checked; headless reached slots | Existing authenticated Patient scope | PARTIAL |
| Shared booking | Existing Patient booking and Doctor agenda | Booking/Home/detail | /consultations/book, /doctor/appointments | Same real appointment ID | API booking passed; no Flutter booking confirmation | Patient B read 404 | PARTIAL |
| Consultation/lifecycle | Existing demo actions | Consultation detail | /doctor/consultations/:id/action | Booking remains authoritative | Immediate start 409; retry login throttled | Invalid time transition refused | PARTIAL |
| Patient context | Assigned appointment only | Detail | /doctor/consultations/:id/access | Existing ownership links | Context returned to assigned doctor | Doctor B unrelated context 404; opposite direction manual check unfinished | PARTIAL |
| Private notes | Doctor-only notes | Notes editor | /doctor/consultations/:id/notes | Existing model preserved | No note created on this journey | B write 404; Patient write 403; completed privacy journey unfinished | PARTIAL |
| Shared summary | Visible after completion | Notes/Patient detail | Existing notes and Patient detail | Existing DTO rules | Manual shared-summary/reload not reached | Backend suite coverage only | PARTIAL |
| Follow-up | Date/shared note relationship | Notes/follow-up | Existing notes API | Existing ConsultationNote fields | Manual persisted follow-up not reached | Backend suite coverage only | PARTIAL |
| API/database reuse | Existing backend source | Typed repositories | Existing endpoints | Same PostgreSQL/schema | Source unchanged; no direct appointment inserts in acceptance utility | Existing authorization unchanged | PASS |
| Live video | Provider boundary | Explicit unavailable notice | Existing provider access | Unchanged | Provider unavailable; no fake call | NOT TESTED | BLOCKED |
| Programs/notifications/earnings | No Doctor portal UI in recovered source | No invented feature | No portal endpoint | Existing shared models | Not applicable to recovered scope | NOT TESTED | NOT TESTED |
| Android device/UX | Native adaptation | All screens | Configured build API | Test backend ready | No connected physical device | Native storage/restart untested | BLOCKED |
| Signing/iOS/branding | External release gates | Native projects/assets | Not applicable | Not applicable | No new validation | NOT TESTED | BLOCKED |

**D-E2E final decision: MIGRATION INCOMPLETE.**

D-E2E final regression outcome: Backend 127/0 skipped/0 failed on isolated repeat,
Patient 89/0/0, Doctor 23/0/0; analysis clean. Initial backend 124/0/3 retained.
Four newly added headless acceptance cases still fail (0 passed/4 failed), so
passing regression does not close the E2E acceptance gaps. No physical device was
connected at final check. See the E2E report for exact scope and logs.

## Doctor launcher asset update

The user supplied Doctor app icon artwork. The original is preserved at assets/branding/doctor-app-icon.png; Android launcher resources and the iOS AppIcon catalog images now use it. Historical missing-launcher-asset findings above predate this update. Icon dimensions were checked; no new device or iOS runtime validation is claimed.

## E2E-REMEDIATION-01 — current acceptance matrix (2026-09-09)

Previous status: MIGRATION INCOMPLETE. This phase preserves all earlier failures,
including four failed headless acceptance cases and the initial backend failures.
The new Patient debug compilation completed successfully; regression results are
recorded in docs/doctor-mobile-e2e-remediation.md and artifacts/remediation.
No product, backend, authorization or migration source was changed. Acceptance
harness cleanup/scrolling changes are not evidence that their journeys passed.
The provisioned actors remain subject to the existing OTP request window; no
reset or bypass was performed. The phone was initially unauthorized, then absent.
No current physical-device acceptance or native session restoration is claimed.

| FEATURE | FLUTTER SCREEN | BACKEND API | DATABASE | E2E | SECURITY | DEVICE | STATUS |
|---|---|---|---|---|---|---|---|
| Doctor authentication | Login/session gate | /auth/otp/request, /auth/otp/verify, /doctor/session | Existing identities/session models | Provisioned-actor replay blocked by OTP window | Existing regression; previous direct role checks retained | BLOCKED | BLOCKED |
| Home/agenda | Home | /doctor/appointments | Existing consultation ownership | Previous headless observation; full matrix unverified | Existing assigned-doctor checks | BLOCKED | BLOCKED |
| Profile/verification | Profile/session gate | /doctor/profile, /doctor/session | Existing Doctor record | Prior save/read observed; native restart unverified | Prior B-target injection rejected | BLOCKED | BLOCKED |
| Availability | Availability | /doctor/availability | Existing windows/exclusions | Prior API persistence; native restart unverified | Prior B-target injection rejected | BLOCKED | BLOCKED |
| Patient slot discovery | Patient doctor profile | /doctors/:id/slots | Backend-generated slots | Prior real slot retrieval; new replay blocked | Existing backend regression | BLOCKED | BLOCKED |
| Patient booking → Doctor appointment | Patient booking; Doctor details | /consultations/book, /doctor/appointments | Shared authoritative appointment | Flutter confirmation and matching Doctor UI remain unverified | Prior Patient B read denied | BLOCKED | BLOCKED |
| Lifecycle/consultation | Consultation | /doctor/consultations/:id/action | Existing lifecycle | Full valid sequence not completed in Flutter | Prior early-start 409 retained | BLOCKED | BLOCKED |
| Patient context | Consultation details | /doctor/consultations/:id/access | Authorized appointment relationship | Assigned context previously retrieved by API | Prior cross-doctor read denied; regression retained | BLOCKED | BLOCKED |
| Private notes | Notes editor | /doctor/consultations/:id/notes | ConsultationNote | Flutter creation/read-isolation not completed | Existing database-backed regression, not this actor journey | BLOCKED | BLOCKED |
| Shared summary | Notes; Patient consultation history | Existing notes and Patient detail endpoints | Existing shared fields/DTO | Not reached; existing feature, not invented | Existing private-field omission regression | BLOCKED | BLOCKED |
| Follow-up | Consultation follow-up fields | Existing notes endpoint | Existing note/date relationship | Not reached in Flutter | Existing ownership regression | BLOCKED | BLOCKED |
| Session persistence/logout | Session gate | /auth/logout, /doctor/session | Existing sessions | Native restart unverified | Previous logout then 401; regression retained | BLOCKED | BLOCKED |
| API/database reuse | Typed repositories | Existing endpoints | Existing schema/migrations | Source comparison unchanged | Authorization unchanged | NOT APPLICABLE | PASS |
| Live video | Provider boundary | Existing consultation provider | Unchanged | Provider required; no simulated call | NOT APPLICABLE | BLOCKED | BLOCKED |
| Doctor programs/inbox/earnings | No corresponding retired portal feature | No new endpoint | Unchanged shared models | Outside recovered portal contract | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE |

Current decision: **MIGRATION INCOMPLETE**. Passing regression and compilation do
not replace the missing internally testable Flutter acceptance journeys.

Remediation regression: Backend 127, Patient 89, Doctor 23 passed; zero skips/failures (239 total). Both debug APK commands completed with exit 0 and both analyses were clean. Four historical headless acceptance failures remain unresolved, not counted as current regression passes. See docs/doctor-mobile-e2e-remediation.md for case-level evidence.


## FINAL-E2E-ACCEPTANCE ? 2026-09-09

Previous decision: MIGRATION INCOMPLETE. Fresh OTP inspection still finds the provisioned-account rate limit active; no device is connected. These environment limitations do not establish product defects, but they prevent acceptance. No application, authorization or test source changed. Historical evidence and failures above remain intact. See docs/doctor-mobile-final-acceptance.md for fresh command results and case evidence.

| FEATURE | FLUTTER SCREEN | BACKEND API | DATABASE | E2E | SECURITY | DEVICE | STATUS |
|---|---|---|---|---|---|---|---|
| OTP/login | Login/session gate | Existing OTP/session endpoints | Existing User/Session/OtpChallenge | BLOCKED ? active request window | Regression reported separately | BLOCKED | BLOCKED |
| Home/appointment | Home/details | /doctor/appointments | Consultation + ownership | BLOCKED ? no Flutter booking | Regression reported separately | BLOCKED | BLOCKED |
| Profile/verification | Profile/session gate | /doctor/profile | Doctor | Native restart unverified | Regression reported separately | BLOCKED | BLOCKED |
| Availability/discovery | Availability; Patient doctor profile | /doctor/availability; /doctors/:id/slots | Availability/exclusions | Paired Flutter persistence unverified | Regression reported separately | BLOCKED | BLOCKED |
| Flutter booking | Patient booking; Doctor details | /consultations/book | Consultation/payment relationships | No new Flutter appointment ID | Regression reported separately | BLOCKED | BLOCKED |
| Consultation/lifecycle | Consultation | Existing action/access endpoints | Existing lifecycle | Flutter sequence not reached | Regression reported separately | BLOCKED | BLOCKED |
| Patient context/private notes | Consultation/notes | Existing authorized access/notes endpoints | ConsultationNote ownership | Flutter save/read-isolation not reached | Regression reported separately | BLOCKED | BLOCKED |
| Shared summary/follow-up | Doctor notes; Patient history | Existing notes/Patient detail endpoints | Existing shared/date fields | Not reached | Regression reported separately | BLOCKED | BLOCKED |
| Session restoration | Session gate | Existing session/logout endpoints | Session | Native restart unverified | Unauthenticated request 401 observed | BLOCKED | BLOCKED |
| Live video | Provider boundary | Existing provider contract | Unchanged | Provider required | NOT TESTED | BLOCKED | BLOCKED |

Decision: **MIGRATION INCOMPLETE**. No internal Flutter acceptance row was promoted to PASS based solely on regression/build results.

FINAL-E2E-ACCEPTANCE completed execution: Backend 127, Patient 89, Doctor 23 passed; zero skips/failures (239 total). Both analyses clean and both debug builds completed. Existing database-backed security regression passed. Fresh logs: artifacts/final-acceptance. Provisioned Flutter and native acceptance remain BLOCKED; no new parity PASS is claimed. See docs/doctor-mobile-final-acceptance.md.


## Final live retry ? current parity evidence

OTP eligibility is resolved by natural expiry. Preserve all earlier findings. Current evidence is scoped to real-HTTP headless Flutter; native storage/device behavior remains unverified.

| FEATURE | FLUTTER SCREEN | BACKEND API | DATABASE | E2E | SECURITY | DEVICE | STATUS |
|---|---|---|---|---|---|---|---|
| Doctor login/Home | Login/Home | Existing OTP/session/agenda | Existing identities | Both Doctor cases passed | Regression passed | BLOCKED | PASS |
| Patient login/discovery | Home/Doctor profile/slots | Existing auth/discovery/slots | Existing actors/slots | Login and slots reached | Regression passed | BLOCKED | PASS |
| Booking | Patient booking | Existing booking API | No new appointment | Review screen timeout; no confirmation | Regression passed separately | BLOCKED | FAIL |
| Doctor matching appointment/lifecycle/context | Appointment/consultation | Existing assigned-appointment endpoints | No Flutter-created acceptance appointment | Prerequisite failed | Regression passed separately | BLOCKED | BLOCKED |
| Private notes/summary/follow-up | Notes; Patient history | Existing notes/detail endpoints | No acceptance note | Not reached | Regression passed separately | BLOCKED | BLOCKED |
| Profile save/headless reload | Profile | /doctor/profile | Existing Doctor | Both headless cases passed | Regression passed | BLOCKED | PASS |
| Native profile/session persistence | Session gate/profile | Existing session/profile | Existing secure session contract | In-memory remount only | Regression passed separately | BLOCKED | BLOCKED |
| Availability modification and paired slot persistence | Availability; Patient slots | Existing availability/slots | Existing windows | Save passed; full modified-window journey unverified | Regression passed | BLOCKED | BLOCKED |
| Logout UI | Login/session gate | Existing logout | Existing sessions | Doctor A/B and Patient B passed | Regression logout denial passed | BLOCKED | PASS |
| Live video | Consultation | Existing provider | Unchanged | Provider required | NOT TESTED | BLOCKED | BLOCKED |

Fresh regression: 239 passed/0 failed/0 skipped. Live harnesses: 3 passed/1 failed. Both APKs compiled and analyses clean. No product/test changes. **MIGRATION INCOMPLETE.** See final acceptance report for precise scopes and failure evidence.

Late emulator evidence: emulator-5554 became available; both APK installs succeeded
and Doctor launch succeeded. Physical device still absent. Native journey evidence
is pending because the emulator changed under another operator's input; no login
or persistence PASS is inferred. Earlier no-emulator findings describe earlier checks.

### Native emulator evidence update

| FEATURE | FLUTTER SCREEN | BACKEND API | DATABASE | E2E | SECURITY | DEVICE | STATUS |
|---|---|---|---|---|---|---|---|
| Patient native OTP/Home | Login/Home | Existing OTP/session | Patient A USER | Native login/Home observed | Existing regression | Emulator | PASS |
| Native Flutter booking | Discovery/slots/review/confirmation | Existing booking endpoint invoked by app | 806a5c75-f39c-46d2-a94b-ca188e66dc20 CONFIRMED | Confirmation observed; read-only DB match | Existing regression, same-actor private-note checks pending | Emulator | PASS |
| Doctor native session restoration | Session gate/Home | Existing session/agenda | Doctor A | Force-stop/relaunch restored authenticated Home | Existing regression | Emulator | PASS |
| Native changed biography persistence | Profile | Existing profile endpoint | Prior value remained | New-value save not proven | Existing regression | Emulator | BLOCKED |
| Same-appointment Doctor actions/notes/summary/follow-up | Consultation | Existing endpoints | Future confirmed appointment | Not yet verified | Same-actor private-note journey pending | Emulator | BLOCKED |

Historical headless failure remains; native booking now supplies genuine positive
evidence. Full internal parity remains unproven: MIGRATION INCOMPLETE.

### Final native matrix corrections

| FEATURE | FLUTTER SCREEN | BACKEND API | DATABASE | E2E | SECURITY | DEVICE | STATUS |
|---|---|---|---|---|---|---|---|
| Doctor receives Patient booking | Upcoming/detail | Existing Doctor appointments | New UUID correlated by unique actors/time/state | Native matching details observed | New-appointment cross-account sequence pending | Emulator | PASS |
| Authorized appointment/provider boundary | Consultation detail | Existing consultation access/action | CONFIRMED remains | Patient A detail; early start denied | Timing boundary enforced | Emulator | PASS |
| Changed profile persistence | Profile | Existing profile API | Changed synthetic biography persisted | Save → force-stop → reopen → same value | Existing regression | Emulator | PASS |
| Native session restoration | Session gate/Home | Existing session API | Existing session | Restored after process restart | Existing regression | Emulator | PASS |
| Native logout/revocation | Logout | Existing logout | Remaining sessions inconclusive | Unexpected Patient-app capture; not proven | Unauthenticated API 401 only | Emulator | BLOCKED |
| In-progress/completion/notes/summary/follow-up | Consultation/notes | Existing endpoints | Future appointment; no acceptance note | Not yet permitted/reached | New-note isolation pending | Emulator | BLOCKED |
| Modified availability/native paired discovery | Availability/Patient slots | Existing availability/slots | Existing configuration | Full changed-window sequence unverified | Existing regression | Emulator | BLOCKED |

Final decision remains MIGRATION INCOMPLETE. Headless failure is preserved alongside
successful native booking evidence. See final report for exact scopes and remaining gaps.


## DOCTOR-REGISTRATION-01 - independent Doctor onboarding (2026-09-09)

This is a separately authorized registration extension. Historical migration and
live E2E results above are preserved; registration tests do not replace the original
Patient-to-Doctor booking/device acceptance evidence.

Implementation and evidence: [doctor-registration-implementation.md](doctor-registration-implementation.md).
Exact file scope: [doctor-registration-files.md](doctor-registration-files.md).

The Doctor Flutter project remains independent. All registration UI, Riverpod state
and routing live in Pocket Doctor Doctor. The Patient Flutter project's 77 Dart files
are unchanged (line endings normalized for comparison). Shared changes extend only
the existing backend and Admin system. No Doctor web portal was restored.

| Feature | Flutter screen | Backend API | Database | Automated evidence | Live dependency | Status |
| --- | --- | --- | --- | --- | --- | --- |
| Existing Doctor login | LoginScreen | Existing auth OTP/session | Existing User/Session | Existing regression retained | Production SMS separate | PASS |
| New Doctor OTP | Registration mode in LoginScreen | Purpose-bound registration OTP on existing IdentityService | OtpChallenge purpose; pending Doctor | PostgreSQL purpose/rate/role tests; Flutter entry test | Production SMS separate | PASS |
| Draft/basic/professional details | RegistrationScreen | GET/PATCH doctor/registration | Existing Doctor plus additive application fields | DB persistence/validation; Flutter steps | None for draft | PASS |
| Credentials | Documents step | Owner-scoped private document endpoints | DoctorCredential metadata | Owner/Admin denial and file contract tests | Private store and approved policy missing | BLOCKED |
| Submit and pending | Review/pending state | POST registration/submit | Existing PENDING_VERIFICATION + timestamps | Lifecycle API and Flutter tests | Actual documents cannot yet be uploaded | BLOCKED |
| Admin review/approval | Existing Admin Doctor management | Existing Admin namespace + registration review | Existing verification and audit | DB role/review/generic-PATCH bypass tests; Admin build | Live credentials review unavailable | BLOCKED |
| Rejection/resubmission | Correction steps and reason | review + draft + submit | Rejection reason and timestamps | DB transitions and Flutter correction state | Full live document journey unavailable | BLOCKED |
| Suspension | Access blocked | Existing operational verification gate | Existing SUSPENDED state | Existing session denied on next request | No new provider dependency | PASS |
| Private document isolation | Owner metadata; Admin private download | Authenticated owner/Admin checks | Doctor foreign key | Cross-role and cross-doctor API denial | Storage adapter itself unvalidated | BLOCKED |
| Patient project separation | Separate app | Shared API only | Shared models | Source integrity report | None | PASS |

Current registration acceptance: BLOCKED for the complete live lifecycle because
private storage and approved required-document policy are not configured. Submission
and approval fail closed. Automated contract coverage must not be represented as
live upload, physical-device acceptance or production readiness.


Registration final validation: Doctor 32, Patient 89, backend 138 and Admin 16 tests
pass (275 total, zero skipped/failed in final runs). Both Flutter analyses and both
independent debug APK builds pass; Admin build and backend TypeScript pass. Prisma
has 15 current migrations and no drift. A concurrent backend run hit transaction/query
timeouts; its log remains available and a subsequent isolated run passed unchanged.
Private storage/policy and live registration/device acceptance remain BLOCKED.
See the registration implementation report for evidence and exact scope.


## DOCTOR-REGISTRATION-02 private storage follow-up

Independent Doctor Flutter only; Patient Flutter source unchanged. The shared backend
now implements disabled-by-default encrypted local-test storage behind the existing
contract, with mandatory scanning and authenticated private retrieval. Atomic same-owner
replacement reuses the upload API. No new database migration or Admin system.

| Feature | Evidence | Status |
| --- | --- | --- |
| Encrypted local test adapter | Real filesystem persistence/tampering/failure tests | PASS |
| Private ownership and replacement | PostgreSQL API tests; current-record replacement | PASS |
| Doctor upload state and retry | Typed Riverpod/repository tests | PASS |
| Real scanner availability | Defender failed synthetic probe, exit 2 / 0x80004005 | BLOCKED |
| Required credentials / retention approval | No approved policy supplied | BLOCKED |
| Live Flutter upload -> submit -> approval | Not established through functioning scanner/policy | BLOCKED |
| Live rejection/replacement/resubmission | Not established | BLOCKED |
| Native registration/session restart | Not validated in this phase | BLOCKED |

Current live registration acceptance remains BLOCKED. Implementation and evidence:
[doctor-registration-storage.md](doctor-registration-storage.md). Historical migration
and registration findings above are preserved; automated tests do not close live E2E gaps.

Storage follow-up final regression: 284 passed, zero skipped/failed (Doctor 35, Patient 89, backend 144, Admin 16). Both independent APK builds and Flutter analyses pass. No attached Android device, the failed real scanner probe and missing approved document/retention policy leave live registration BLOCKED. Historical migration acceptance is unchanged.


## DOCTOR-REGISTRATION-03 provider configuration audit

Current evidence: [doctor-registration-live-storage.md](doctor-registration-live-storage.md).
Cloudinary variable names exist as reserved deployment placeholders; no approved or
configured private credential provider/adapter was found. The neutral storage
contract already exists. No provider was selected, no local adapter enabled, and no
application, backend, Patient, Admin, database or test source changed in this phase.

Live registration remains BLOCKED pending provider approval/configuration and
DOCUMENT POLICY APPROVAL REQUIRED. The local encrypted adapter is not production
storage. All previous implementation, failures and acceptance evidence remain intact.

Registration-03 final validation: Doctor 35, Patient 89, backend 144 and Admin 16 tests passed (284 total, zero skipped/failed). Both Flutter analyses and independent debug APK builds passed; backend typecheck/build, Admin build and Prisma validation passed, with 15 current migrations and no drift. See doctor-registration-live-storage.md and artifacts/registration-live-storage. No product or Patient source changed. Provider-backed lifecycle and device acceptance remain BLOCKED; automated fixtures are not live storage evidence.


## Approved production storage follow-up

See [doctor-registration-production-storage.md](doctor-registration-production-storage.md). Fresh configuration/device recheck still finds no configured approved provider, document policy or attached Android device. Existing 284 passing tests and successful builds are retained from the immediately preceding unchanged-source run, not represented as new execution. No application/schema/test changes. Live registration remains BLOCKED.


## Storage configuration contract and readiness diagnostic

See [doctor-registration-storage-configuration.md](doctor-registration-storage-configuration.md) for the single configuration contract and secret-free diagnostic. Existing backend validator and adapter factory are reused; no product/schema/Patient changes. Missing provider and document-policy approval still block live acceptance. Prior evidence is preserved.

Configuration-contract validation: fresh Doctor 35, Patient 89, backend 144, Admin 16 plus four readiness tests passed (288 total; zero skips/failures). Both Flutter analyses/debug APKs, backend typecheck/build, Admin build and Prisma checks passed. Live storage/registration remains BLOCKED. See doctor-registration-storage-configuration.md.


## Final live-storage acceptance retry

See [doctor-registration-live-storage-final.md](doctor-registration-live-storage-final.md). Fresh configuration presence and ADB checks still show no provider configuration, document policy or attached device. Live acceptance stopped as required. Previous 288 passing tests/builds are retained evidence, not rerun or relabeled as live. No source/schema changes or database mutations. Status: BLOCKED.


## Development document deferral

The explicit default-off DOCTOR_REGISTRATION_DEFER_DOCUMENTS flag is enabled only in the isolated development runtime. Documents can be deferred; professional validation and existing Admin approval remain required. Real local OTP, zero-document submission, pending denial, Admin approval and a fresh DOCTOR/READY login succeeded. Native Home/device acceptance remains unverified. See doctor-registration-document-deferral.md. Production storage blockers and prior evidence remain unchanged.

Document-deferral final checks: Doctor 37, Patient 89, backend 146 and Admin 16 passed; zero skips/failures in final runs. Both analyses and Doctor debug APK passed. Real Admin-approved login returned DOCTOR/READY. Native Home acceptance remains blocked by no device. Historical failed attempts are retained.


## Phase 8 Doctor mobile acceptance

See [phase-8-doctor-app-acceptance.md](phase-8-doctor-app-acceptance.md). Existing independent Doctor screens retained; Android Back returns secondary tabs to Home. Real local OTP/READY/profile/availability/appointments and logout revocation checks passed. Documents remain development-deferred. Native acceptance remains blocked without a device; no live video claim. Earlier evidence is preserved.

Phase 8 final regression: Doctor 38 (+1 navigation test), Patient 89, backend 146, Admin 16; total 289 passed with zero skips/failures. Both analyses/APKs, backend typecheck/build, Admin build and Prisma checks passed. Full native acceptance remains BLOCKED, distinct from passing API/widget coverage.
