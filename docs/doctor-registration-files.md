# Registration file manifest

All Flutter registration source is in Pocket Doctor Doctor. Patient Flutter source is unchanged.

## Doctor files created

- lib/features/registration/registration_repository.dart
- lib/features/registration/registration_screen.dart
- test/registration_test.dart
- docs/doctor-registration-implementation.md
- docs/doctor-registration-files.md

## Doctor files modified

- lib/app.dart
- lib/features/auth/auth_repository.dart
- lib/features/auth/auth_controller.dart
- lib/features/auth/login_screen.dart
- lib/core/networking/api_client.dart
- pubspec.yaml
- pubspec.lock
- docs/doctor-mobile-migration.md

Flutter regenerates Android/iOS plugin registration for file_selector. No application identity change.

## Shared backend / existing Admin files

Paths relative to ../pocket doctor. Exactly these files were copied from the matching execution checkout; no apps/mobile paths.

- services/api/prisma/schema.prisma
- services/api/prisma/migrations/20260909100000_doctor_registration/migration.sql
- services/api/src/modules/auth/identity-service.ts
- services/api/src/modules/auth/doctor-session.ts
- services/api/src/modules/auth/request-budget.ts
- services/api/src/modules/doctor-registration/contracts.ts
- services/api/src/modules/doctor-registration/service.ts
- services/api/src/modules/doctor-registration/routes.ts
- services/api/src/app.ts
- services/api/src/modules/admin/routes.ts
- services/api/src/modules/admin/queries.ts
- services/api/test/doctor-registration.integration.test.ts
- apps/admin-console/src/registration.ts
- apps/admin-console/src/pages.ts

## Evidence

artifacts/registration contains test/build/Prisma logs, source integrity reports, and the synchronization manifest. Private runtime credentials remain outside these files.
