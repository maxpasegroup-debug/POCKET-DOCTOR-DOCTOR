import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { spawnSync, spawn } from 'node:child_process';

const root = path.resolve(import.meta.dirname, '..');
const api = path.join(root, '.validation/platform/services/api');
const privateFile = path.join(root, '.validation/environment/runtime.json');
const evidence = path.join(root, 'artifacts/environment');
const runtime = (() => {
  try { return JSON.parse(fs.readFileSync(privateFile, 'utf8').replace(/^\uFEFF/, '')); }
  catch { throw new Error('Private runtime unavailable; configuration withheld.'); }
})();
const url = new URL(runtime.env.DATABASE_URL);
const expectedData = path.resolve(root, '../pocket doctor/artifacts/db-tooling/phase7-data-1788851081677');
if (url.hostname !== '127.0.0.1' || url.port !== '55433' || url.pathname !== '/pocket_doctor_test'
    || runtime.env.APP_ENV !== 'development' || path.resolve(runtime.dataDir) !== expectedData) {
  throw new Error('TEST DATABASE SAFETY = BLOCKED');
}
const env = { ...process.env, ...runtime.env, HOST: '127.0.0.1', PORT: '3018', NODE_ENV: 'test' };
const require = createRequire(path.join(api, 'package.json'));
const { Client } = require('pg');
const save = (name, value) => fs.writeFileSync(path.join(evidence, name), JSON.stringify(value, null, 2));
const action = process.argv[2];
try {
  if (action === 'inspect') {
    const client = new Client({ connectionString: env.DATABASE_URL });
    await client.connect();
    try {
      const identity = await client.query('SELECT current_database() AS database, host(inet_server_addr()) AS address, inet_server_port() AS port');
      if (identity.rows[0].database !== 'pocket_doctor_test' || identity.rows[0].address !== '127.0.0.1') throw new Error('Database identity mismatch');
      const counts = await client.query('SELECT (SELECT count(*) FROM "User") AS users, (SELECT count(*) FROM "Doctor") AS doctors, (SELECT count(*) FROM "Doctor" WHERE NOT "isDemo") AS non_demo_doctors');
      const constraints = await client.query("SELECT conname, contype FROM pg_constraint WHERE connamespace='public'::regnamespace ORDER BY conname");
      const indexes = await client.query("SELECT tablename,indexname FROM pg_indexes WHERE schemaname='public' ORDER BY tablename,indexname");
      const tables = await client.query("SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY tablename");
      const relationships = await client.query(`SELECT
        (SELECT count(*) FROM "Doctor" WHERE "userId" IN ('81000000-0000-4000-8000-000000000001','81000000-0000-4000-8000-000000000002') AND "isDemo" AND "verificationStatus"='VERIFIED') AS fixture_doctors,
        (SELECT count(*) FROM "DoctorAvailability" WHERE "doctorId" IN ('82000000-0000-4000-8000-000000000001','82000000-0000-4000-8000-000000000002')) AS fixture_windows,
        (SELECT count(*) FROM "Consultation" c LEFT JOIN "Doctor" d ON d.id=c."doctorId" LEFT JOIN "User" u ON u.id=c."userId" WHERE d.id IS NULL OR u.id IS NULL) AS orphan_appointments,
        (SELECT count(*) FROM "ConsultationNote" n LEFT JOIN "Consultation" c ON c.id=n."consultationId" WHERE c.id IS NULL) AS orphan_notes`);
      save('relationships.json', relationships.rows[0]);
      save('database-inspection.json', { safety: 'PASS: documented local synthetic test cluster', identity: identity.rows[0], counts: counts.rows[0], tables: tables.rows, constraints: constraints.rows, indexes: indexes.rows });
      console.log('Verified existing loopback test database; schema metadata recorded without personal data.');
    } finally { await client.end(); }
  } else if (action === 'start-db' || action === 'stop-db') {
    const bin = path.resolve(root, '../pocket doctor/artifacts/db-tooling/node_modules/@embedded-postgres/windows-x64/native/bin/pg_ctl.exe');
    const args = action === 'start-db'
      ? ['-D', expectedData, '-l', path.join(evidence, 'postgres-supported.log'), '-o', '-h 127.0.0.1 -p 55433', '-w', 'start']
      : ['-D', expectedData, '-m', 'fast', '-w', 'stop'];
    const result = spawnSync(bin, args, { windowsHide: true, encoding: 'utf8' });
    console.log(`${action}: exit ${result.status}; only the verified test cluster targeted.`);
    process.exitCode = result.status ?? 1;
  } else if (action === 'api') {
    const log = fs.openSync(path.join(evidence, 'api.log'), 'a');
    const child = spawn(process.execPath, ['node_modules/tsx/dist/cli.mjs', 'src/server.ts'], { cwd: api, env, windowsHide: true, detached: true, stdio: ['ignore', log, log] });
    fs.writeFileSync(path.join(root, '.validation/environment/api.pid'), String(child.pid));
    child.unref();
    console.log('Existing backend started on loopback port 3018.');
  } else {
    const commands = {
      validate: ['node_modules/prisma/build/index.js', 'validate'],
      migrate: ['node_modules/prisma/build/index.js', 'migrate', 'deploy'],
      status: ['node_modules/prisma/build/index.js', 'migrate', 'status'],
      drift: ['node_modules/prisma/build/index.js', 'migrate', 'diff', '--from-config-datasource', '--to-schema', 'prisma/schema.prisma', '--exit-code'],
      test: ['node_modules/tsx/dist/cli.mjs', '--test', ...fs.readdirSync(path.join(api, 'test')).filter(f => f.endsWith('.test.ts')).map(f => `test/${f}`)],
      provision: ['node_modules/tsx/dist/cli.mjs', path.join(root, 'scripts/doctor-test-provision.mts')],
    };
    if (!commands[action]) throw new Error('Unknown environment action');
    const child = spawnSync(process.execPath, commands[action], { cwd: api, env, windowsHide: true, encoding: 'utf8', maxBuffer: 16 * 1024 * 1024 });
    // Redact all configured secret values before persisting subprocess output.
    let output = `${child.stdout ?? ''}\n${child.stderr ?? ''}`;
    for (const [key, value] of Object.entries(env)) {
      if (/SECRET|TOKEN|PASSWORD|DATABASE_URL|API_KEY/.test(key) && value) output = output.split(value).join('[REDACTED]');
    }
    output = output.replace(/postgres(?:ql)?:\/\/[^\s"']+/g, '[REDACTED DATABASE URL]');
    fs.writeFileSync(path.join(evidence, `${action}.log`), output);
    save(`${action}-exit.json`, { exitCode: child.status });
    console.log(`${action}: exit ${child.status}; redacted evidence saved.`);
    process.exitCode = child.status ?? 1;
  }
} catch (error) {
  console.error(JSON.stringify({name:error.name,code:error.code}));
  console.error('Environment operation failed; credentials withheld. Inspect safe evidence or verify configuration.');
  process.exitCode = 1;
}

