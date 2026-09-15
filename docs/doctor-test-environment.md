# Doctor test environment — D-ENVIRONMENT

Status: **TEST ENVIRONMENT READY**. This certifies local infrastructure and
synthetic account provisioning, not full mobile acceptance or production readiness.
Date: 2026-09-09.

## Discovery and correction to earlier findings

Doctor Flutter lives at this workspace root. The unchanged source platform is
`../pocket doctor` at commit `435a684`; Patient Flutter is `apps/mobile`, Admin is
`apps/admin-console`, and backend/Prisma are `services/api`. Executions use the
existing ignored `.validation/platform` archive, not a new backend implementation.

Earlier checks found no environment variables/runtime .env configuration and
reported database validation blocked. Deeper inspection found the existing
ignored `artifacts/db-tooling/phase7-runtime.json` in the source platform. This
corrects that finding: a historical configured test runtime still exists, despite
older reports describing credential cleanup. Its contents must never be printed.

Safety was established from the historical Phase 7 start utility and reports,
matching data-directory provenance, APP_ENV=development, OTP_MODE=development,
loopback host, dedicated test database name and actual connected server identity.
Initial database inspection found 17 historical users, one demo doctor and zero
non-demo doctors. These are historical synthetic validation records, not a newly
created empty database. No production connection or unknown credential was used.

## Database and configuration

Existing PostgreSQL 18 test database: `pocket_doctor_test`, loopback port 55433.
Existing cluster directory: source platform
`artifacts/db-tooling/phase7-data-1788851081677`. No new cluster/database architecture,
reset, drop or credential override was created. The cluster was stopped on initial
inspection; the complete existing embedded PostgreSQL distribution restarted it.
PostgreSQL recovered its interrupted previous shutdown and became ready.

The standalone `pg18-tools` copy failed because required libraries were missing.
The existing complete distribution under
`artifacts/db-tooling/node_modules/@embedded-postgres/windows-x64/native/bin`
worked. This required no application or migration changes.

Private configuration is copied to `.validation/environment/runtime.json`, already
covered by `.validation/` in .gitignore and protected by a Windows ACL granting the
current account access. It is under a OneDrive workspace: ignored/ACL-restricted
does not establish that it is excluded from cloud backup. Treat it as a secret
file; do not attach, commit or print it. Existing credentials were reused, not
invented. No OTP or authenticated session token is persisted by provisioning.
The existing backend runs at `http://127.0.0.1:3018/api/v1`, bound to loopback only.
External SMS, payments, push and consultation providers remain unvalidated.

## Prisma, schema and ownership

All checks returned exit 0:

- Prisma schema validation.
- Existing `migrate deploy`: 14 migrations found; no pending migrations.
- Migration status: up to date.
- Database-to-schema drift: no difference.
- Actual connection/server identity and public table/index/constraint inventory.

No migrations were modified or newly applied; the existing database was current.
`artifacts/environment/database-inspection.json` records catalog metadata without
patient content. `relationships.json` confirms two provisioned verified demo
doctors, 14 assigned working windows, zero orphan appointments and zero orphan
consultation notes. Existing foreign keys/constraints and the complete integration
suite verify relationships; follow-up remains fields on ConsultationNote linked
to its consultation, not a new model. No manual cross-app appointment was created
for the new identities in this environment phase.

## Synthetic identities

All five names start `DEMO D-ENVIRONMENT`. Phones below are local synthetic fixture
identifiers only; external SMS is disabled by the development configuration.
Do not use these identities against a production/provider deployment.

| Identity | User ID suffix (prefix 81000000-0000-4000-8000-) | Synthetic phone | Exact role |
|---|---|---|---|
| Doctor A | 000000000001 | +919999918001 | DOCTOR |
| Doctor B | 000000000002 | +919999918002 | DOCTOR |
| Patient A | 000000000003 | +919999918003 | USER |
| Patient B | 000000000004 | +919999918004 | USER |
| Admin | 000000000005 | +919999918005 | ADMIN |

Doctor IDs use prefix `82000000` with the corresponding suffix. Both profiles
are explicitly demo, VERIFIED, accepting appointments, synthetic qualifications
and specialty, English/Hindi, Asia/Kolkata, 30-minute consultations, 10-minute
buffer, zero test fee and seven 09:00–17:00 working windows. Neither represents a
real clinician or an approved professional credential. Patients have no Doctor
role. Admin is the existing ADMIN role for later provisioning/authorization
acceptance; no superuser application role was invented.

Provisioning uses the existing `consultations:seed` / Doctor integration fixture
pattern: direct synthetic User/role/Doctor/availability creation in an explicitly
guarded development database. VERIFIED demo records are supported by that seed
mechanism; production verification rules were not bypassed or changed. The utility
uses fixed fixture IDs, checks ID/phone/name/role collisions, and refuses to promote
an unrelated existing account. Reruns preserve existing matching fixtures.

## OTP and authentication evidence

**OTP TEST MODE = AVAILABLE.** The backend's existing random six-digit development
OTP is requested and verified via actual HTTP APIs. No fixed OTP, fake provider or
session bypass was introduced. Values remain in memory; all five sessions were
logged out after checks.

For all five identities: OTP request, verification, exact role resolution,
authenticated session retrieval and logout passed. Doctor A/B each returned READY
from `/doctor/session` and HTTP 200 from `/doctor/appointments`. Patient A/B and
Admin each received HTTP 403 at the Doctor session gate. Evidence is in
`artifacts/environment/accounts.json` and `provision.log` without OTP/token values.

This proves backend readiness for Doctor Home, not an observed Flutter Home.
Patient Home and Doctor Home screens, device session restoration and the manual
Patient → Doctor booking journey remain the next acceptance step. No production
SMS validation is claimed.

## Running the environment

Currently PostgreSQL and the existing backend are running locally. Do not start a
second API process on the same port. With the private runtime present:

```powershell
# Inspect a running test database; no mutation.
node scripts/doctor-test-environment.mjs inspect
# If the known test database is stopped:
node scripts/doctor-test-environment.mjs start-db
# Validate the existing schema/migrations safely:
node scripts/doctor-test-environment.mjs validate
node scripts/doctor-test-environment.mjs migrate
node scripts/doctor-test-environment.mjs status
node scripts/doctor-test-environment.mjs drift
# Start unchanged backend only if it is not already running:
node scripts/doctor-test-environment.mjs api
# Provision/recheck these synthetic identities through supported test OTP:
node scripts/doctor-test-environment.mjs provision
# Run unchanged complete backend suite with integration enabled:
node scripts/doctor-test-environment.mjs test
```

Scripts read credentials privately and supply subprocess environment variables.
They guard the exact test host, port, database, APP_ENV and data-directory path.
The provisioning entrypoint additionally requires development OTP and demo mode.
No actual database URL or session secret belongs in documentation or shell history.

For next physical Android acceptance, `adb reverse tcp:3018 tcp:3018` can expose
this loopback service only over the authorized USB connection; build/run the
client with explicit `API_BASE_URL=http://127.0.0.1:3018/api/v1` and opt-in development
OTP display if needed. This setup was documented, not performed here. The earlier
APK's emulator address is not a physical-device backend configuration.

## Stop and remove test data safely

Stop the backend process only after verifying the PID in
`.validation/environment/api.pid` still belongs to the backend launched here;
never kill an unrelated reused PID. Then stop only the guarded local cluster:
`node scripts/doctor-test-environment.mjs stop-db`.

Do not drop/reset this database: it contains retained historical test evidence.
For fixture removal, first verify the exact five IDs, synthetic names/phones and
two demo doctor IDs above, inspect their related records, and stop if ownership
or provenance differs. Remove only their test sessions/challenges and dependent
synthetic records in foreign-key-safe order within a transaction; leave historical
fixtures and audit policy intact. This task did not execute deletion or reset.
The provision utility is idempotent; a reset is unnecessary for normal reruns.

## Executed tests and limitations

- Doctor Flutter analyze: PASS, no issues.
- Doctor Flutter tests: 23 passed, 0 skipped, 0 failed.
- Complete existing backend suite with PostgreSQL: **127 passed, 0 skipped, 0 failed**.
- Current-phase total: **150 passed, 0 skipped, 0 failed**. Backend integration
  subtests expand the prior 41 top-level count; this is not test removal/recounting.
- Patient/Admin suites were not rerun in this environment-only phase; their latest
  earlier evidence remains 82 passed/7 skipped and 16 passed respectively.
- No test or skip condition changed. No application/business source changed.

Backend tests exercised existing ownership/privacy/session/payment relationships
with their own synthetic fixtures. That does not certify the new mobile clients'
full cross-app UI acceptance. No device/full booking journey, production provider,
store signing or iOS claim is made. Initial tooling failure (TypeScript interpreted
as CommonJS) was resolved by using an .mts utility; product source was untouched.

Evidence: `artifacts/environment/`; private runtime is not evidence to publish.
Next step is live Doctor/Patient Flutter acceptance against this established test
environment. Migration status remains incomplete until those gates have evidence.

## Final environment evidence

Catalog inspection recorded 54 public tables, 132 indexes and 518 constraints.
After all backend tests, idempotent provisioning and real OTP/session/role/logout
checks passed again for all five identities. No duplicate fixtures were created.
The source archive still matches 186 tracked application/test files; original
platform Git status remains clean. Secret scanning found zero configured-secret
values, credential-bearing PostgreSQL URLs or private-key patterns in the scanned
tooling, documentation and evidence. This is a targeted scan, not a formal audit.

Created: this document; scripts/doctor-test-environment.mjs,
scripts/doctor-test-provision.mts, scripts/doctor-test-secret-scan.mjs; ignored
private runtime and artifacts/environment evidence. Updated: migration report
and delivery file inventory. Application/business source changes: none.

Final status: **TEST ENVIRONMENT READY**.
