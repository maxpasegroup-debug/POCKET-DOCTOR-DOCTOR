# E2E-REMEDIATION-01 — Doctor Flutter acceptance

Date: 2026-09-09. Decision: **MIGRATION INCOMPLETE**.
This report preserves earlier failures and distinguishes regression evidence from
acceptance using the provisioned Patient A/Doctor A identities on actual devices.

## Environment and OTP investigation

The existing verified local PostgreSQL test database and shared API are reachable:
`pocket_doctor_test` on loopback port 55433; API at
`http://127.0.0.1:3018/api/v1`. Private environment remains in the ignored,
ACL-protected `.validation/environment/runtime.json`; no credentials are included.
No backend or database architecture was added.

The existing OTP service generates a random six-digit development challenge,
retains only its hash, expires challenges after five minutes, enforces a one-minute
request cooldown and five requests per phone per hour. Production authentication
was not changed. Inspection found no documented test-only reset mechanism.
`cleanup-auth.ts` deliberately retains phone cooldown state for one hour; invoking
it early would not make these accounts eligible and it was not used as a bypass.

Read-only inspection at approximately 10:49 IST showed all four provisioned
Doctor/Patient accounts had used five requests. Their windows end approximately
11:16:22 IST (05:46:22Z). Evidence: `artifacts/remediation/otp-window-inspection.json`.
No further acceptance OTP requests were sent while those accounts were ineligible.
No counters, session records, clocks, phone numbers or roles were altered to evade
that limit. **OTP ACCEPTANCE = BLOCKED** for that window. Regression suites retain
their own existing synthetic fixtures and do not impersonate the provisioned actors.

## Device observation

Initial adb discovery found the physical phone **unauthorized**. USB debugging
approval was requested from the user. Subsequent discovery showed no connected
phone. Neither condition permits app installation, control or native evidence.
Previous-phase successful installation does not establish current acceptance.
**ANDROID DEVICE = BLOCKED — NO CONNECTED DEVICE** at the subsequent checks.
This is an environment limitation, not a product defect.

## Acceptance harness remediation

No product source changed. The existing headless Patient harness now explicitly
scrolls to Reserve this time after reaching the review screen. Its provider
container and real HTTP client are disposed in a finally block, including failure
paths. The Doctor harness likewise unmounts and closes its real transports in a
finally block. A final virtual-widget timer drain is harness cleanup only; it does
not alter the backend clock or appointment timestamps. No HTTP response is mocked.

The Patient executable harness is in the ignored validation copy; the reviewable
copy is `acceptance/patient_live_ui_test.dart.template`. Doctor harness:
`acceptance/doctor_live_ui_test.dart`. These changes are not reported as passing
acceptance until replay succeeds. The four earlier failed acceptance cases and
their logs remain in the preceding E2E report; no test was removed or newly skipped.

## Acceptance cases

Evidence paths in this table are relative to `artifacts/remediation/` unless
explicitly stated. PASS applies only to the stated scope; BLOCKED does not mean
that an application defect was proven.

| Test | Actor | Action | Expected | Actual | Evidence | Status |
|---|---|---|---|---|---|---|
| Environment | Test runner | Read database identity/catalog | Verified test database reachable | Connected to existing known local test database | Environment inspection and prior doctor-test-environment.md | PASS |
| OTP mechanism | Test runner | Inspect service and cleanup | Existing safe mechanism, no bypass | Development OTP exists; no test-only throttle reset | identity-service.ts; cleanup-auth.ts | PASS |
| Acceptance OTP | Doctor A/B, Patient A/B | Establish eligible real login | OTP → session | All four still at hourly limit during inspection; no bypass attempted | otp-window-inspection.json | BLOCKED |
| Patient login | Patient A | Actual Flutter login | Patient Home, USER | Provisioned-account replay blocked | OTP/device evidence | BLOCKED |
| Doctor login | Doctor A | Actual Flutter login | Doctor Home, DOCTOR | Provisioned-account replay blocked | OTP/device evidence | BLOCKED |
| Flutter booking | Patient A → Doctor A | Discovery → slots → booking → confirmation | Confirmed appointment ID | No new acceptance appointment created this phase | OTP/device evidence | BLOCKED |
| Shared Doctor appointment | Doctor A | Open same Flutter-created appointment | Matching ID/patient/date/state | No completed Flutter booking to open | Booking prerequisite | BLOCKED |
| Main lifecycle | Doctor A | CONFIRMED → IN_PROGRESS → COMPLETED | Supported transitions on same booking | No successful replay on that shared Flutter booking | Booking/OTP prerequisite | BLOCKED |
| Other lifecycle | Patient/Doctor | Cancel/reschedule/no-show/expiry | Existing valid rules only | Existing regression coverage, not new provisioned-account device evidence | Backend suite recorded below | BLOCKED |
| Consultation boundary | Doctor A | Open consultation and existing actions | Authorized context and supported actions | Flutter journey not replayed | OTP/device evidence | BLOCKED |
| Live video | Doctor A + Patient A | Real video/audio connection | Configured provider | Provider unavailable; no simulated call | Existing provider boundary | BLOCKED |
| Patient context | Doctor A | Open Patient A only via assigned appointment | ALLOWED; unrelated context DENIED | No new Flutter journey; backend security suite separate | Backend suite recorded below | BLOCKED |
| Private notes | Doctor A, Doctor B, Patient A/B | Create/save/reload and attempt unrelated reads | Owner can read; others denied | No note created through Doctor Flutter in this phase | Booking/OTP prerequisite | BLOCKED |
| Shared summary | Doctor A → Patient A | Save then view after completion | Summary visible, private note absent | Existing feature; journey not reached | Existing notes DTO contract | BLOCKED |
| Follow-up | Doctor A → Patient A | Save date/details, reload both apps | Persisted relationship and intended visibility | Flutter journey not reached | Booking/OTP prerequisite | BLOCKED |
| Profile persistence | Doctor A | Edit/save/reopen/process restart | Values persist; Doctor B unchanged | Native restart not observed | OTP/device evidence | BLOCKED |
| Availability persistence | Doctor A + Patient A | Save/restart/discover slots | Persisted settings reflected in slots | Native restart and cross-app replay not observed | OTP/device evidence | BLOCKED |
| Native session restore | Doctor A | Close without logout, reopen | Doctor Home for valid session | No authorized connected device | Device evidence | BLOCKED |
| Native logout restore | Doctor A | Logout, restart, protected request | Login/401 | No native replay; regression revocation tests separate | Device/backend evidence | BLOCKED |
| Device UI/UX | Patient/Doctor | Touch, keyboard, scroll, back, controls, orientation | Functional controls without defects | No usable physical device; no defect inferred | adb discovery | BLOCKED |
| No fake booking | Test runner | Review mutations in this phase | No direct acceptance appointment insertion | No acceptance appointment was inserted or time-shifted | Scripts/source audit | PASS |

**LIVE VIDEO = BLOCKED — PROVIDER REQUIRED.** Shared summary and follow-up are
existing functionality, so they are not labelled NOT IMPLEMENTED merely because
acceptance is blocked. Device absence is not a product failure.

## Execution and remaining work

Patient and Doctor analysis/tests/debug builds are executed sequentially, followed
by the unchanged complete backend suite. Patient uses all seven existing live
smoke flags with the explicit test backend. These genuine live repository tests
are not relabelled as native Patient A/Doctor A screen acceptance. Final commands,
counts and build results are recorded below after completion.

After the legitimate OTP window and device authorization are available, use one
login per actor and retain the valid session through the workflow instead of
repeated login attempts. Book only through Patient Flutter. Use the backend slot
lead time (15 minutes) and Doctor start window (10 minutes before start) as-is;
wait for the natural window, never change appointment timestamps or server time.
Capture the returned appointment ID, follow that exact ID in Doctor Flutter,
complete notes/summary/follow-up and privacy checks, then logout last.

## Completed execution results

| TEST | ACTOR | ACTION | EXPECTED | ACTUAL | EVIDENCE | STATUS |
|---|---|---|---|---|---|---|
| Patient analysis | Existing Patient snapshot | flutter analyze | Clean | No issues | artifacts/remediation/patient-analyze.log | PASS |
| Patient regression | Existing suite fixtures | flutter test --concurrency=1 with all seven existing live smoke flags | 89 pass, zero skips/failures | 89 pass, 0 skipped, 0 failed | artifacts/remediation/patient-tests.log | PASS |
| Patient debug APK | Existing Patient snapshot | flutter build apk --debug with explicit test API and development OTP display | Successful compilation | Exit 0; APK built in 91.4s Gradle task | artifacts/remediation/patient-debug-build.log; patient-exits.json | PASS |
| Doctor analysis | Doctor project | flutter analyze | Clean | No issues | artifacts/remediation/doctor-analyze.log | PASS |
| Doctor regression | Existing suite | flutter test | 23 pass | 23 pass, 0 skipped, 0 failed | artifacts/remediation/doctor-tests.log | PASS |
| Doctor debug APK | Doctor project | flutter build apk --debug with explicit test API and development OTP display | Successful compilation | Exit 0; APK built in 33.7s Gradle task | artifacts/remediation/doctor-debug-build.log; doctor-exits.json | PASS |
| Backend regression | Existing isolated database fixtures | node scripts/doctor-test-environment.mjs test | 127 pass, zero skips/failures | 127 pass, 0 skipped, 0 failed; exit 0 | artifacts/remediation/backend-tests.log; backend-exit.json | PASS |
| Security regression | Existing database-backed fixtures | Unchanged auth, doctor-session and consultations integration tests | Server-enforced denial and privacy | All included cases passed | artifacts/remediation/backend-tests.log | PASS |
| Product source comparison | Authoritative platform snapshot | Compare tracked source/test files after newline normalization | No product changes | 186 files compared; zero differences; authoritative Git clean | artifacts/remediation/environment-source-audit.json | PASS |
| Physical device final discovery | Android adb | devices -l | Authorized connected phone | Empty device list at 10:56 IST | artifacts/remediation/android-devices.txt | BLOCKED |

Current regression totals: **239 passed, 0 skipped, 0 failed** (127 backend + 89
Patient + 23 Doctor). Counts match the requested baseline. This excludes the four
historically failed acceptance-harness cases, which were not replayed in this
phase because of the provisioned-account OTP window. Those previous failures
remain recorded in artifacts/e2e and the earlier report; no tests or skip conditions
were removed or weakened. Backend regression fixtures are not claimed as a
Patient A → Doctor A Flutter booking.

Security regression covers role boundaries, assigned-doctor context, profile and
availability ownership, patient DTO omission of private notes, invalid/expired OTP,
request caps, expiry and logout revocation. See the named integration tests in
services/api/test/{auth,doctor-session,consultations}.integration.test.ts. This is
actual PostgreSQL-backed regression evidence, but the missing Flutter-created
note and provisioned cross-user read-isolation sequence remain BLOCKED.

Commands use API_BASE_URL=http://127.0.0.1:3018/api/v1. The seven Patient flags are
RUN_API_SMOKE, RUN_AUTH_SMOKE, RUN_PROGRAM_SMOKE, RUN_CONSULTATION_SMOKE,
RUN_COMMERCE_SMOKE, RUN_ASSISTANT_SMOKE and RUN_MEMBERSHIP_SMOKE, all true.
Both debug builds also set SHOW_DEVELOPMENT_OTP=true using the existing mechanism.
These are local test artifacts, not production/store-ready releases.

APKs: Doctor build/app/outputs/flutter-apk/app-debug.apk; Patient
.validation/platform/apps/mobile/build/app/outputs/flutter-apk/app-debug.apk.
No current device installation was possible. Store signing and iOS validation
were not performed. The previously supplied Doctor launcher artwork is present;
this phase did not redesign branding.

## Files and final decision

Created: docs/doctor-mobile-e2e-remediation.md and artifacts/remediation evidence.
Modified: docs/doctor-mobile-migration.md, docs/doctor-mobile-files.txt,
acceptance/doctor_live_ui_test.dart, acceptance/patient_live_ui_test.dart.template,
and its ignored executable copy under .validation/platform/apps/mobile/acceptance.
The environment test runner refreshed its existing artifacts/environment logs;
the complete new backend result was copied into artifacts/remediation.
No application/business source was changed.

Remaining blockers: provisioned-account OTP window; no connected authorized
physical device; Flutter booking confirmation and same-appointment Doctor journey;
Flutter consultation/notes/shared-summary/follow-up; native profile/availability and
session persistence. Live video remains BLOCKED — PROVIDER REQUIRED.
Patient compilation is now closed. Current matrix is appended to the migration
report without removing any historical findings.

**FINAL DECISION: MIGRATION INCOMPLETE.**

Final Patient analysis after the acceptance harness edits also passed (exit 0, no issues); evidence: artifacts/remediation/patient-analyze-final.log. Targeted secret scan checked 24 evidence/document/harness files with zero configured-secret or credential-pattern candidates; private runtime excluded. Evidence: artifacts/remediation/secret-scan.json.


## Subsequent FINAL-E2E-ACCEPTANCE attempt ? 2026-09-09

Fresh read-only inspection still finds the provisioned accounts rate limited until approximately 11:16:22 IST. Android has no connected device. No OTP bypass or new appointment was attempted. The new report docs/doctor-mobile-final-acceptance.md records fresh regression/build execution and the blocked cases; it does not erase the historical four failed acceptance tests. Decision remains MIGRATION INCOMPLETE.

FINAL-E2E-ACCEPTANCE completed execution: Backend 127, Patient 89, Doctor 23 passed; zero skips/failures (239 total). Both analyses clean and both debug builds completed. Existing database-backed security regression passed. Fresh logs: artifacts/final-acceptance. Provisioned Flutter and native acceptance remain BLOCKED; no new parity PASS is claimed. See docs/doctor-mobile-final-acceptance.md.


## FINAL LIVE RETRY ? completed 2026-09-09

OTP cleared naturally; all four actors authenticated through unchanged real-HTTP Flutter harnesses. Doctor harness: 2 passed. Patient harness: 1 passed/1 failed; Patient A reached slot selection but timed out waiting for Review your reservation (line 103). No booking ID was produced. No test or application changes were made. Both analyses/builds completed; existing regression remains 239 passed/0 skipped/0 failed. Combined with the live cases: 242 passed/1 failed/0 skipped. Native device absent. Detailed case evidence: docs/doctor-mobile-final-acceptance.md and artifacts/live-retry. MIGRATION INCOMPLETE.

Late device update: an authorized emulator appeared. Both test APKs installed and
Doctor launch succeeded. The OTP screen then changed without agent input; emulator
control was queried before further interaction. This is not physical-device or
native journey acceptance. See the final acceptance report's scope correction.

Native emulator update: with user-authorized control, Patient A created appointment
806a5c75-f39c-46d2-a94b-ca188e66dc20 through Flutter and saw confirmed booking for
Doctor A, September 10 09:00 IST. Native Doctor session restoration passed after
force-stop/relaunch. Headless booking failure remains recorded but native booking
is now PASS. Full same-appointment Doctor lifecycle/notes/follow-up is still not
validated. Detailed native evidence and limitations are appended to the final report.

Latest native evidence: Doctor Upcoming/detail matched the new Patient Flutter
booking via unique patient/time/state and read-only database UUID correlation.
Start was correctly rejected for the future appointment; no notes were enabled.
Changed biography save/restart/reload now PASS, superseding the initial input issue.
Native session restoration PASS; native logout/revocation remains inconclusive.
Full lifecycle, note/summary/follow-up, changed availability persistence and new
appointment cross-account checks remain BLOCKED. MIGRATION INCOMPLETE.
