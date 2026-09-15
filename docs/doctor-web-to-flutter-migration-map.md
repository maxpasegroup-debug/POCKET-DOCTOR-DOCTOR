# Doctor web to Flutter migration map

Audit date: 2026-09-08. Inventory completed before Flutter implementation.

## Source and provenance

The requested workspace was empty. The existing platform was located read-only at
`../pocket doctor`. Its clean HEAD is `435a684`; that commit deleted the Doctor
web frontend. The last committed portal is `58658d1:apps/doctor-portal`.
This inventory describes that recoverable source, not an assumed newer deployment.
Backend contracts were checked against HEAD. No source application was modified.

## Complete frontend inventory

The portal has one HTML entry point and no URL router. `src/main.ts` owns all
screens and forms; `src/models.ts` owns DTOs, agenda filtering and availability
validation; `src/api.ts` owns bearer transport and session invalidation.
`src/style.css` owns all presentation. Remaining files: `index.html`, README,
package manifest/lock, TypeScript config, `.env.example`, `.gitignore`, and
`test/portal.test.ts` (8 tests). No other pages or components exist in this tree.

Components/functions: `el`, `button`, `field`, `message`, `submit`, `brand`,
`reset`, `login`, `otp`, `logout`, `show`, `renderAgenda`, `detail`, `profile`,
`availability` (including dynamic window rows). Navigation: Agenda, Profile,
Availability; appointment detail replaces agenda content; back returns to Today.

| Web feature | Existing API (relative to /api/v1) | Existing logic | Database model | Flutter screen | Provider/repository | Migration status |
|---|---|---|---|---|---|---|
| Mobile number | POST /auth/otp/request | Trim; Indian +91 number, first digit 6–9; backend rate limit/challenge | User, OtpChallenge | Sign in | AuthController/AuthRepository | PARTIAL: implemented; live validation pending |
| Six digit OTP | POST /auth/otp/verify | Challenge ID + code only; backend resolves identity; no client role input | User, Session, OtpChallenge | OTP | AuthController/AuthRepository | PARTIAL: implemented; live validation pending |
| Doctor access | GET /doctor/profile | DOCTOR role and assigned VERIFIED profile; demo config enforced | User, Doctor | Session gate | AuthController/AuthRepository | PARTIAL: implemented; live validation pending |
| Resume/session expiry | GET /auth/session | Web foreground check; memory-only session; 401 clears all private state; late responses rejected | Session, User | Session gate | AuthController/ApiClient | PARTIAL: implemented; live validation pending |
| Logout | POST /auth/logout | Revoke server session; clear locally even on failure; disclose failure | Session | Profile/logout | AuthController/AuthRepository | PARTIAL: implemented; live validation pending |
| Dashboard/agenda | GET /doctor/appointments | Latest 100 assigned consultations; Today in doctor timezone; Upcoming active and ends in future; Completed status; ascending start order | Doctor, Consultation, User, ConsultationNote, EnrollmentPayment | Home | appointmentsProvider/DoctorRepository | PARTIAL: implemented; live validation pending |
| Appointment detail | Same authorized appointments response | Patient name, time, timezone, status; no arbitrary patient lookup | Consultation, User | Appointment detail | appointmentsProvider/DoctorRepository | PARTIAL: implemented; live validation pending |
| Lifecycle actions | POST /doctor/consultations/:id/action | Demo only; start/complete/no-show; backend time/status/idempotency checks; refresh after success | Doctor, Consultation | Appointment detail | DoctorRepository | PARTIAL: implemented; live validation pending |
| Private notes/shared summary | POST /doctor/consultations/:id/notes | IN_PROGRESS or COMPLETED only; private 10000 chars, summary 5000; summary visible to patient only after completion | ConsultationNote, Consultation | Notes editor | DoctorRepository | PARTIAL: implemented; live validation pending |
| Follow-up | Same notes endpoint | Required toggle; optional real YYYY-MM-DD date, visible note max 2000; disabled sends null date and empty note | ConsultationNote | Notes editor | DoctorRepository | PARTIAL: implemented; live validation pending |
| Profile | GET/PATCH /doctor/profile | Credentials read-only; edit biography (trim, 1–2000) and languages (1–10, each 2–40; backend lowercase) only | Doctor | Profile | profileProvider/DoctorRepository | PARTIAL: implemented; live validation pending |
| Availability | GET/POST /doctor/availability | Timezone, length 10–120, buffer 0–60, accepting toggle; ISO weekdays; add/remove windows; valid excluded dates; no overlaps; windows fit duration; max 28 windows/120 dates; end may be 24:00 | Doctor, DoctorAvailability, DoctorAvailabilityException | Availability | availabilityProvider/DoctorRepository | PARTIAL: implemented; live validation pending |
| Connection notice | None called by portal | Real provider unavailable; not an emergency service; no fake visit | Consultation | Appointment detail | None | PARTIAL: implemented; live validation pending |
| Verification | Profile request gives generic 403 in historical UI | Admin-managed; current GET /doctor/session exposes authoritative PENDING_VERIFICATION, REJECTED, SUSPENDED, INACTIVE, PROFILE_REQUIRED, UNAVAILABLE, READY | Doctor, User, Session | Access status | AuthRepository | PARTIAL: implemented; live validation pending |
| Programs | No Doctor web feature | Doctor relationship exists; no web creation/publication workflow to migrate | Program (unchanged) | None | None | BLOCKED: absent in source |
| Notifications/preferences | No Doctor web feature | Shared notification backend exists; no portal inbox/preferences to migrate | Notification (unchanged) | None | None | BLOCKED: absent in source |
| Earnings/records | No earnings page | Payment relationship exists; no Doctor earnings totals API used by portal | EnrollmentPayment (unchanged) | None | None | BLOCKED: absent in source |

## UI states, validation and actions

All section loads show loading, generic error and Retry. Agenda has separate Today
and other empty copy and Refresh. Navigation epochs discard stale responses.
Forms disable buttons during requests, remove old notices, preserve input after
failure, display errors and announce save success. No confirmation dialogs exist.
OTP has Use another number and development-code display only with explicit local
build configuration. Demo banner labels sample accounts/appointments. Profile
explains platform-managed credentials. Availability explains breaks and preserved
booked times. Notes explain private versus shared content. Notes are unavailable
outside IN_PROGRESS/COMPLETED. Follow-up fields disable when unchecked.

Transport: 12 second timeout, no cached responses, bearer header, data envelope;
401 resets session, 403 verified-account message, 409 refresh/conflict message,
429 wait message, generic errors for other failures and malformed responses.
Production requires explicit HTTPS /api/v1 base without embedded credentials,
query or fragment. Local web HTTP only permits loopback.

## Authoritative backend rules

`modules/auth/routes.ts`, `identity-service.ts`, `authorization.ts` and
`doctor-session.ts` own OTP, session revocation, role and account checks. Bearer
authentication remains supported by Doctor APIs; native clients do not require
the browser cookie/origin exchange. Current GET /doctor/session is suitable for
verification display without changing identity or granting access.

`modules/consultations/routes.ts`, `consultation-service.ts`, `availability.ts`
own strict request schemas, assigned-doctor lookup, transaction locks, ownership,
slot generation, conflicts, and note disclosure. Patient DTOs omit private notes.
Doctor IDs and patient IDs are never supplied by the mobile client for lookups.
Actions use only consultation IDs obtained from assigned appointments.

Lifecycle enum: PENDING_PAYMENT, CONFIRMED, IN_PROGRESS, COMPLETED, CANCELLED,
NO_SHOW, EXPIRED. Rescheduling changes booked timestamps and rescheduledAt; it is
not a RESCHEDULED enum or a Doctor web action. Cancellation/rescheduling/payment
are patient workflows and must not be recreated as Doctor mutations.

Start: CONFIRMED, within 10 minutes before start through end. Complete:
IN_PROGRESS. No-show: CONFIRMED after end. Repeating target state is idempotent.
All transitions require demo doctor and enabled DEMO_CONSULTATIONS. Real session
access endpoint exists but its provider is unavailable and portal never calls it.

## Retirement gate

The sibling repository already removed the web portal in 435a684, before this
task. That removal is not evidence of migration parity. This task deletes no
frontend, backend, schema, shared code or deployment configuration. Historical
source remains recoverable from Git. Final parity and validation are recorded in
doctor-mobile-migration.md; this initial audit alone does not approve retirement.

