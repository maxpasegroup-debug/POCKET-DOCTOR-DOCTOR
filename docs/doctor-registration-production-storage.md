# Doctor registration: approved production storage follow-up

## Outcome

BLOCKED. The provider/configuration recheck found no approved private credential
provider. Cloudinary is reserved in deployment documentation, not approved or enabled.
No application, Patient, API, authorization, schema or test code changed in this follow-up.
The existing provider-neutral PrivateCredentialStore is retained. The local encrypted
adapter remains disabled; it is not production storage.

## Configuration required

Provider approval is required before selecting/implementing its adapter. Existing
reserved variable names are CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY and
CLOUDINARY_API_SECRET. Values belong only in the backend environment/secret manager.
These variables alone do not implement private delivery or the missing production adapter.
No Cloudinary provider has been selected by this follow-up.

Existing local-test names are DOCTOR_CREDENTIAL_STORAGE, DOCTOR_CREDENTIAL_ROOT,
DOCTOR_CREDENTIAL_KEY, DOCTOR_CREDENTIAL_SCANNER and DOCTOR_REQUIRED_CREDENTIALS.
They were not enabled/configured. Process and private runtime presence checks found
none of these storage/provider settings. No secret values were printed.

Required external decisions: approved provider and isolated test resource; private
access and scanning configuration; approved required document categories, retention,
replacement history and deletion policy. DOCUMENT POLICY = BLOCKED.

## Existing private design and authorization

The existing store exposes available/put/read/remove. Upload uses authenticated
Doctor ownership and editable registration state. Strict request validation rejects
client owner, path, role and provider identifiers. Supported files are PDF, JPEG and
PNG, up to 5 MB, with base64 and signature validation; PDF is not a profile photo.
Storage keys are server controlled. PostgreSQL keeps credential metadata, not provider
secrets or credential file bodies. Existing owner/Admin retrieval is authenticated
and proxied; no public provider URL is introduced. Admin retains existing review,
authorization and verification controls.

## Upload, replacement and deletion

The existing Riverpod/UI supports upload status, failure/retry, replacement and removal.
Uploaded never means verified. Replacement stores new content before a same-owner,
same-kind metadata transaction under the Doctor lock; a failed new upload must not
remove the current document. Existing cleanup/removal behavior is preserved, not
redefined as an approved production retention policy. Production retention/deletion
acceptance remains BLOCKED pending policy approval.

Submission checks fields, authenticated ownership, application state, storage and
required document policy. Pending/rejected/suspended doctors remain barred from
operational endpoints. Only authorized Admin approval grants verified access.

## Evidence and scope

The immediately preceding unchanged-implementation run is recorded in
artifacts/registration-live-storage and doctor-registration-live-storage.md:

| Check | Result | Status |
| --- | --- | --- |
| Doctor analysis/tests/debug APK | Clean; 35 passed; build exit 0 | PASS |
| Patient analysis/tests/debug APK | Clean; 89 passed; build exit 0 | PASS |
| Backend complete suite/typecheck/build | 144 passed; commands exit 0 | PASS |
| Admin tests/build | 16 passed; build exit 0 | PASS |
| Total automated | 284 passed, zero skipped/failed | PASS |
| Prisma | Valid; 15 current migrations; no drift | PASS |
| Source/secret checks | No Patient changes; targeted scan passed | PASS |
| Live upload/submission/Admin credential approval | No approved configured provider/policy | BLOCKED |
| Live rejection/replacement/resubmission | Same provider/policy boundary | BLOCKED |
| Device and native session restoration | Fresh adb devices: no device attached | BLOCKED |

Tests/builds above are retained evidence, not a newly repeated run. No implementation
changes justify repeating successful checks. API storage tests use a disclosed storage
double and local encrypted store tests use a scanner double; neither proves real
provider acceptance. Historical scanner failure remains recorded and was not bypassed.
No new live application, account provisioning or manual database mutation was performed.

## Files and next required input

Created this report; appended links to doctor-registration-implementation.md and
doctor-mobile-migration.md. All previous reports remain intact. Confirm the approved
provider and document policy, then configure an isolated provider resource through
server-side environment configuration before live upload/review testing can proceed.
No production readiness, legal verification, signing, iOS or device acceptance is claimed.


## Storage configuration contract and readiness diagnostic

See [doctor-registration-storage-configuration.md](doctor-registration-storage-configuration.md) for the single configuration contract and secret-free diagnostic. Existing backend validator and adapter factory are reused; no product/schema/Patient changes. Missing provider and document-policy approval still block live acceptance. Prior evidence is preserved.

Configuration-contract validation: fresh Doctor 35, Patient 89, backend 144, Admin 16 plus four readiness tests passed (288 total; zero skips/failures). Both Flutter analyses/debug APKs, backend typecheck/build, Admin build and Prisma checks passed. Live storage/registration remains BLOCKED. See doctor-registration-storage-configuration.md.
