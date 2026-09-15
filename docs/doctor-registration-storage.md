# Doctor registration private storage

## Audit and plan (before implementation)

No approved Cloudinary, S3/object-store, signed URL service or private file adapter
was found in the shared backend, Admin or Patient source. Existing provider closure
and security documentation mark storage and retention as pending. Environment values
were not printed. Existing DoctorCredential metadata and PrivateCredentialStore are
reused; no Patient Flutter source changes are planned.

Implement a disabled-by-default local-test encrypted filesystem adapter behind that
contract, with authenticated backend retrieval and real OS malware scanning. Permit
it only in development/test. Store random opaque objects with AES-256-GCM; reject
unsafe keys and non-private roots. No public route or public URL. Missing scanner,
key or permissions fail closed. Keep document requirements configurable and unset
until approved; production requirements/retention remain BLOCKED - BUSINESS/POLICY
APPROVAL REQUIRED. Add transactional replacement and clear Doctor upload statuses.
Test persistence, failure, tampering, ownership and replacement; run unchanged Patient
regression and independent builds. Live submission is gated by actual configuration
and policy, never a fixture presented as live evidence.


## Implemented storage and configuration

The adapter is Windows local-test storage, not an approved production/cloud provider.
Server startup reuses the existing registration dependency injection. Defaults remain
disabled, and local-test mode is rejected in staging/production. No runtime encryption
key or document policy was fabricated or enabled during this phase.

| Variable | Meaning |
| --- | --- |
| DOCTOR_CREDENTIAL_STORAGE | disabled (default) or local-test |
| DOCTOR_CREDENTIAL_ROOT | Absolute, pre-provisioned private directory outside public/static/sync trees |
| DOCTOR_CREDENTIAL_KEY | Private random 32-byte key encoded as base64; never in source or reports |
| DOCTOR_CREDENTIAL_SCANNER | Absolute path to installed Microsoft Defender MpCmdRun.exe |
| DOCTOR_REQUIRED_CREDENTIALS | Approved comma-separated supported categories; empty means policy unavailable |

Supported policy categories remain QUALIFICATION, REGISTRATION, IDENTITY and
ADDITIONAL. PROFILE_PHOTO is optional. No mandatory medical/legal rule or retention
period was chosen. Missing policy blocks submission and approval independently of
Flutter checks. BLOCKED - BUSINESS/POLICY APPROVAL REQUIRED.

Objects use random server-generated keys mapped to hashed filenames. Persistent
bytes use AES-256-GCM with a fresh nonce and the logical object key as authenticated
data. The encryption key remains separate from the object directory. Directory
ownership/permissions are checked on access: Windows protected ACL permitting only
the current service identity, SYSTEM and Administrators; POSIX owner-only checks
are also present in the adapter tests. Symbolic roots, traversal keys, wrong keys,
modified ciphertext and overwrites fail closed.

Uploads are staged in the private directory only for scanning. The scanner uses
custom file scanning with remediation disabled; a nonzero exit, timeout, changed
file or read failure rejects storage. Temporary files are removed on completion or
failure. Process-crash orphan reconciliation and approved retention/key rotation/
backup policy remain deployment work; this adapter is explicitly test-only.

The scanner invocation follows [Microsoft Defender command-line documentation](https://learn.microsoft.com/en-us/defender-endpoint/command-line-arguments-microsoft-defender-antivirus).
Scanning is bounded to 60 seconds; the Doctor credential request allows 90 seconds,
while other Doctor API requests retain their existing timeout. No authentication
or OTP limit was changed. Host scanner configuration/cloud policy is not asserted
suitable for production credential processing.

## Private retrieval and ownership

Existing authenticated credential GET endpoints continue proxying bytes as base64
with the global no-store response policy. There is no static file mount, bucket
URL, permanent public URL, signed public link or client-selected destination. Admin
uses its existing private download and existing authorization/step-up controls.
Doctor-owned metadata and document IDs are checked before reading the storage key.
Patient and unauthenticated callers remain denied.

## Atomic replacement and Doctor UI

The existing POST /doctor/registration/documents accepts optional replaceDocumentId.
No new parallel upload API exists. The new bytes must store successfully first;
then, under the existing Doctor row lock, the backend verifies same-owner/same-kind
old metadata and swaps the current document in a single database transaction.
Failure preserves the old record. Successful replacement removes the old object
through the existing editable-document removal behavior. Failed object cleanup can
leave an encrypted, unreachable orphan; an approved reconciliation/retention policy
is needed before production. No new historical retention/deletion rule was invented.

Doctor Riverpod state exposes UPLOADING, UPLOADED and FAILED; absence of current
metadata shows NOT UPLOADED. A busy progress bar, error and retry/reselection remain
visible. Each editable document has Replace and Remove. Uploaded never means verified.
All Flutter changes remain in Pocket Doctor Doctor; Patient source is unchanged.

## Actual environment probe

A private test directory was provisioned outside OneDrive under the current user's
local application data. A harmless synthetic text probe was submitted to the already
installed Defender scanner. It returned exit 2 and HRESULT 0x80004005. The probe was
removed. Evidence: artifacts/registration-storage/scanner-probe.log and scanner-status.json.

SCANNER = BLOCKED. No scanner bypass, disabled scanning or successful live upload is
claimed. The running API's storage remains disabled. Private-storage adapter tests
use actual encrypted filesystem writes with an explicitly identified scanner test
double; those results are not live malware-scanning or provider acceptance.

## Live acceptance gates

| Journey | Actual outcome | Status |
| --- | --- | --- |
| Real scanner probe | Failed; no upload accepted | BLOCKED |
| Required documents / retention approval | No approved policy supplied | BLOCKED |
| Flutter upload -> submission -> pending | Not performed through a functioning scanner/policy boundary | BLOCKED |
| Admin live credential review -> approval -> Doctor Home | No valid live submission established | BLOCKED |
| Live rejection -> replacement -> resubmission | No valid live submission established | BLOCKED |
| Native draft/session restart | No native registration run performed in this phase | BLOCKED |
| Production storage/SMS/legal verification/iOS | Not configured or validated here | BLOCKED |

No real credential, fake accepted appointment or manually approved Doctor was added
to obtain a live PASS. Automated lifecycle/ownership evidence is recorded separately.


## Final verification results

| Check | Result | Evidence in artifacts/registration-storage |
| --- | --- | --- |
| Doctor analysis | PASS, no issues | doctor-analyze-verified.log |
| Doctor tests | PASS, 35 / 0 skipped / 0 failed | doctor-tests-verified.log |
| Doctor debug APK | PASS | doctor-build.log (build exit 0 in doctor-exit.json) |
| Patient analysis/tests | PASS, no issues; 89 / 0 skipped / 0 failed | patient-analyze.log; patient-tests.log |
| Patient independent debug APK | PASS | patient-build.log; patient-exit.json |
| Backend typecheck/build | PASS | backend-typecheck-final.log; backend-build.log; backend-build-exit.json |
| Backend full suite | PASS, 144 / 0 skipped / 0 failed | backend-tests.log; backend-tests-exit.json |
| Existing Admin tests | PASS, 16 / 0 skipped / 0 failed | admin-tests.log |
| Prisma | PASS, 15 migrations current, no drift; no schema change | prisma-validate.log; prisma-status.log; prisma-drift.log |
| Patient source integrity | PASS, 77 Dart files match; no authoritative Patient changes | patient-source-integrity.json; patient-git-status.txt |
| Changed source/secret scan | PASS, no configured secret values, credential URLs or private-key markers; synchronized files match | security-scan.json |
| Native device availability | BLOCKED, adb lists no attached device/emulator | adb-devices.log |
| Actual malware scanner | BLOCKED, exit 2 / 0x80004005 | scanner-status.json; scanner-probe.log |
| Document/retention policy | BLOCKED - BUSINESS/POLICY APPROVAL REQUIRED | No approved policy supplied |

Final automated total: 284 passed, 0 skipped, 0 failed. Doctor increased by three
upload/retry/replacement tests; backend by five encrypted-store tests and one API
replacement subtest. Existing tests were not deleted, weakened or skipped.
Initial analyzer/test-fixture failures remain in their original logs; final verified
logs show passing results. Earlier registration timeout evidence is also preserved.

No actual credential upload, live submission, Admin credential approval, native
registration restart or production storage acceptance is claimed. Storage remains
disabled in the running test API because the scanner failed. Production storage
provider approval, retention/review policy and live/native acceptance remain open.

FINAL STATUS: BLOCKED for the requested live lifecycle. Implementation, automated
security/storage checks and independent builds pass; environmental/policy gates
have not been bypassed.


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
