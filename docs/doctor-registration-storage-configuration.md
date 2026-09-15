# Doctor registration storage configuration contract

## Status and provider selection

Production storage configuration and live acceptance are BLOCKED. No approved private
provider exists. Cloudinary appears only as reserved deployment configuration. Do not
enable it from placeholders or supply secrets to Flutter. The encrypted local adapter
remains disabled and is not a production substitute.

STORAGE_PROVIDER is the logical contract name. The existing executable environment
selector is DOCTOR_CREDENTIAL_STORAGE; there is no separate STORAGE_PROVIDER variable.
Do not add an alias or assume an unsupported value activates a provider.

## Single server-side configuration contract

| Variable | Existing meaning |
| --- | --- |
| DOCTOR_CREDENTIAL_STORAGE | Existing selector: disabled (default) or local-test; no production adapter implemented |
| DOCTOR_CREDENTIAL_ROOT | Private absolute local-test directory; protected filesystem permissions required |
| DOCTOR_CREDENTIAL_KEY | Local-test encryption key; 32 bytes encoded in base64 |
| DOCTOR_CREDENTIAL_SCANNER | Existing Windows Defender executable for local-test scanning |
| DOCTOR_REQUIRED_CREDENTIALS | Approved required categories, comma-separated; no policy is supplied by this task |
| APP_ENV / NODE_ENV | Existing environment safeguards; local-test forbidden in deployed environments |
| CLOUDINARY_CLOUD_NAME | Reserved server-side provider name; not approval or activation |
| CLOUDINARY_API_KEY | Reserved server-side credential name |
| CLOUDINARY_API_SECRET | Reserved server-side secret name |

No actual secret values belong in this document, source control, Flutter defines,
client responses or logs. The reserved Cloudinary variables alone do not implement
private storage. Exact additional provider settings must be defined after approval.
Do not invent document requirements, retention periods or deletion policy.

## Interface, metadata and lifecycle

The existing PrivateCredentialStore provides available, put, read and remove.
Upload/download/delete map to those methods. Metadata and owner relationships reside
in DoctorCredential through the registration service, not in a second store model.
Replace is orchestrated by that service: store new bytes first; validate same owner
and kind under a Doctor row lock; transactionally replace metadata; clean up old bytes.
An upload failure preserves the existing current credential. Existing cleanup failures
can leave private orphaned objects; a production cleanup/retention procedure requires
approval and is not claimed complete. No new retention or deletion rules are imposed.

The available flag is configuration availability, not proof of remote health. The
new diagnostic reuses readEnvironment and configuredRegistration. It does not alter
runtime authorization, instantiate a second adapter or probe production services.

## Safe readiness command

From the Doctor project with the existing validation checkout installed:

    node .validation/platform/services/api/node_modules/tsx/dist/cli.mjs scripts/doctor-registration-readiness.mts --test-runtime

Omit --test-runtime to inspect process environment only. No arbitrary runtime path
is accepted. The command makes no database/provider connections or mutations. It
reports CONFIGURED, NOT_CONFIGURED or INVALID_CONFIGURATION without values.
Exit 1 means invalid/unreadable configuration; exit 0 does not mean live readiness.
A valid disabled setup reports storage NOT_CONFIGURED. A configured local-test
adapter would still report productionStorage NOT_CONFIGURED. Invalid overall backend
configuration conservatively marks subsystem configuration invalid, not unhealthy.

Fresh test-runtime output: environment development, database CONFIGURED, OTP CONFIGURED,
storage NOT_CONFIGURED, documentPolicy NOT_CONFIGURED. These are syntax/configuration
results, not connectivity, scanner, provider health or business-policy approval.

## Fail-closed access and submission

Existing strict upload validation rejects client-supplied ownership/verification/path
fields (rather than trusting or silently applying them). Allowed files: PDF/JPEG/PNG,
up to 5 MB, signature and base64 validated. PDFs cannot be profile photos.
The server derives Doctor ownership from authenticated identity. Other Doctors,
patients and unauthenticated callers cannot access credentials. Admin access uses
existing Admin authorization and the secure backend proxy, never public URLs.

Missing store produces PRIVATE_STORAGE_UNAVAILABLE (503) with a retry message.
Existing upload/retry UI must not mark a failed upload Uploaded. Admin retrieval also
fails without a store; no fake document is served. Application submission checks
fields, state, store and required documents. Submission remains pending; only Admin
verification enables operational Doctor access. Rejected/suspended access stays denied.
Flutter cannot promote the Doctor. Existing states and business rules are unchanged.

## Live acceptance procedure after external approval

1. Approve provider, isolated test resource, private access/scanning and document/retention policy.
2. Implement the approved adapter behind the existing interface and supply server environment secrets.
3. Run the diagnostic, then separately verify actual private upload/retrieval and provider failure.
4. Through Flutter, register synthetic Doctor A via existing OTP, upload, review and submit.
5. Verify pending operational denial; Admin securely views credential and approves; Doctor logs in to Home.
6. Repeat with Doctor B rejection, correction/replacement and resubmission without operational access.
7. Attempt cross-Doctor, Patient, unauthenticated and tampered-ID access; verify denial and no public delivery.
8. Validate restart/session/logout and suspension on a connected device; preserve evidence.

Until then live upload, Admin document review and full registration acceptance remain BLOCKED.

## Evidence

The first diagnostic test attempt hit sandbox spawn EPERM; the unchanged tests passed
with child-process permission. Four new diagnostic tests cover missing configuration,
unknown provider/redaction, incomplete local configuration and deployed local rejection.
Existing backend validation/security/registration tests remain unchanged. Current run
logs are in artifacts/registration-configuration. Final results are appended below.

## Final results for this configuration-contract task

Fresh regression: Doctor 35, Patient 89, backend 144, Admin 16 passed, all zero skipped
or failed. Four new readiness tests passed: total 288. Existing test counts are
unchanged; the additional four are standalone diagnostic tests, not new backend cases.
Both Flutter analyses and both debug APK builds passed. Backend typecheck/build,
Admin build and Prisma validation passed. Fifteen migrations are current, no drift.
No database reset or migration was performed. No Patient/product/schema source changed.

The first diagnostic run failed to spawn under the sandbox (EPERM). The unchanged
tests were rerun with child-process permission and passed; no skips were introduced.
Targeted secret scan of new scripts and modified reports passed. Existing source
privacy checks remain covered by backend regression. No Android device was attached.

Created scripts/doctor-registration-readiness.mts,
scripts/doctor-registration-readiness.test.mts and this document, plus evidence under
artifacts/registration-configuration. Appended production-storage, implementation and
migration reports. No new production provider or document policy was selected.

FINAL STATUS: BLOCKED for live storage/registration acceptance. Configuration contract
and diagnostic are implemented and tested; provider integration still requires approval,
server-side credentials, approved document/retention policy and real access testing.
