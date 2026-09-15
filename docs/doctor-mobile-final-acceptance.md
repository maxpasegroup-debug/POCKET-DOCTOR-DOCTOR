# FINAL-E2E-ACCEPTANCE ? 2026-09-09

Decision: **MIGRATION INCOMPLETE** pending genuine internal Flutter acceptance.

## Environment and scope

Existing isolated PostgreSQL: loopback port 55433, database pocket_doctor_test. Shared API: http://127.0.0.1:3018/api/v1. Development OTP mode confirmed without printing secrets. Read-only inspection at 10:59:41 IST found all four provisioned identities capped at five requests until approximately 11:16:22 IST. **OTP = BLOCKED ? RATE LIMIT ACTIVE**. No OTP request, reset, counter change, clock change, alternative identity or session bypass was used for acceptance.

**ANDROID DEVICE = BLOCKED ? NO CONNECTED DEVICE**. Headless authenticated journeys are also blocked by the same provisioned-account window. Regression fixtures remain separate and are not relabelled as these journeys. No production readiness claim.

No product, business, authorization, test or skip-condition changes were made in this phase. No acceptance appointments were created through SQL, API utilities or Flutter in this blocked attempt. Previous API booking evidence is not a Flutter-created booking. Previous failed acceptance runs remain documented.

## Acceptance cases

Evidence filenames below are under artifacts/final-acceptance unless stated otherwise.

| TEST | ACTOR | ACTION | EXPECTED | ACTUAL | EVIDENCE | STATUS |
|---|---|---|---|---|---|---|
| OTP eligibility | Doctor A/B; Patient A/B | Read existing request windows | Eligible without bypass | All four capped; windows end 11:16:22 IST | environment.json | BLOCKED |
| Backend connectivity | Unauthenticated client | GET /doctor/session | 401 | HTTP 401 | environment.json | PASS |
| Android device | adb | devices -l | Authorized physical device | No connected device | android-devices.txt | BLOCKED |
| Patient Flutter login | Patient A | Launch ? OTP ? Home | Correct USER session | Not attempted while rate limited | environment.json | BLOCKED |
| Doctor Flutter login | Doctor A | Launch ? OTP ? Home | Correct DOCTOR session | Not attempted while rate limited | environment.json | BLOCKED |
| Doctor discovery | Patient A | Find Doctor A ? generated slot | Real backend slots shown | Authenticated Flutter journey blocked | environment.json | BLOCKED |
| Flutter booking | Patient A | Select ? review ? confirm | Real Flutter-created appointment | No booking attempted or appointment inserted | environment.json | BLOCKED |
| Shared appointment | Doctor A | Find exact Patient Flutter booking | Matching ID, actors, time, state | No new Flutter booking ID exists | environment.json | BLOCKED |
| Lifecycle | Doctor A | CONFIRMED ? IN_PROGRESS ? COMPLETED | Only valid transitions | Same-appointment Flutter sequence unavailable | environment.json | BLOCKED |
| Patient context | Doctor A/B; Patient A/B | Read authorized and unrelated context | Allowed/denied according to ownership | Provisioned-actor sequence blocked; regression recorded separately | environment.json | BLOCKED |
| Private notes | Doctor A/B; Patient A/B | Flutter create ? reload ? cross-account read | Only assigned Doctor reads private note | Flutter-created note sequence not reached | environment.json | BLOCKED |
| Shared summary | Doctor A; Patient A | Create shared summary ? Patient view | Only intended shared fields visible | Existing feature; not reached, not labelled absent | environment.json | BLOCKED |
| Follow-up | Doctor A; Patient A | Save ? reload ? permitted Patient view | Persisted relationship/date/details | Flutter journey not reached | environment.json | BLOCKED |
| Profile persistence | Doctor A | Save biography ? reopen ? restart | Persisted values | Native restart unavailable; historical API evidence retained | android-devices.txt | BLOCKED |
| Availability persistence | Doctor A; Patient A | Save ? restart ? discover slots | Persisted configuration affects generated slots | Native restart and paired Flutter journey unavailable | android-devices.txt | BLOCKED |
| Session restoration | Doctor A | Login ? close ? reopen ? logout | Restoration then protected denial | Native process restart unavailable | android-devices.txt | BLOCKED |
| Provisioned cross-account security | Doctor A/B; Patient A/B; Admin | Direct protected requests with actor sessions | Server-enforced ownership/roles | No new actor sessions; existing regression run separately | environment.json | BLOCKED |
| Live video | Doctor A | Use configured provider | Genuine provider session | BLOCKED ? PROVIDER REQUIRED; no simulated call | Prior migration/provider evidence | BLOCKED |
| Device UI/UX | Doctor and Patient | Keyboard, navigation, scrolling, forms, relaunch | Usable native behavior | No authorized physical device | android-devices.txt | BLOCKED |

## Execution results

Fresh Doctor and Patient analysis, tests and debug builds run sequentially, followed by the complete unchanged backend suite. Results are appended only after commands finish.
## Validation command scope

Doctor commands: flutter analyze; flutter test; flutter build apk --debug.
Patient commands: flutter analyze; flutter test --concurrency=1 with all seven
existing live smoke flags enabled; flutter build apk --debug.
Both debug builds explicitly target API_BASE_URL=http://127.0.0.1:3018/api/v1
and SHOW_DEVELOPMENT_OTP=true using the existing supported test mechanism.
Patient flags: RUN_API_SMOKE, RUN_AUTH_SMOKE, RUN_PROGRAM_SMOKE,
RUN_CONSULTATION_SMOKE, RUN_COMMERCE_SMOKE, RUN_ASSISTANT_SMOKE,
RUN_MEMBERSHIP_SMOKE. Backend: node scripts/doctor-test-environment.mjs test,
which runs the existing complete suite with the guarded private test environment.
No flag/skip condition or test implementation was modified.

The existing API/database-backed regression includes separate synthetic fixtures
for authorization, private-note DTO isolation, profile/availability ownership,
OTP abuse controls, session expiry and logout. Those tests are not the missing
provisioned Patient A ? Doctor A Flutter acceptance sequence.

Source audit: 186 tracked platform source/test files compared with zero differences;
authoritative platform Git status clean. Evidence: artifacts/final-acceptance/
environment-source-audit.json. Its absent process-level DATABASE_URL observation
is not an infrastructure failure: the runner supplies the verified private runtime
to its child processes. Actual test database connectivity is recorded separately.


## Completed Flutter execution

| TEST | ACTOR | ACTION | EXPECTED | ACTUAL | EVIDENCE | STATUS |
|---|---|---|---|---|---|---|
| doctor analyze | Existing doctor project | flutter analyze | Successful completion | No issues; exit 0 | artifacts/final-acceptance/doctor-analyze.log | PASS |
| doctor tests | Existing doctor project | Existing flutter test suite | Successful completion | 23 passed, 0 skipped, 0 failed; exit 0 | artifacts/final-acceptance/doctor-tests.log | PASS |
| doctor build | Existing doctor project | flutter build apk --debug | Successful completion | APK compilation completed; exit 0 | artifacts/final-acceptance/doctor-build.log | PASS |
| patient analyze | Existing patient project | flutter analyze | Successful completion | No issues; exit 0 | artifacts/final-acceptance/patient-analyze.log | PASS |
| patient tests | Existing patient project | Existing flutter test suite | Successful completion | 89 passed, 0 skipped, 0 failed; exit 0 | artifacts/final-acceptance/patient-tests.log | PASS |
| patient build | Existing patient project | flutter build apk --debug | Successful completion | APK compilation completed; exit 0 | artifacts/final-acceptance/patient-build.log | PASS |

Doctor Gradle assembleDebug: 24.3 seconds. Patient: 76.9 seconds. Both APKs completed. These are test builds targeting the shared loopback API, not store-signed production artifacts. Native installation was not possible without a connected authorized device.


## Backend and final outcome

| TEST | ACTOR | ACTION | EXPECTED | ACTUAL | EVIDENCE | STATUS |
|---|---|---|---|---|---|---|
| Backend regression | Existing isolated fixtures | Complete existing suite | 127 passed, no skips/failures | 127 passed, 0 skipped, 0 failed; exit 0 | artifacts/final-acceptance/backend-tests.log; backend-exit.json | PASS |
| Security regression | Existing database-backed fixtures | Existing auth, doctor-session and consultation tests | Server authorization, ownership and privacy preserved | All existing cases passed | artifacts/final-acceptance/backend-tests.log | PASS |
| Final device discovery | adb | devices -l | Authorized device | Empty device list | artifacts/final-acceptance/android-devices-final.txt | BLOCKED |

Fresh regression total: **239 passed, 0 skipped, 0 failed**. Baseline unchanged. The four historical failed headless acceptance cases were not rerun or deleted; they are excluded from these existing regression-suite counts and remain unresolved in previous reports. Native restart and the provisioned Flutter booking/consultation/note/summary/follow-up sequence remain unverified.

Created docs/doctor-mobile-final-acceptance.md and artifacts/final-acceptance evidence. Updated docs/doctor-mobile-e2e-remediation.md, docs/doctor-mobile-migration.md and docs/doctor-mobile-files.txt. Existing artifacts/environment test output was refreshed by the unchanged runner and copied into this phase. No product/test/harness source changes.

Remaining blockers: OTP request window (ends approximately 11:16:22 IST), no authorized Android device, authenticated Flutter booking and same-appointment Doctor journey, private-note/shared-summary/follow-up acceptance, native profile/availability/session restart. Live video requires a provider. Production SMS, signing, iOS and deployment are not certified. No new appointment ID was produced.

**FINAL DECISION: MIGRATION INCOMPLETE.**

## FINAL LIVE ACCEPTANCE RETRY — 2026-09-09

Evidence for this attempt is under artifacts/live-retry. No application, backend,
authorization or test/harness source is changed. The first read-only account query
used a nonexistent User.role column and returned PostgreSQL 42703; it was corrected
to read the existing UserRole relationship. No database mutation occurred.
The successful check confirmed five synthetic identities with DOCTOR, DOCTOR,
USER, USER and ADMIN roles. All 14 Prisma migrations are current. Development OTP
is enabled; unauthenticated GET /doctor/session returns HTTP 401.

Contrary to the prompt's timing assumption, the actual database clock at the
initial check was 11:08:48 IST and all four account windows remained active until
approximately 11:16:22 IST. This attempt waits for natural eligibility, without
changing counters or requesting OTP while blocked. adb reported no connected
device: ANDROID DEVICE = BLOCKED — NO AUTHORIZED DEVICE.

The unchanged headless Flutter harnesses use actual widgets and real HTTP, with
transient session storage. They cannot establish native process restart or device
UX acceptance. Their results will be recorded separately from existing regression.


### Live retry completed results

All evidence filenames below are under artifacts/live-retry.

| TEST | ACTOR | ACTION | EXPECTED | ACTUAL | EVIDENCE | STATUS |
|---|---|---|---|---|---|---|
| Environment/migrations/accounts | Test operator | Verify existing local PostgreSQL, Prisma and roles | Safe reachable test environment | PASS: 14 migrations current; five correct synthetic roles; unauthenticated API 401 | environment.json; prisma-status.log | PASS |
| OTP eligibility | Doctor A/B; Patient A/B | Wait until natural expiry, then existing Flutter OTP flow | No bypass; backend OTP verification | Initial window active; recheck at 11:16:46 IST eligible; all four actors subsequently authenticated | environment-initial.json; environment.json; patient-ui.log; doctor-ui.log | PASS |
| Patient A login/Home | Patient A | Existing Flutter widgets ? OTP ? Home | Correct synthetic USER and session | Identity assertion and Home passed before later booking failure; real HTTP, transient storage | patient-ui.log; unchanged harness before line 103; environment.json | PASS |
| Patient B login/Home/logout | Patient B | Existing Flutter login/Home test | Correct USER, Home, logout | Whole case passed | patient-ui.log | PASS |
| Doctor A/B login/Home | Doctor A/B | Existing Flutter widgets ? OTP ? Home | Correct DOCTOR identity and Home | Both complete cases passed; expected profile names asserted | doctor-ui.log; environment.json | PASS |
| Doctor discovery/profile/slots | Patient A | Search Doctor A ? profile ? available ChoiceChip | Actual backend-generated slot shown | Reached slot selection and Review reservation tap before later timeout | patient-ui.log; unchanged harness lines 73?103 | PASS |
| Flutter booking confirmation | Patient A | Select slot ? Review reservation ? confirmation | Review screen then real booking confirmation | FAIL: timed out waiting for Review your reservation at harness line 103. Reserve this time was never reached. No booking ID artifact exists | patient-ui.log; ui-exits.json | FAIL |
| Same appointment in Doctor UI | Doctor A | Find Patient Flutter booking by exact ID | Matching actors/time/status/ID | No Flutter booking ID produced; not substituted with historical API booking | Patient booking prerequisite failed | BLOCKED |
| Lifecycle/consultation actions | Doctor A | Use same Flutter-created appointment | Valid CONFIRMED ? IN_PROGRESS ? COMPLETED | Prerequisite booking unavailable; no forced transitions | Patient booking prerequisite failed | BLOCKED |
| Authorized patient context | Doctor A | Open same appointment context | Only authorized Patient A context | Provisioned-journey check not reached; regression separate | Patient booking prerequisite failed | BLOCKED |
| Private note create/reload/isolation | Doctor A/B; Patient A/B | Flutter note creation then actual read authorization | Assigned Doctor only | No acceptance note created; journey blocked | Patient booking prerequisite failed | BLOCKED |
| Shared summary | Doctor A; Patient A | Save shared fields then Patient view | Shared summary visible; private note absent | Existing feature not reached; not labelled unimplemented | Patient booking prerequisite failed | BLOCKED |
| Follow-up | Doctor A; Patient A | Save/reload follow-up then permitted Patient view | Persistence and correct visibility | Not reached | Patient booking prerequisite failed | BLOCKED |
| Profile save/headless reload | Doctor A/B | Enter synthetic biography/languages ? save ? remount ? reload | Save success and expected bio retained | Both harness cases passed. Same existing synthetic values are used; not proof of native restart | doctor-ui.log | PASS |
| Availability save | Doctor A/B | Open existing availability ? Save | Existing API accepts save | Availability saved observed in both passed cases; harness does not alter a window or prove paired slot changes | doctor-ui.log | PASS |
| Availability modification/native persistence/paired slots | Doctor A; Patient A | Modify ? native restart ? Patient slot check | Changed configuration persists and affects discovery | No authorized native device; unchanged harness lacks this full journey | android-devices.txt; unchanged harness scope | BLOCKED |
| Native profile/session restoration | Doctor A | Close process ? reopen | Secure-storage session and profile restore | Only in-memory store remount passed; native process restart unavailable | android-devices.txt; doctor-ui.log | BLOCKED |
| Logout in headless UI | Doctor A/B; Patient B | Logout ? login screen, cleared store | Unauthenticated UI | Whole cases passed; post-logout API denial is covered separately by regression, not asserted by this harness | doctor-ui.log; patient-ui.log | PASS |
| Cross-account/security regression | Existing separate test fixtures | Complete existing database-backed auth/doctor/consultation suite | Ownership, role and privacy protections | 127 existing backend tests passed, including security cases | backend-tests.log | PASS |
| Provisioned-actor cross-account private-note sequence | Doctor A/B; Patient A/B | Direct API checks against Flutter-created note/context | Server denial | Cannot test against missing Flutter-created appointment/note; existing fixture regression is not relabelled | Booking prerequisite failed | BLOCKED |
| Live video | Doctor A | Use real video provider | Genuine provider session | LIVE VIDEO = BLOCKED ? PROVIDER REQUIRED; no simulated successful call | Existing provider limitation retained | BLOCKED |
| Android/UI acceptance | Physical device | adb devices; native interactions | Authorized physical device | ANDROID DEVICE = BLOCKED ? NO AUTHORIZED DEVICE | android-devices.txt | BLOCKED |
| Doctor regression/analyze/build | Existing Doctor suite | Requested unchanged commands | 23 pass; clean analysis; debug APK | 23 passed, 0 skipped, 0 failed; analysis clean; APK built | doctor-tests.log; doctor-analyze.log; doctor-build.log; exits.json | PASS |
| Patient regression/analyze/build | Existing Patient suite | Requested unchanged commands, all existing live flags | 89 pass; clean analysis; debug APK | 89 passed, 0 skipped, 0 failed; analysis clean; APK built | patient-tests.log; patient-analyze.log; patient-build.log; exits.json | PASS |

Regression: **239 passed, 0 skipped, 0 failed**. Unchanged live headless acceptance: Doctor **2 passed**, Patient **1 passed, 1 failed**. Combined executed tests: **242 passed, 1 failed, 0 skipped**. These are fresh results; earlier failures remain recorded above. UI failure is a confirmed acceptance-harness failure, not yet a proven application defect. Static inspection shows Review reservation is enabled only when a slot is selected, but the unchanged run does not expose enough state to identify why the review screen was not reached. No speculative fix, test edit or repeated OTP attempts were made.

Doctor APK compilation completed (Gradle 183.0s); Patient completed (140.0s). The machine reported roughly 193 MB free physical memory during slow execution. No command was relabelled as passed before completion. Source/test comparison remains unchanged.

No Flutter appointment was created and no appointment was inserted through SQL, Prisma, fixtures or direct API as a substitute. Existing regression fixtures remain separate from acceptance. No new product development was started.

**FINAL LIVE RETRY DECISION: MIGRATION INCOMPLETE.** OTP is now resolved. Remaining internal gaps are the failed Flutter booking transition and dependent same-appointment Doctor/notes/summary/follow-up journeys, plus native persistence/device acceptance.

### Late emulator discovery — scope correction

A late adb check found emulator-5554 authorized. No physical Android device was
connected. Both current APK installations returned Success, and the Doctor app
launch command succeeded. The emulator first showed the launcher screen and later
an OTP form with partially entered text, despite this agent issuing no phone/text
input. Control ownership was therefore requested before further interaction.
Native login, identity, restart and booking are not claimed from another operator's
unattributed actions. The OTP-bearing screenshot was moved into ignored private
runtime storage and is excluded from reviewable evidence.

This supersedes the earlier statement that no emulator was available; physical
acceptance remains BLOCKED. Emulator installation/Doctor launch = PASS; controlled
native authentication and journey validation remain BLOCKED pending control.

### Native emulator follow-through — supersedes earlier booking blocker

The user explicitly authorized emulator control. Both APKs installed successfully.
Doctor A's OTP was requested and submitted in the native Flutter UI. The expected
Doctor A profile appeared. After force-stop and launch, Doctor Home restored its
session and loaded the existing agenda (native-doctor-restart.txt): native session
restoration PASS on emulator. Physical-device validation is still BLOCKED.

A native biography edit was attempted, but reload still showed the prior biography.
This is not accepted as a successful changed-value persistence test; the interaction
was not proven to have saved the new value. Headless save/remount evidence remains
separate. One Android UI dump returned a null root; its stale follow-up file
native-patient-return.txt is INVALID evidence and must not be used. The capture
utility now rejects unavailable UI trees instead of treating old XML as current.
This is an observation utility change, not an application or test-suite change.

Patient A then completed native mobile-number ? development OTP ? Patient Home.
Search found Doctor A and loaded real backend slots. The 09:00 IST September 10 slot
was selected, the native Review reservation button was enabled, and the Review your
reservation screen loaded. Pressing Reserve this time displayed Demo reservation
booked and confirmed. This proves the native review/booking journey despite the
unchanged headless harness failure; that failure remains recorded, not erased.

Read-only database verification after the UI confirmation captured:
- Appointment: 806a5c75-f39c-46d2-a94b-ca188e66dc20
- Patient: 81000000-0000-4000-8000-000000000003
- Doctor: 82000000-0000-4000-8000-000000000001
- Starts: 2026-09-10T03:30:00Z (09:00 IST)
- Ends: 2026-09-10T03:40:00Z (09:10 IST)
- State: CONFIRMED

Origin is exclusively the native Patient Flutter booking button. SQL was SELECT
only for post-booking evidence; no direct API/SQL/fixture booking was substituted.
Evidence: native-booking-review.txt, native-booking-submit.txt,
native-booking-record.json, native-patient-home.txt, native-doctor-profile.txt,
native-slots.txt under artifacts/live-retry.

The appointment is in the future. No IN_PROGRESS/COMPLETED state or note creation
has been forced outside backend rules. Those downstream journeys remain unverified.
Opening Doctor's upcoming agenda encountered an automatic permission-review timeout;
the allowed one retry is pending. Do not infer an unsafe action from the timeout.

### Latest native outcome — authoritative retry summary

The approval retry succeeded. Doctor A's Upcoming agenda and detail screen showed
the Patient Flutter reservation for September 10 at 09:00 IST, CONFIRMED. These
UI fields match the unique new database row 806a5c75-f39c-46d2-a94b-ca188e66dc20.
The screen does not render the raw UUID: identity matching is the unique
actor/time/state correlation plus read-only database evidence, not a claimed visible
UUID. Evidence: native-doctor-upcoming.txt, native-doctor-appointment.txt,
native-booking-record.json and native-final-state.json.

Doctor's existing start button returned 'This action is not available now. Refresh
and try again.' State remains CONFIRMED. Notes remained restricted to during/after
consultation, and the detail screen explicitly reported pending video integration.
No time, state, ownership or provider boundary was bypassed. Therefore authorized
appointment detail/provider-boundary display PASS; successful IN_PROGRESS ? COMPLETED,
private-note creation/read-isolation, shared summary and follow-up remain BLOCKED
for this future appointment. LIVE VIDEO = BLOCKED — PROVIDER REQUIRED.

The native biography interaction was retried without changing app or tests. The
field accepted a changed synthetic value, Save produced 'Profile saved.', and that
exact value remained after force-stop/relaunch and reopening Profile. The earlier
unsuccessful input attempts remain documented, but changed-biography persistence
is now PASS on emulator. Evidence: native-profile-value-final.txt,
native-profile-saved.txt, native-profile-persisted.txt. Native session restoration
also PASS (native-restart-after-save.txt). Credentials remained read-only.

Native logout/revocation is NOT proven. The logout command's subsequent capture
unexpectedly showed the Patient app, not Doctor sign-in, and a read-only query found
four Doctor A session records. This cannot establish which sessions were revoked.
The final unauthenticated Doctor appointments request returned 401, which only
proves unauthenticated denial. Existing regression logout/revocation tests passed
separately; do not relabel them as this native-session logout result.

| TEST | ACTOR | ACTION | EXPECTED | ACTUAL | EVIDENCE | STATUS |
|---|---|---|---|---|---|---|
| Native Patient booking | Patient A | Slots ? review ? reserve | Confirmed real backend record | Confirmed booking, matching unique database row | native-booking-submit.txt; native-booking-record.json | PASS |
| Doctor receives booking | Doctor A | Upcoming ? detail | Matching patient/time/state | Patient A, Sep 10 09:00 IST, CONFIRMED; UUID correlated via unique DB row | native-doctor-upcoming.txt; native-doctor-appointment.txt | PASS |
| Consultation timing boundary | Doctor A | Existing start action | Backend enforces permitted window | Action rejected; state remains CONFIRMED | native-start-boundary.txt; native-final-state.json | PASS |
| Successful full lifecycle | Doctor A | In-progress then complete | Valid supported transitions | Future appointment cannot yet start | native-start-boundary.txt | BLOCKED |
| Changed profile/native restart | Doctor A | Save changed bio ? restart ? reload | Same saved value | Save success and exact changed value reloaded | native-profile-saved.txt; native-profile-persisted.txt | PASS |
| Native session restoration | Doctor A | Force-stop ? launch | Authenticated Doctor Home | Doctor A Home and agenda restored | native-restart-after-save.txt | PASS |
| Native logout/revocation | Doctor A | Logout ? protected request | Doctor sign-in and revoked exact token | Patient app appeared; remaining sessions cannot identify revocation | native-doctor-logout.txt; native-final-state.json | BLOCKED |
| Availability modification/persistence | Doctor A; Patient A | Change windows ? restart ? slots | Persisted change reflected | Headless save passed; this full native sequence not completed | doctor-ui.log | BLOCKED |
| Private notes/summary/follow-up | Doctor A/B; Patient A/B | Create during permitted consultation then isolation checks | Correct persistence/visibility | Future consultation cannot start; no note created | native-doctor-appointment.txt | BLOCKED |
| Same-appointment cross-account checks | Provisioned actors | Read/write ownership against new appointment/note | Server denial | Existing regression passed, but new-appointment denial sequence not executed | backend-tests.log | BLOCKED |
| Native emulator launch/login | Patient A; Doctor A | Installed apps and real OTP login | Correct workspaces | Both native workspaces observed | native-patient-home.txt; native-doctor-restart.txt | PASS |
| Physical Android acceptance | Physical device | Native journeys | Authorized phone | Only emulator available | android-devices.txt | BLOCKED |

No application/business/backend/authorization/test-suite/harness changes were made.
Only evidence documentation and the redacted native observation utility were added.
239 existing regression tests passed. Unchanged headless live harnesses: 3 passed,
1 failed. Native manual observations are additional case evidence, not extra counted
automated tests. The headless review-screen timeout is still FAIL even though native
review and booking passed. Both requested APK builds and analyses completed.

**FINAL DECISION: MIGRATION INCOMPLETE.** The native Patient ? Doctor booking and
native profile/session restoration gaps are substantially closed, but the remaining
internal workflows and security acceptance must not be declared complete.
