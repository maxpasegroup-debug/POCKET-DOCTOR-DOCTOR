import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { createDatabase } from '../.validation/platform/services/api/src/database/database.js';

const target = new URL(process.env.DATABASE_URL!);
assert.equal(target.hostname, '127.0.0.1');
assert.equal(target.port, '55433');
assert.equal(target.pathname, '/pocket_doctor_test');
assert.equal(process.env.APP_ENV, 'development');
assert.equal(process.env.OTP_MODE, 'development');
assert.equal(process.env.DEMO_CONSULTATIONS, 'true');
const database = createDatabase(process.env.DATABASE_URL!);
const db = database.client!;
const fixtures = ['Doctor A', 'Doctor B', 'Patient A', 'Patient B', 'Admin'].map((label, i) => ({
  label, id: `81000000-0000-4000-8000-${String(i + 1).padStart(12, '0')}`,
  phone: `+91999991800${i + 1}`, name: `DEMO D-ENVIRONMENT ${label}`,
  role: i < 2 ? 'DOCTOR' as const : i < 4 ? 'USER' as const : 'ADMIN' as const,
}));
try {
  // Same synthetic-fixture method as existing Doctor integration tests and
  // consultations seed. Collision checks prevent promotion of another account.
  await db.$transaction(async tx => {
    for (const f of fixtures) {
      const existing = await tx.user.findFirst({ where: { OR: [{ id: f.id }, { phone: f.phone }] }, include: { roles: true } });
      if (existing) {
        assert.equal(existing.id, f.id); assert.equal(existing.phone, f.phone);
        assert.equal(existing.fullName, f.name);
        assert.deepEqual(existing.roles.map(r => r.role), [f.role]);
      } else await tx.user.create({ data: { id: f.id, phone: f.phone, fullName: f.name,
        profileCompletedAt: new Date(), roles: { create: { role: f.role } } } });
      if (f.role === 'DOCTOR') {
        const doctorId = f.id.replace('81000000', '82000000');
        const doctor = await tx.doctor.findUnique({ where: { id: doctorId } });
        if (doctor) { assert.equal(doctor.userId, f.id); assert.equal(doctor.isDemo, true); }
        else await tx.doctor.create({ data: { id: doctorId, userId: f.id, name: f.name,
          qualification: 'DEMO — not a real credential', specialty: 'Synthetic test education',
          biography: 'Synthetic D-ENVIRONMENT test profile. No real clinician or patient.',
          languages: ['english', 'hindi'], verificationStatus: 'VERIFIED', isDemo: true,
          acceptingAppointments: true, timezone: 'Asia/Kolkata', consultationMinutes: 30,
          bufferMinutes: 10, feePaise: 0,
          availability: { create: Array.from({ length: 7 }, (_, day) => ({ weekday: day + 1, startMinute: 540, endMinute: 1020 })) },
        } });
      }
    }
  });
  const results: object[] = [];
  for (const f of fixtures) {
    const request = async (route: string, method = 'GET', body?: object, token?: string) => {
      const response = await fetch(`http://127.0.0.1:3018/api/v1${route}`, {
        method, headers: { ...(body ? { 'Content-Type': 'application/json' } : {}), ...(token ? { Authorization: `Bearer ${token}` } : {}) },
        ...(body ? { body: JSON.stringify(body) } : {}), signal: AbortSignal.timeout(12000),
      });
      return { status: response.status, body: await response.json() as any };
    };
    const challenge = await request('/auth/otp/request', 'POST', { phone: f.phone });
    assert.equal(challenge.status, 200);
    assert.ok(/^\d{6}$/.test(challenge.body.data.developmentCode), 'Expected development OTP shape; value withheld');
    const login = await request('/auth/otp/verify', 'POST', { challengeId: challenge.body.data.challengeId, code: challenge.body.data.developmentCode });
    assert.equal(login.status, 200);
    const token = login.body.data.token;
    try {
      assert.deepEqual(login.body.data.user.roles, [f.role]);
      const session = await request('/auth/session', 'GET', undefined, token);
      assert.equal(session.status, 200);
      const doctorSession = await request('/doctor/session', 'GET', undefined, token);
      assert.equal(doctorSession.status, f.role === 'DOCTOR' ? 200 : 403);
      if (f.role === 'DOCTOR') {
        assert.equal(doctorSession.body.data.status, 'READY');
        assert.equal((await request('/doctor/appointments', 'GET', undefined, token)).status, 200);
      }
      results.push({ label: f.label, id: f.id, role: f.role, otpLogin: 'PASS', session: 'PASS', doctorGate: doctorSession.status, homeApi: f.role === 'DOCTOR' ? 'PASS: appointments' : 'NOT TESTED: Flutter Home' });
    } finally { assert.equal((await request('/auth/logout', 'POST', undefined, token)).status, 200); }
  }
  fs.writeFileSync(path.resolve(import.meta.dirname, '../artifacts/environment/accounts.json'), JSON.stringify(results, null, 2));
  console.log('Five synthetic accounts provisioned; real HTTP development OTP, role separation and session/logout checks passed. Tokens not persisted.');
} finally { await database.close(); }

