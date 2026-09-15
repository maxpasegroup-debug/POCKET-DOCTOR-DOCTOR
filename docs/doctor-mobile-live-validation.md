# Doctor mobile live validation — D-VALIDATION

Date: 2026-09-09. Decision: **MIGRATION INCOMPLETE**.
This is validation evidence, not a production-readiness certification.

## Previous status → work performed → current status

Previous closure: MIGRATION INCOMPLETE, 149 passed / 20 skipped / 0 failed;
live database, workflow, authorization and device acceptance blocked.
This run re-inspected configuration and historical reports, reran unchanged
suites, validated Prisma offline and checked migration/source preservation.
Current live acceptance remains blocked without a configured test database.
Device and final test outcomes are recorded below after execution.

## Environment and source inventory

- Doctor Flutter project: workspace root, `lib/`, `test/`, Android and iOS projects.
- Authoritative platform: sibling `../pocket doctor`, commit `435a68496d0fe69a3754fadfeddc276fe593884e`.
- Patient: platform `apps/mobile`; Admin: `apps/admin-console`; backend: `services/api`.
- Regression execution copy: `.validation/platform`, an existing ignored archive
  of that platform. It is not a separately designed backend or database.
- Prisma: `services/api/prisma/schema.prisma`, 14 existing SQL migrations and
  `services/api/prisma.config.ts` in the platform/copy.
- Source comparison: 186 tracked Dart/TypeScript/Prisma source/test files match
  after newline normalization; source Git status is clean. SQL migration hashes
  were compared separately. No product, test or business-logic source changes.
- Reviewed `doctor-web-to-flutter-migration-map.md`, `doctor-mobile-migration.md`,
  `doctor-mobile-device-validation.md`, platform Phase 3–7 validation reports,
  authentication/doctor-session and consultation routes/services, and Admin DTOs.
- Historical web source remains `58658d1:apps/doctor-portal`; no web UI restored.

Evidence directory: `artifacts/live-validation/`. Configuration evidence contains
presence flags and paths only, never connection strings, OTPs or session tokens.

## Test database and safety

**TEST DATABASE = BLOCKED.** No configured `DATABASE_URL`, `TEST_DATABASE_URL`,
`DIRECT_URL`, `POSTGRES_URL`, `PGHOST`, `PGDATABASE` or `PGSERVICE` was found in
process/user/machine environment. Inspected project/API environment locations
contain no actual runtime `.env` file; examples are not live configuration.
The broader file inventory found historical isolated PostgreSQL data directories
under the platform's ignored `artifacts/db-tooling`. Phase reports explicitly
record stopping their servers and removing temporary credentials. No PostgreSQL
process was detected. These leftovers were not treated as an authorized configured
connection, and no URL was reconstructed or invented.

`npm run db:validate` uses the existing Prisma config's unconfigured fallback for
schema validation only. This offline operation does not connect to a database.
The fallback is not a test database and was not used for any database command.
All 14 SQL migrations match source; this is file-integrity evidence, not proof of
applied migrations, drift, SQL execution, connectivity or database health.

No migration deployment/status/drift/connectivity command, reset, database start,
seed or destructive operation was run. Those checks require a configured database
whose test/development purpose is verified first. No production data was accessed.
Evidence: `database-environment.json`, `database-status.json`,
`environment-source-audit.json`, `migration-inventory.json`,
`migration-source-check.json`, `prisma-validate.log`.

## Test accounts and authentication

**TEST ACCOUNTS = BLOCKED.** Doctor A, Doctor B, Patient A, Patient B and Admin
were neither provisioned nor used in this run. No real person's identity was used.

The existing supported local mechanism is `OTP_MODE=development` with a random
`SESSION_SECRET`, restricted to development/test. It generates a random OTP via
the existing request/verify API; there is no fixed bypass code. This mechanism
was inspected, not exercised against a database. Production SMS is NOT TESTED.

All eight real authentication cases remain BLOCKED: valid Doctor login through
Doctor Home, invalid OTP, expired OTP, logout, restoration, expired session,
normal USER access denial and unauthorized-account denial. Existing local
contract/widget tests remain supporting evidence only.

## Functional and cross-app acceptance

| Required evidence | Implementation/source finding | This run's live result |
|---|---|---|
| Doctor Home | Backend appointments, Today/Upcoming/Completed/All filters, loading/empty/retry | BLOCKED: no real authenticated records |
| Profile | GET/PATCH profile; only biography/languages writable; credentials read-only | BLOCKED: persistence and reload |
| Verification | Server Doctor session resolves account and verification state | BLOCKED: real account enforcement |
| Availability | Windows, exclusions, duration, buffer, timezone and accepting preference | BLOCKED: save/reload and Patient slot discovery |
| Patient → Doctor | Patient discovery/detail/slots/book, then assigned Doctor appointments | BLOCKED: no shared real appointment created |
| Appointment states | PENDING_PAYMENT, CONFIRMED, IN_PROGRESS, COMPLETED, CANCELLED, NO_SHOW, EXPIRED | BLOCKED: live lifecycle; rescheduling is timestamp mutation, not a new enum |
| Consultation | Existing authorized demo start/complete/no-show and context | BLOCKED: persisted state/actions/completion |
| Provider | No real video/audio session fabricated | BLOCKED — LIVE CONSULTATION PROVIDER |
| Private notes | Distinct private editor; Doctor-only DTO field | BLOCKED: persisted visibility and cross-account requests |
| Shared summary | Patient DTO includes summary only after completion, omits private note | BLOCKED: real Patient response/reload |
| Follow-up | Date/shared note tied to ConsultationNote; disabled null/empty values | BLOCKED: persistence, relationship and patient visibility |

No production-looking records or mock endpoints were substituted for these cases.
Local tests retain their original fixtures; they are not relabelled live tests.

## Authorization and ownership acceptance

All database/API checks in this table are BLOCKED; none is a frontend-only PASS.

| Direct backend case | Required outcome |
|---|---|
| Doctor A reads assigned Patient A appointment/context | ALLOWED |
| Doctor A reads unrelated Patient B context | DENIED |
| Doctor B reads Doctor A's appointment/private context | DENIED |
| Patient A reads Doctor-private note | DENIED |
| Patient B reads Patient A appointment or note | DENIED |
| Normal USER calls Doctor API | DENIED |
| Doctor calls Admin-only API | DENIED |
| Doctor A targets Doctor B availability/profile | DENIED; authenticated owner remains authoritative |
| Missing/invalid/expired/revoked session calls protected API | DENIED |
| Logout then reuse revoked session | DENIED |

Static inspection: Doctor profile and availability routes accept no target doctor
ID and use the authenticated principal. Strict schemas reject unexpected fields;
service transaction locks recheck assignment. Appointment notes/actions scope the
lookup by both consultation ID and assigned doctor. Patient DTOs omit private
notes and expose shared note information only after COMPLETED. Existing Admin
appointment list/detail selects omit consultation notes. No new Admin note-access
policy was invented. Static findings do not establish actual HTTP denials.

Relevant unchanged database suites include `auth.integration.test.ts`,
`doctor-session.integration.test.ts`, `consultations.integration.test.ts`,
`provider-delivery.integration.test.ts` and `database.integration.test.ts`.
Their existing guards and fixtures were preserved, including ownership/payment
relationships. Skips require actual configured infrastructure to resolve.

## Release, iOS and branding

Android release compilation passed in preceding closure; its placeholder HTTPS
API URL does not prove connectivity. Store signing is unconfigured and the
previous signature check returned exit 1 (Missing META-INF/MANIFEST.MF).
**ANDROID STORE SIGNING = BLOCKED.** No signing identity was created.

**IOS VALIDATION = BLOCKED.** Windows is not macOS/Xcode/signing/device evidence.
**APPROVED BRAND ASSET = BLOCKED.** Existing brand README requires the approved
unmodified logo; text fallback and Flutter launcher scaffolding are not approval.
No logo or product UI was redesigned.

## Remaining acceptance gates

A verified dedicated test database/connection and supported test deployment,
provisioned synthetic accounts, all real authentication and cross-app workflows,
server-side privacy/ownership/session denial evidence, and authenticated Android
device acceptance remain required. Live providers, approved branding, store
signing and iOS must be tracked separately. Local passing suites cannot establish
production readiness or completion while internal acceptance is blocked.

## Executed suites and build evidence

| Check rerun in D-VALIDATION | Result | Evidence in artifacts/live-validation |
|---|---|---|
| Doctor flutter analyze | PASS, no issues | doctor-analyze.log; doctor-exits.json |
| Doctor flutter test | 23 passed, 0 skipped, 0 failed | doctor-tests.log |
| Complete existing Patient flutter test suite | 82 passed, 7 skipped, 0 failed | patient-tests.log; patient-exit.txt |
| Complete existing backend npm test | 28 passed, 13 skipped, 0 failed | backend-tests.log |
| Backend typecheck | PASS | backend-typecheck.log; platform-exits.json |
| Prisma schema validation | PASS, offline only | prisma-validate.log; platform-exits.json |
| Admin npm test | 16 passed, 0 skipped, 0 failed | admin-tests.log |
| Admin production build | PASS | admin-build.log; platform-exits.json |

Total: **149 passed, 20 skipped, 0 failed (169 tests)**. The complete commands
ran, but the infrastructure-dependent cases did not. No test was deleted,
weakened or newly skipped. Patient auth/discovery/slots/booking/consultation,
programs/commerce/AI/membership local coverage passed; live smoke acceptance did
not run. Admin local management/verification/role/form contracts passed; no live
management or payment mutation was performed.

Prisma prints its config-loaded notice on stderr, which PowerShell formats as
NativeCommandError in the redirected log; Prisma returned exit 0 and explicitly
reported a valid schema. This is not a hidden validation failure.

Android debug/release compilation evidence remains from preceding migration and
closure; this phase did not rerun unchanged APK compilation. Installation uses
the actual existing debug APK. No iOS/web build is claimed. This is a dedicated
mobile project and does not require a Flutter web build.

## Android device evidence

A physical I2403 Android 16 / API 36 device became available in this phase.
`adb install -r` returned **Success**, exit 0; `am start -W` returned **Status: ok**
for `com.pocketdoctor.pocket_doctor_doctor/.MainActivity`. This resolves the earlier
installation failure for this physical device, not the old emulator failure.

The existing Pixel_6 AVD was briefly cold-started read-only with no data wipe or
snapshot save, then stopped when the physical device was discovered. No new AVD
was created. The physical device was left with the installed Doctor debug app.
Evidence: `device-install.log`, `device-install-exit.txt`, `device-launch.log`.

Initial UI inspection found only Android system UI because the phone was locked.
The lock-screen hierarchy was removed from local evidence; no credentials or
personal UI content are included in this report. Unlock was requested. Successful
activity launch alone is not proof that the login form was visible or interactive.
Authenticated login/OTP/Home/navigation/appointments/availability/consultation/
notes/logout still require the configured test backend. The existing debug APK
uses emulator host `10.0.2.2:3000`; it is not configured for a physical-device test
backend. No backend address was fabricated and no real phone number was entered.

Device acceptance is **PARTIAL**: installation and activity launch pass;
visible UI and all authenticated workflow checks remain blocked unless supported
by a subsequent evidence entry. Store readiness is not claimed.

Final device observation: the physical device disconnected before the requested
unlock/recheck. A subsequent adb request returned device not found. Therefore no
visible login-form, keyboard, scrolling or navigation acceptance is claimed.
The temporary hierarchy path on the device could not be cleaned after disconnect;
its local lock-screen copy was removed. No OTP/session was entered or captured.
