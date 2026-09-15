# Phase 8: Doctor mobile acceptance

## Scope and implementation plan

Audit the independent Doctor app and reuse its existing screens/repositories; fix
concrete mobile behavior; exercise real local API authentication and session controls;
run regressions/builds and Prisma checks; separate automated/API/device evidence.
No Patient or backend business source changes are part of this phase.

DOCUMENT UPLOAD = DEFERRED
LIVE CONSULTATION PROVIDER = NOT CONFIGURED
PRODUCTION SMS = EXTERNAL DEPENDENCY

The existing development document-deferral flag remains enabled only in the isolated
test runtime. No storage provider was configured. Production rejects the flag. Admin
approval is still authoritative; documents do not block verified Doctor Home.

## Audit and change

Home reads profileProvider and appointmentsProvider. Agenda filters Today/Upcoming/
Completed/All use backend data and timezone, explicitly limited to the latest 100.
No fabricated global appointment totals were added. Existing loading, empty, error,
retry and refresh handling remain. Appointments are part of Home rather than duplicated
in another tab. Profile and Availability remain direct bottom-navigation destinations.

Found and fixed Android Back behavior: Profile/Availability now return to Home;
appointment details close before root navigation exits. Added a widget regression for
both secondary tabs and appointment back behavior. All existing navigation and screens
remain. No new provider calls, state-management architecture or backend APIs added.

Profile edits only biography/languages; credentials stay governed by the backend.
Availability retains windows, excluded dates, duration, buffer, timezone and booking
preference. Backend remains authoritative for slots. Consultation opens only an ID
from the authorized agenda; private notes, shared summary and follow-up retain existing
APIs and visibility. Provider-required messaging is explicit; no live call was faked.

SessionGate restores/revalidates the server session and obscures content while inactive.
Only READY grants the workspace. Registration status governs draft/pending/rejection;
suspension remains blocked. Logout clears private client state. Native restart and
background lifecycle behavior require actual device acceptance, not just widget tests.

## Real local API evidence

Using the existing synthetic development-approved Doctor account, fresh OTP request
and verification returned 200; Doctor session returned READY. Profile, availability
and appointments returned 200. Doctor access to Admin returned 403. Logout returned
200 and the same token subsequently received 401 on the appointments endpoint.
Evidence: artifacts/phase-8-doctor/live-api.json. No OTP values or tokens recorded.
Measured local endpoint durations were 10-125 ms; this is not a device benchmark.

No real Flutter booking/consultation/notes/follow-up mutation is claimed this phase.
Those contracts are covered by existing database/API and Flutter regression tests.
No arbitrary patient records were loaded or direct acceptance appointments inserted.

## Acceptance scope

| Feature | Evidence available | Remaining live/device acceptance |
| --- | --- | --- |
| Login/OTP/verified Home gate | Real local OTP, READY and Home APIs; Flutter tests | Native login/Home rendering BLOCKED |
| Registration/pending/Admin approval | Previous real deferred API lifecycle; current regression | Native new registration BLOCKED |
| Navigation/Android Back | New widget test and existing navigation | Physical interaction BLOCKED |
| Appointments | Real authorized listing; lifecycle regression | Full Flutter booking-to-completion BLOCKED |
| Availability | Real retrieval; save/slot generation regression | Native edit/restart and Patient slot UI BLOCKED |
| Profile | Real retrieval; save/reload regression | Native logout/login persistence BLOCKED |
| Patient context/notes/summary/follow-up | Existing ownership and consultation regression | Complete real Flutter journey BLOCKED |
| Consultation | Existing provider-boundary UI/actions | Live audio/video BLOCKED |
| Session restoration | Existing restoration tests | Native restart BLOCKED |
| Logout/security | Real revoked token 401, Admin 403; regression | Device visual clearing BLOCKED |
| Layout/keyboard/performance | Existing small-screen/error tests, local API timings | Device UX/performance BLOCKED |

ADB reported no attached device. No installation, physical-device approval or native
Home visibility is claimed. Production SMS, video, production document policy/storage,
signing, iOS and deployment remain external dependencies. Document deferral is not
an authorization bypass or a production credential policy.

## Regression/build/database results

Current evidence directory: artifacts/phase-8-doctor. Final command results follow.
No tests or skip conditions were removed or weakened. No database reset or migration
is performed; regression suites retain their existing synthetic fixture operations.

## Final results

Doctor 38 passed (one added Back-navigation test); Patient 89 passed; backend 146
passed; Admin 16 passed. Total 289, zero skipped/failed. Both Flutter analyses,
both independent debug APK builds, backend typecheck/build and Admin production build
passed. Prisma is valid, 15 migrations current, no drift; database inspection found
zero orphan appointments/notes. No database reset or business source change occurred.
Git status for authoritative Patient lib/test is clean.

Automated layout/navigation checks passed. Real HTTP login/READY/data/logout checks
passed. Full native acceptance remains BLOCKED: no Android device was attached.
No device restart, interactive notes/follow-up, cross-app booking or live video success
is claimed. Existing regression coverage does not substitute for those live journeys.

Created this report and phase evidence. Modified lib/app.dart, the corresponding
migration_widget_test.dart regression and docs/doctor-mobile-migration.md only.
Document upload remains DEFERRED in development. Production SMS is an external
dependency; live consultation provider is NOT CONFIGURED. No new logo, provider,
backend authorization, Patient UI or unrelated product feature was added.

FINAL STATUS: BLOCKED for full mobile acceptance; implementation fix and automated/API
validation passed. Next acceptance requires an available device and real Flutter journeys.
