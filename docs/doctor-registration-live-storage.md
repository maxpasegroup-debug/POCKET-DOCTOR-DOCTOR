# DOCTOR-REGISTRATION-03: provider audit and live acceptance

## Outcome and scope

STORAGE PROVIDER = NOT CONFIGURED.
Production/private provider acceptance = BLOCKED.
DOCUMENT POLICY = BLOCKED - DOCUMENT POLICY APPROVAL REQUIRED.

This phase audits and validates the existing implementation. No provider was chosen,
no runtime secret or policy was invented, and the encrypted local adapter remains
disabled. Doctor and Patient remain separate Flutter projects. No application,
backend, Admin, Patient, schema or existing test source was changed in this phase.

## Provider audit

Reviewed shared API configuration/startup, PrivateCredentialStore, credential
routes/service, DoctorCredential metadata, private Admin downloads, Patient source,
root environment template, and deployment/provider/security documentation.

The existing platform documents reserve CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY
and CLOUDINARY_API_SECRET. provider-configuration.md explicitly says no production
upload or signed-media adapter is enabled; production-config.md says setting these
placeholders alone enables nothing. They are evidence of a reserved integration,
not approval of an account, private credential processing or retention policy.

No configured Cloudinary account, approved private bucket, signed credential URL
service or production upload adapter was found. Process/test runtime audit records
only environment names/presence, never values. No storage-related configuration was
present. See artifacts/registration-live-storage/environment-audit.json.

## Missing external decisions and configuration

Before provider integration can proceed, supply:

- Confirmation of the approved provider (including whether the reserved Cloudinary
  integration is approved for private professional credentials).
- An isolated test provider account/resource and least-privilege server credentials,
  supplied through the backend environment or approved secret manager, not chat.
- Approved private delivery/access settings, authorized retrieval and expiry rules,
  encryption/key management and malware-scanning requirements.
- Approved required document categories, reviewer verification criteria, retention,
  historical replacement/audit requirements and deletion rules.

Existing reserved provider variable names only:
CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET.
No additional provider-specific variables are invented before a provider is approved.
Those three values alone do not implement the missing private production adapter.

Existing local-test configuration variable names only:
DOCTOR_CREDENTIAL_STORAGE, DOCTOR_CREDENTIAL_ROOT, DOCTOR_CREDENTIAL_KEY,
DOCTOR_CREDENTIAL_SCANNER, DOCTOR_REQUIRED_CREDENTIALS.
These describe the existing test adapter, not a production substitute. No values are
included or configured by this phase. The historical Defender probe failed with
exit 2 / HRESULT 0x80004005; it was not bypassed or represented as a current passing scan.

## Existing neutral architecture

PrivateCredentialStore already defines available, put, read and remove behind the
existing registration service. A provider-neutral interface is therefore already
implemented and was not duplicated. A future approved adapter must satisfy that
contract, including secure persistence, scanning and private access, before activation.

The local-test adapter uses encrypted files, server-generated opaque keys, protected
root permissions and mandatory scanning. It is rejected for deployed environments.
The test runtime does not activate it. It is not production/private-cloud acceptance.

## Upload, replacement and submission

Existing registration upload validates the bearer session, DOCTOR role, own editable
application, allowed category, MIME/signature/base64, size, safe filename, storage
result and document association. Client owner/role/path selectors are rejected.

Replacement reuses POST /doctor/registration/documents with replaceDocumentId. New
storage must succeed before the Doctor-row-locked transaction replaces same-owner,
same-kind current metadata. Existing removal behavior is preserved; no new retention
or historical audit rule is decided here. Production retention approval remains open.

Application submission independently validates fields, existing OTP-authenticated
Doctor ownership, registration state, configured policy and required stored documents.
Missing storage or policy fails closed. Submitted/under-review applications remain
PENDING_VERIFICATION in the existing enum and have no operational Doctor access.

Doctor Riverpod/UI distinguishes NOT UPLOADED, UPLOADING, UPLOADED and FAILED, with
retry and replacement. Uploaded does not imply verification. Server approval alone
permits the existing verified Doctor workspace.

## Private retrieval and Admin

Existing owner/Admin authenticated endpoints proxy credential bytes; no permanent
public URL or static document route is added. Global no-store response handling is
preserved. Ordinary application DTOs expose safe metadata, not storage keys or file
bytes. Admin uses its existing authorization, step-up policy, review UI and audit.
The generic Admin Doctor update cannot bypass registered-application approval gates.

There is no signed-URL implementation to validate yet. Signed URL expiry is NOT
APPLICABLE to the current authenticated proxy. Session expiry/revocation and ownership
are covered by existing backend tests; future provider signed access remains BLOCKED.

## Live versus automated evidence

| Journey | Evidence/scope | Status |
| --- | --- | --- |
| Private provider connection | No approved configured integration | BLOCKED |
| Provider upload/failure/expiry acceptance | No provider available; no simulated live success | BLOCKED |
| Flutter credential upload -> pending | Required provider and policy missing | BLOCKED |
| Admin real credential viewing/approval -> Doctor Home | No real submitted application through provider | BLOCKED |
| Live rejection/replacement/resubmission | Same missing boundary | BLOCKED |
| Native registration/OTP/session restart | No attached device at this attempt | BLOCKED |
| Existing storage validation/ownership/lifecycle | Automated API/PostgreSQL and filesystem tests; scope below | PASS |

Automated API registration tests use synthetic users and a disclosed storage double.
Encrypted filesystem tests write/read real encrypted files but use a scanner double.
Flutter tests use HTTP fixtures. These prove their stated contracts, not production
storage, live credential review or native E2E acceptance. No new live application ID
is reported because no genuine provider-backed submission was established.

The test backend readiness returned HTTP 200. adb-devices.log records no attached
Android device/emulator for this attempt. The earlier emulator login-screen launch
remains historical evidence only; it is not a live credential lifecycle result.

## Preservation and evidence

Source comparisons match authoritative backend, tests, Prisma, Admin and all 77
Patient Dart files against the execution checkout (generated Prisma client excluded).
No Patient source changed. No database reset, migration, direct acceptance appointment
insertion, role grant or manual application approval was performed by this phase.
Regression suites may create their existing synthetic fixtures normally.

Current evidence is under artifacts/registration-live-storage. Prior failures,
scanner results and earlier acceptance reports remain untouched.

## Final regression and build results (this phase)

| Check | Actual result | Status |
| --- | --- | --- |
| Doctor Flutter analysis / tests | Clean; 35 passed, zero skipped/failed | PASS |
| Patient Flutter analysis / tests | Clean; 89 passed, zero skipped/failed | PASS |
| Complete backend suite | 144 passed, zero skipped/failed | PASS |
| Admin suite | 16 passed, zero skipped/failed | PASS |
| Total | 284 passed, zero skipped/failed; unchanged baseline | PASS |
| Doctor debug APK | Command completed, exit 0 | PASS |
| Patient debug APK | Command completed, exit 0 | PASS |
| Backend typecheck/build | Both exit 0 | PASS |
| Admin build | Exit 0 | PASS |
| Prisma schema/migration/drift | Valid, 15 migrations current, no difference | PASS |
| Preservation spot checks | Five identities, two original doctors and original Flutter booking remain | PASS |
| Targeted secret scan | No configured secret values, private keys or credential URL findings | PASS |
| Provider-backed registration and native lifecycle | Missing approved provider/policy; no attached device | BLOCKED |

Commands and raw logs are recorded in artifacts/registration-live-storage. Flutter
builds used API_BASE_URL for the Android emulator test backend. The Patient smoke
suite enabled its existing API/auth/program/consultation/commerce/assistant/membership
flags; no skip conditions were changed. The backend suite used the existing isolated
test-environment helper. APK hashes and sizes are in apk-evidence.json. These APKs
are debug builds, not store-signing or physical-device acceptance.

No new tests were necessary because no implementation was changed. Existing tests
were neither removed nor weakened. Real provider failure, provider upload/retrieval,
Flutter submission/approval/rejection and native restart remain BLOCKED; automated
storage doubles do not change those statuses.

Files created: this report and phase evidence under artifacts/registration-live-storage.
Files modified: doctor-registration-storage.md, doctor-registration-implementation.md
and doctor-mobile-migration.md, by additive documentation only. Patient source and
all product/business/authentication/authorization code remain unchanged by this phase.

FINAL STATUS: BLOCKED. Provider approval, secure environment configuration and
approved document/retention policy are required before live credential acceptance.
