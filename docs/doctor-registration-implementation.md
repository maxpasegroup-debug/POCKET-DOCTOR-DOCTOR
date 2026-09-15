# Doctor registration implementation

## Audit and implementation plan (before code changes)

Authoritative platform: ../pocket doctor; execution checkout: .validation/platform.
Doctor Flutter: workspace root. Patient: apps/mobile; Admin: apps/admin-console;
backend/Prisma: services/api. No AGENTS.md was found in these project roots.

1. Extend the existing OTP challenge with a server-owned purpose. Registration
   requests share existing cooldown/hash/expiry/attempt limits. Only a verified
   registration challenge may create a new DOCTOR role. Existing USER-only accounts
   cannot use it to self-promote. Existing login remains unchanged.
2. Reuse Doctor and existing PENDING_VERIFICATION/VERIFIED/REJECTED/SUSPENDED/INACTIVE.
   Add nullable draft/review timestamps, basic application fields and rejection reason,
   plus a private credential metadata relation. No duplicate Doctor or identity system.
   DRAFT/OTP_VERIFIED map to an unsubmitted OTP-authenticated Doctor record;
   SUBMITTED/UNDER_REVIEW derive from timestamps; existing verification enum is retained.
3. Add ownership-scoped draft/status/save/submit and private-document contracts.
   No private storage implementation or required-document policy exists. Provide a
   disabled-by-default private storage interface, size/type/signature checks and
   opaque identifiers. Do not accept public credential URLs. Fail closed for missing
   storage/policy; no mandatory legal-document claim is invented.
4. Extend existing Admin Doctor Management with application review, rejection reason,
   resubmission, private document retrieval and guarded approval. Preserve legacy
   Doctor editing, but prevent its generic status PATCH bypassing registration gates.
5. Add typed Riverpod registration models/repository/controller and mobile steps,
   review/status/correction screens. Existing operational workspace remains unchanged.
6. Add meaningful API/database security and Flutter state/widget tests, preserving
   existing suites. Apply one additive migration to the confirmed test DB without
   reset; validate schema/drift and preservation. Run Doctor/Patient/Admin/backend
   checks and APK builds. Sync only reviewed backend/Admin changes to authoritative
   platform; publish an exact file manifest and evidence-based limitations.

Storage integration and document policy are explicit configuration dependencies.
No document upload or approval is claimed working until that boundary is satisfied.

## Implemented architecture and flow

The Doctor UI lives only in the independent Pocket Doctor Doctor Flutter project.
Patient entry points, navigation, authentication, source and application identity
are unchanged. Backend/Admin changes are in the existing ../pocket doctor platform;
.validation/platform is the local execution copy, not a second backend architecture.

Existing doctor login remains the default. Register as Doctor selects a registration
purpose for the same OTP infrastructure. A new phone must pass the random six-digit
OTP before a server-created DOCTOR role and pending Doctor draft exist. Existing
USER-only accounts are denied registration; a role in a request body is rejected.
This deliberately does not offer conversion of an existing Patient account.

Mobile steps: Basic information -> Professional information -> Documents -> Review.
Save draft and Save and continue persist to PostgreSQL. Name, email, professional
registration details, languages, biography and consultation fee are required on
submission. Date of birth and gender are optional; profile photo is a private
optional document. Only the existing reservation consultation type is represented.
No legally mandatory document list was invented.

| Backend state | Registration state | Access |
| --- | --- | --- |
| PENDING_VERIFICATION, started, no submission | DRAFT (mobile OTP already verified) | Own draft only |
| PENDING_VERIFICATION, submitted | SUBMITTED | Read-only pending application |
| PENDING_VERIFICATION, review started | UNDER_REVIEW | Read-only pending application |
| VERIFIED | VERIFIED; session READY | Existing Doctor workspace |
| REJECTED | REJECTED | Server rejection reason, corrections and resubmission |
| SUSPENDED / INACTIVE | Same | Blocked operational access |

Existing legacy doctors without registrationStartedAt retain their original session
and Admin behavior. New application approval never comes from Flutter. Admin review
uses existing ADMIN authentication, step-up policy and audit events. The legacy
Admin doctor PATCH cannot change a new application's verification status, preventing
it from bypassing submission/review gates. Pending applications can be filtered in
the existing Doctor management list.

## API contracts

All paths below use the existing /api/v1 prefix.

| Method/path | Authorization and purpose |
| --- | --- |
| POST /doctor/registration/otp/request | Existing OTP limits, server-owned registration purpose |
| POST /doctor/registration/otp/verify | Valid matching challenge creates pending DOCTOR; no auto-approval |
| GET /doctor/registration | DOCTOR; own application |
| PATCH /doctor/registration | DOCTOR; own DRAFT/REJECTED; strict fields |
| POST /doctor/registration/submit | Own complete draft, required private documents, configured policy |
| POST /doctor/registration/documents | Own editable draft; size/type/signature checks and request limits |
| GET/DELETE /doctor/registration/documents/:documentId | Owner; state restrictions; no public URL |
| GET /admin/operations/doctors/:id/registration | Existing authorized Admin review |
| POST /admin/operations/doctors/:id/registration/review | BEGIN_REVIEW, APPROVE, REJECT or SUSPEND; valid states and audit |
| GET /admin/operations/doctors/:id/registration/documents/:documentId | Authorized Admin private download |
| GET /doctor/session | Additive registration status/required field; existing READY behavior retained |

Draft saves, submission and review serialize on the Doctor row. Upload association
rechecks editability after storing the object, preventing submission races. DTOs do
not expose storage keys or document bytes through ordinary profile/application lists.
Existing patient doctor DTOs continue to select public fields explicitly.

## Private document boundary and remaining configuration

BLOCKED: no approved private-storage implementation is configured. The contract is
PrivateCredentialStore (put/read/remove/available), injected into buildApp alongside
an approved requiredKinds policy. The actual server supplies neither by default.
The future adapter must enforce private ACLs, encryption at rest, malware scanning,
authenticated retrieval and deletion/retention handling. It must never expose public
credential URLs. No Cloudinary/public upload workaround was introduced.

The safe interface accepts PDF/JPEG/PNG, checks signatures/base64 and a 5 MB limit,
restricts profile photos to images, validates filenames, limits document count and
uses random opaque object keys. Flutter shows operation progress, validation/network
errors and retry by reselecting a document. It uses the official file_selector
package, not a public URL input. Admin downloads through an authenticated endpoint
into a temporary browser Blob URL, which is revoked.

BLOCKED: an approved required-document policy has not been supplied. Qualification,
registration, identity and additional documents are supported categories, not a claim
that all are required by law. Missing storage/policy prevents submission and approval
with a clear error; drafts remain usable. Profile photos remain private credentials;
a public profile-photo publishing pipeline is not implemented.

The storage contract's best-effort cleanup on a failed metadata write or deletion
must be backed by adapter-side orphan reconciliation before enabling live uploads.
No live credential storage, malware scanning or retention claim is made.

## Database and deployment

Additive migration: 20260909100000_doctor_registration. Existing Doctor records gain
nullable personal/application fields and timestamps. DoctorCredential stores private
metadata and a Doctor ownership foreign key. OtpChallenge gains a LOGIN-default
purpose with a constraint. Existing users, doctors and appointment models are reused.
No reset, drop or destructive data migration was performed.

The confirmed loopback development database pocket_doctor_test on port 55433 was
validated before mutation. Migration deploy, schema validate, migration status and
schema diff completed successfully: 15 migrations current, no schema drift. Fixture
Doctor A/B remain verified; their 14 availability windows remain. Orphan appointment
and note counts are zero. Overall users/doctors increased through existing regression
fixtures (76/15 before; 81/17 after), not a reset. New registration test identities are
synthetic and cleaned up by their suite.

Deploy through existing platform commands in services/api: install dependencies,
run Prisma migrate deploy with the confirmed environment, generate Prisma client,
typecheck/build and restart the existing API. Do not copy a test DATABASE_URL to
production. The local test API was restarted to exercise the updated shared source.

## Validation evidence and scope

Evidence directory: ../../Pocket Doctor Doctor/artifacts/registration (from platform)
or ../artifacts/registration from this document. Tests use existing suite conditions;
no prior test was removed or weakened.

- Backend: 138 passed, 0 skipped, 0 failed (previous 127; 11 new counted tests,
  including a parent integration test and its nine subtests plus file validation).
- Doctor: 32 passed, 0 skipped, 0 failed (previous 23 plus nine registration tests).
- Doctor analysis: no issues. Backend TypeScript: passed.
- Admin: 16 passed, 0 skipped, 0 failed; TypeScript/Vite build passed.
- Patient and Android build results are recorded below after completion.

Backend lifecycle tests execute real PostgreSQL operations and Fastify API
handlers. They inject a private storage test double and a REGISTRATION document
policy; those tests prove lifecycle/authorization contracts, not live storage.
Flutter widget tests use HTTP fixtures to verify navigation, forms and failure
states; they are not claimed as real-device or live Flutter acceptance.

Security evidence covers USER registration denial, purpose-bound OTP, shared rate
limits, race-time role checks, owner-only drafts and documents, Admin-only review,
locked submitted applications, rejection/resubmission, approval, suspension of an
existing session, and denial of legacy Admin PATCH bypass. Existing operational
verification checks remain authoritative on every request.

Initial Flutter test failures and sandbox-blocked Admin invocations are retained in
logs. Flutter test harness scrolling, missing dashboard profile fixture and timezone
initialization were corrected; final assertions all pass. Admin succeeded when its
child processes were allowed to execute. No failing existing test was skipped.

## Project separation evidence

artifacts/registration/platform-files.json lists exactly 14 synchronized backend/Admin
files. Each copy was hash-checked against the execution source. Patient files were
explicitly excluded. patient-git-status.txt is empty; patient-source-integrity.json
compares all 77 Patient Dart files after UTF-8/BOM/line-ending normalization and finds
zero content differences. Flutter projects, lib/main.dart entry points, app identities
and builds remain separate.


### Additional evidence during final checks

Patient analysis is clean and all 89 tests pass with all seven existing live smoke
flags enabled against the restarted shared backend. A concurrent backend rerun
reported 135 passed and 3 failed: existing auth query timeout and assistant transaction
start timeout (including its parent count). The failure log is retained as
backend-tests-concurrent-timeout.log. No timeout, test or skip condition was changed.
A final backend rerun is performed without overlapping Flutter regression/build work.

Credential validation now uses bounded base64 decoding and canonical comparison,
avoiding regular-expression recursion on large files. The file-validation test checks
both a valid 5 MB input and rejection above the limit, alongside malformed signatures,
invalid base64 and PDF rejection for profile photos.


### Acceptance case matrix

PASS below describes the stated automated evidence, not a live document provider.

| Test | Expected | Evidence | Status |
| --- | --- | --- | --- |
| New unknown phone -> registration OTP -> draft | DOCTOR, pending, no operational access | PostgreSQL integration + Flutter registration entry | PASS |
| Normal Patient -> registration or doctor-only APIs | 403; no role promotion | PostgreSQL API tests | PASS |
| Client role / foreign doctor selector | Rejected strict request body | PostgreSQL API tests | PASS |
| LOGIN challenge used for registration or converse | Rejected purpose mismatch | PostgreSQL API tests | PASS |
| Registration followed by ordinary OTP request within cooldown | Shared 429 limit | PostgreSQL API tests | PASS |
| USER appears between challenge and verification | No promotion | PostgreSQL race scenario | PASS |
| Save basic/professional draft | Persistent own fields | PostgreSQL + four-step Flutter test | PASS |
| Read another doctor's credentials | 404; Patient 403 | PostgreSQL API tests with private-store double | PASS |
| Owner/Admin credential access | Authorized bytes only | PostgreSQL API tests with private-store double | PASS |
| Submit -> pending | Editing locked; appointment API 403 | PostgreSQL + Flutter pending tests | PASS |
| Admin rejection -> correction -> resubmit | Reason visible, pending, access denied until approval | PostgreSQL lifecycle; Flutter correction state | PASS |
| Admin approval -> READY | Existing Doctor services accessible | PostgreSQL lifecycle; Flutter READY workspace test | PASS |
| Admin suspension with an existing token | Next operational request denied | PostgreSQL lifecycle | PASS |
| Generic Admin status PATCH bypass | 409 for registered applications | PostgreSQL integration | PASS |
| Missing storage | Upload/submit disabled or rejected; draft remains | PostgreSQL API + Flutter unavailable-state tests | PASS |
| Complete real credential upload/review lifecycle | Real private storage and approved policy | No adapter or policy configured | BLOCKED |
| Physical registration/device acceptance | Native form, file picker and lifecycle | No device registration acceptance performed in this phase | BLOCKED |

Read-only preservation evidence in preserved-records.json confirms all five original
synthetic identities, both legacy verified Doctor profiles, and original Flutter
booking 806a5c75-f39c-46d2-a94b-ca188e66dc20 still exist. No acceptance appointment was
created by the registration implementation.


### Final results

| Check | Result | Evidence |
| --- | --- | --- |
| Doctor analyze | PASS, no issues | doctor-analyze-final.log |
| Doctor tests | PASS, 32 passed / 0 skipped / 0 failed | doctor-tests-final.log |
| Doctor independent APK | PASS, debug compilation | doctor-build.log; doctor-exit.json |
| Patient analyze | PASS, no issues | patient-analyze.log |
| Patient tests | PASS, 89 passed / 0 skipped / 0 failed | patient-tests.log |
| Patient independent APK | PASS, debug compilation | patient-build.log; patient-exit.json |
| Backend final suite | PASS, 138 passed / 0 skipped / 0 failed | backend-tests-final.log; backend-exit-final.json |
| Backend TypeScript | PASS | backend-typecheck-final.log |
| Admin tests/build | PASS, 16 passed / 0 skipped / 0 failed | admin-tests-final.log; admin-build-final.log; admin-exit.json |
| Prisma/schema/migrations | PASS, 15 current, no drift | prisma-*-final.log |
| Project separation | PASS, distinct application IDs/APKs; no Patient source changes | final-integrity.json; patient-source-integrity.json; patient-git-status.txt |
| Secret scan | PASS for configured secret values, credential URLs and private-key markers | secret-scan.json |
| Live private credential upload and review | BLOCKED | No private storage adapter or approved policy |
| Production SMS | BLOCKED | Development OTP is the tested mode |
| Native registration/device acceptance | BLOCKED | Not performed in this phase |

Total final suites: 275 passed, 0 skipped, 0 failed. Prior concurrent timeout failure
is retained; final rerun passed without changing existing tests or timeout settings.
Doctor +9 and backend +11 counted tests explain increases from the prior baseline.
No pre-existing test was deleted or weakened.

Doctor APK: build/app/outputs/flutter-apk/app-debug.apk.
Patient APK: .validation/platform/apps/mobile/build/app/outputs/flutter-apk/app-debug.apk.
Application IDs remain com.pocketdoctor.pocket_doctor_doctor and
com.pocketdoctor.pocket_doctor. SHA-256 hashes and sizes are recorded in
final-integrity.json. Debug builds are not store signing or iOS validation.

FINAL STATUS: BLOCKED for a complete live registration lifecycle. Draft onboarding,
server lifecycle, Admin controls and private document contracts are implemented and
automatically tested. A real private storage adapter, approved required-document
policy and live acceptance through that boundary remain necessary. No production
readiness or completion of earlier migration E2E gaps is claimed.


## DOCTOR-REGISTRATION-02 storage follow-up

See [doctor-registration-storage.md](doctor-registration-storage.md) for the audit,
configuration, encrypted local-test adapter, atomic replacement, upload statuses and
actual environment limitations. Files: [doctor-registration-storage-files.md](doctor-registration-storage-files.md).

The existing private contract now has a disabled-by-default encrypted filesystem
adapter limited to local development/test, with protected permissions and mandatory
Defender scanning. The real harmless-file probe failed (exit 2 / 0x80004005), so the
running API remains storage-disabled. Required document and retention policy is still
BLOCKED - BUSINESS/POLICY APPROVAL REQUIRED. No live submission/approval claim is made.

Replacement reuses the upload endpoint and swaps the same owner's current credential
atomically after successful storage. Doctor Riverpod state now distinguishes upload
progress/success/failure and exposes replacement. Patient source remains unchanged.
No database migration was added; 15 current migrations and no drift remain confirmed.

New automated evidence: backend 144 passing tests (+6), Doctor 35 passing tests (+3).
Encrypted filesystem tests use a disclosed scanner double, not fake live acceptance.
All historical failures and earlier migration evidence remain in their original logs.

Storage follow-up final checks: Doctor 35, Patient 89, backend 144 and Admin 16 pass (284 total; zero skipped/failed). Both Flutter analyses and independent debug APK builds pass. Backend typecheck/build and Prisma validation pass. Scanner failure, missing approved policy and no attached Android device leave live registration BLOCKED. See doctor-registration-storage.md for exact logs and limitations.


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
