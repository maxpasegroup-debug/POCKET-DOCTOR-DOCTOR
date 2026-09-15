import fs from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { readEnvironment } from '../.validation/platform/services/api/src/config/env.js';
import { configuredRegistration } from '../.validation/platform/services/api/src/modules/doctor-registration/local-store.js';

// Configuration-only diagnostic. Never opens a database, reads documents, or uploads.
export function readiness(input: NodeJS.ProcessEnv) {
  const environment = ['development', 'test', 'staging', 'production'].includes(input.APP_ENV ?? 'development')
    ? input.APP_ENV ?? 'development' : 'INVALID_CONFIGURATION';
  try {
    const env = readEnvironment(input);
    let storage = 'NOT_CONFIGURED';
    if (env.DOCTOR_CREDENTIAL_STORAGE !== 'disabled') {
      try { storage = configuredRegistration(env).store?.available ? 'CONFIGURED' : 'NOT_CONFIGURED'; }
      catch { storage = 'INVALID_CONFIGURATION'; }
    }
    return { environment, configuration: 'CONFIGURED',
      database: env.DATABASE_URL ? 'CONFIGURED' : 'NOT_CONFIGURED',
      storage, storageProvider: env.DOCTOR_CREDENTIAL_STORAGE,
      productionStorage: 'NOT_CONFIGURED',
      documentPolicy: env.DOCTOR_REQUIRED_CREDENTIALS ? 'CONFIGURED' : 'NOT_CONFIGURED',
      otp: env.OTP_MODE === 'disabled' ? 'NOT_CONFIGURED' : 'CONFIGURED',
      scope: 'Configuration only; no connectivity, scanning, policy approval or live acceptance verified' };
  } catch {
    // Do not serialize an exception, input values, URLs or provider responses.
    return { environment, configuration: 'INVALID_CONFIGURATION',
      database: 'INVALID_CONFIGURATION', storage: 'INVALID_CONFIGURATION',
      otp: 'INVALID_CONFIGURATION', productionStorage: 'NOT_CONFIGURED',
      scope: 'Configuration rejected; no network operations performed' };
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    const args = process.argv.slice(2);
    if (args.some(arg => arg !== '--test-runtime') || args.length > 1) throw new Error();
    let input = process.env;
    if (args.includes('--test-runtime')) {
      const runtime = JSON.parse(fs.readFileSync(new URL('../.validation/environment/runtime.json', import.meta.url), 'utf8').replace(/^\uFEFF/, ''));
      if (!runtime.env || typeof runtime.env !== 'object' || Array.isArray(runtime.env)
        || Object.values(runtime.env).some(value => typeof value !== 'string')) throw new Error();
      input = { ...process.env, ...runtime.env };
    }
    const result = readiness(input);
    console.log(JSON.stringify(result, null, 2));
    process.exitCode = result.configuration === 'INVALID_CONFIGURATION' || result.storage === 'INVALID_CONFIGURATION' ? 1 : 0;
  } catch {
    console.log(JSON.stringify({ configuration: 'INVALID_CONFIGURATION', scope: 'Input unavailable; values withheld' }));
    process.exitCode = 1;
  }
}
