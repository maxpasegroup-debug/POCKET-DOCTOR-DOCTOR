# Reproducing validation

Doctor app, from this workspace:

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --dart-define-from-file=config/development.example.json
flutter build apk --release --dart-define-from-file=config/production.example.json
```

Replace the production example hostname before any deployment. A release build
with an example hostname checks compilation only; it does not validate service
connectivity. Configure signing separately before distribution.

The unchanged source platform was archived into `.validation/platform` from
`../pocket doctor` commit `435a684` using `git archive`. The copy is ignored and
exists solely to avoid writing dependencies/build outputs into the source repo.

In `.validation/platform/services/api`:

```powershell
npm ci
npm run generate
npm test
npm run typecheck
```

The initial run above skips database-dependent tests. For full integration,
configure `DATABASE_URL` to an isolated test PostgreSQL database using local
secret configuration, deploy the existing migrations there, and set
`AUTH_INTEGRATION=true` before rerunning. Never point test fixtures at production.
Consult the platform's own validation documents for all provider/test flags.
This migration creates no new database schema or backend service.

In `.validation/platform/apps/admin-console`:

```powershell
npm ci
npm test
npm run build
```

In `.validation/platform/apps/mobile`:

```powershell
flutter pub get
flutter test
```

The Patient suite skips seven live API smoke tests without the existing test
deployment/flags. Those skipped tests must run for end-to-end acceptance.
See the Patient README and the platform's phase validation documents. Local
passing widget tests do not prove production Patient or Admin workflows.

Windows sandbox initially blocked Node subprocesses with EPERM; the recorded
successful Node runs used approved execution outside that sandbox. Flutter also
required SDK/cache access outside the workspace. No permission bypass was used.

iOS validation requires a macOS/Xcode environment and remains unperformed.
