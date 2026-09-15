# Development-only document deferral

The server setting DOCTOR_REGISTRATION_DEFER_DOCUMENTS defaults to false. When explicitly
true in development/test, professional completeness is still validated, but document
storage/policy requirements are deferred for submission and Admin review. Staging,
production and NODE_ENV=production reject the flag. It is never accepted from a client.

The existing registration DTO exposes documentPolicy.deferred. Doctor Flutter uses
that server field to move from Professional information directly to Review and shows
an explicit development notice. Pending, rejected, verified and suspended navigation
and backend authorization are unchanged. Only the existing authorized Admin review
endpoint can approve a submitted application. Upload APIs and private storage are
preserved and still fail closed when no store is configured.

This is a temporary development exception, not medical credential verification or
production registration. Do not promote the test database or synthetic doctors to a
production environment. Disable the flag to restore document-required submission.
No Patient source changes and no schema migration are needed.

Tests add a database-backed zero-document submission/approval/suspension sequence,
production configuration rejection and a Flutter server-policy test. No existing
assertions, skip conditions or tests were removed. Device acceptance requires an
attached Android device; no device was attached at the start of this task.

Evidence will be recorded under artifacts/document-deferral.

## Real local API acceptance

The private runtime was explicitly enabled after verifying the isolated loopback test
database. No storage provider was configured. A real OTP registration used synthetic
phone +919999918099 (DEVELOPMENT Document Deferred Doctor). Application
e351a80a-aa1c-40a8-8146-9a203659b20d submitted with zero documents and stayed SUBMITTED.
Pending appointments access returned 403, Doctor approval attempt returned 403, and
existing Admin OTP/login/review/approval returned 200. After approval, appointments
and profile returned 200. Evidence: artifacts/document-deferral/live-api.json.
These were real HTTP API operations, not Flutter or Admin UI automation. No database
roles, approvals or appointments were inserted directly. No production credentials
or OTP limits were changed. The test account remains available for Doctor Home testing.

The initial regression exposed a disabled-factory return-shape regression, fixed by
preserving the original empty object; existing test was not weakened. It also hit a
transaction timeout in an unrelated WhatsApp test. Initial Flutter checks found a
new test type-name typo and a missing-braces lint, both corrected. Initial logs remain.

A fresh post-approval OTP login returned roles [DOCTOR] and /doctor/session status READY (HTTP 200). See verified-login.json. This confirms the existing backend Home gate, not native rendering. Storage diagnostics may still correctly report NOT_CONFIGURED while this temporary document exemption allows development submission.

## Final regression

Backend 146 passed (two new cases), Doctor 37 passed (two new cases), Patient 89
passed, Admin 16 passed; all zero skips/failures in final runs. Doctor and Patient
analysis passed. Initial failures are retained separately; the new widget test also
caught the four-step label during deferred flow, which was corrected to three steps.
The Patient app source and build configuration were not changed; its previous APK
build remains prior evidence rather than a new build in this task.

Files changed: Doctor registration model/screen and registration tests; shared backend
environment schema, existing registration dependency/factory/service and integration
tests; private local runtime flag (no secrets added to source); this document and
migration report. Added the real local API acceptance script. No database schema
changes, reset, Patient source changes, provider configuration or auto-approval.

Final Doctor debug APK build completed successfully. No Android device was attached. Development implementation and real API approval/READY login passed; native Flutter Home visibility and interactive full-feature acceptance remain BLOCKED.
