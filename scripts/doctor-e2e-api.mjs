import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
const root = path.resolve(import.meta.dirname, '..');
const evidence = path.join(root, 'artifacts/e2e');
const outcomes = [];
const tokens = new Map();
const doctorA = '82000000-0000-4000-8000-000000000001';
const doctorB = '82000000-0000-4000-8000-000000000002';
const privateNote = 'DEMO E2E private: authorized doctor only.';
const summary = 'DEMO E2E shared consultation summary.';
let appointmentId;
const resumeId = process.argv[2];
const tomorrow = new Date(Date.now()+330*60000+86400000).toISOString().slice(0,10);
async function call(label, actor, route, method = 'GET', body, expected = 200) {
  const response = await fetch(`http://127.0.0.1:3018/api/v1${route}`, {
    method, headers: { ...(body ? { 'Content-Type': 'application/json' } : {}), ...(tokens.has(actor) ? { Authorization: `Bearer ${tokens.get(actor)}` } : {}) },
    ...(body ? { body: JSON.stringify(body) } : {}), signal: AbortSignal.timeout(15000),
  });
  const data = await response.json();
  outcomes.push({ label, actor, method, route, expected, actual: response.status, pass: response.status === expected });
  assert.equal(response.status, expected, `${label}: status mismatch; response withheld`);
  return data.data;
}
try {
  for (const [i, actor] of ['Doctor A', 'Doctor B', 'Patient A', 'Patient B', 'Admin'].entries()) {
    const challenge = await call(`${actor} OTP request`, actor, '/auth/otp/request', 'POST', { phone: `+91999991800${i + 1}` });
    assert.ok(/^\d{6}$/.test(challenge.developmentCode), 'Development OTP unavailable; value withheld');
    const login = await call(`${actor} OTP verify`, actor, '/auth/otp/verify', 'POST', { challengeId: challenge.challengeId, code: challenge.developmentCode });
    tokens.set(actor, login.token);
    assert.deepEqual(login.user.roles, [i < 2 ? 'DOCTOR' : i < 4 ? 'USER' : 'ADMIN']);
  }
  if (!resumeId) {
  await call('Unauthenticated Doctor access', 'none', '/doctor/appointments', 'GET', undefined, 401);
  tokens.set('invalid', 'not-a-session');
  await call('Invalid session', 'invalid', '/doctor/appointments', 'GET', undefined, 401);
  await call('Patient denied Doctor', 'Patient A', '/doctor/appointments', 'GET', undefined, 403);
  await call('Doctor denied Admin', 'Doctor A', '/admin/operations/doctors', 'GET', undefined, 403);
  await call('Admin Doctor management', 'Admin', '/admin/operations/doctors');
  for (const actor of ['Doctor A', 'Doctor B']) {
    const state = await call(`${actor} READY`, actor, '/doctor/session');
    assert.equal(state.status, 'READY');
    await call(`${actor} real agenda`, actor, '/doctor/appointments');
  }
  const originalB = await call('Doctor B profile baseline', 'Doctor B', '/doctor/profile');
  const availabilityB = await call('Doctor B availability baseline', 'Doctor B', '/doctor/availability');
  const editedProfile = { biography: 'DEMO E2E persisted profile via real API; no medical advice.', languages: ['english', 'hindi'] };
  await call('Doctor A profile save', 'Doctor A', '/doctor/profile', 'PATCH', editedProfile);
  const profile = await call('Doctor A profile reload', 'Doctor A', '/doctor/profile');
  assert.equal(profile.doctor.biography, editedProfile.biography);
  await call('Reject profile target injection', 'Doctor A', '/doctor/profile', 'PATCH', { ...editedProfile, doctorId: doctorB }, 400);
  assert.deepEqual(await call('Doctor B profile unchanged', 'Doctor B', '/doctor/profile'), originalB);
  const now = new Date();
  const local = new Date(now.getTime() + 330 * 60000);
  const date = local.toISOString().slice(0, 10);
  const excludedDate = new Date(local.getTime() + 3 * 86400000).toISOString().slice(0, 10);
  const minute = local.getUTCHours() * 60 + local.getUTCMinutes() + 4;
  assert.ok(minute + 50 < 1440, 'Near midnight: use another real-time window; do not alter clock');
  const weekday = local.getUTCDay() || 7;
  const availability = { timezone: 'Asia/Kolkata', consultationMinutes: 10, bufferMinutes: 2, acceptingAppointments: true,
    windows: Array.from({length:7},(_,d)=>({weekday:d+1,startMinute:d+1===weekday?minute:540,endMinute:d+1===weekday?minute+50:1020})), excludedDates: [excludedDate] };
  await call('Doctor A availability save', 'Doctor A', '/doctor/availability', 'POST', availability);
  assert.deepEqual(await call('Doctor A availability reload', 'Doctor A', '/doctor/availability'), availability);
  await call('Reject availability target injection', 'Doctor A', '/doctor/availability', 'POST', { ...availability, doctorId: doctorB }, 400);
  assert.deepEqual(await call('Doctor B availability unchanged', 'Doctor B', '/doctor/availability'), availabilityB);
  const discovery = await call('Patient discovers Doctor A', 'Patient A', '/doctors?q=D-ENVIRONMENT');
  assert.ok(discovery.doctors.some(d=>d.id===doctorA));
  await call('Patient Doctor profile', 'Patient A', `/doctors/${doctorA}`);
  const excluded = await call('Excluded date has no slots', 'Patient A', `/doctors/${doctorA}/slots?date=${excludedDate}`);
  assert.equal(excluded.slots.length, 0);
  const slots = await call('Backend-generated current slots', 'Patient A', `/doctors/${doctorA}/slots?date=${date}`);
  assert.ok(slots.slots.length > 0);
  const booking = await call('Patient A books via actual API', 'Patient A', '/consultations/book', 'POST', { doctorId: doctorA, date, startsAt: slots.slots[0].startsAt });
  appointmentId = booking.consultation.id;
  assert.equal(booking.consultation.status, 'CONFIRMED');
  const agenda = await call('Doctor A sees same booking', 'Doctor A', '/doctor/appointments');
  const appointment = agenda.consultations.find(a=>a.id===appointmentId);
  assert.ok(appointment); assert.equal(appointment.patientName, 'DEMO D-ENVIRONMENT Patient A');
  await call('Patient B denied Patient A appointment', 'Patient B', `/me/consultations/${appointmentId}`, 'GET', undefined, 404);
  await call('Doctor B denied Patient A context', 'Doctor B', `/doctor/consultations/${appointmentId}/access`, 'POST', {}, 404);
  await call('Doctor B denied private note mutation', 'Doctor B', `/doctor/consultations/${appointmentId}/notes`, 'POST', { privateNote, summary, followUpRequired:false,followUpDate:null,followUpNote:'' }, 404);
  await call('Patient denied private Doctor note API', 'Patient A', `/doctor/consultations/${appointmentId}/notes`, 'POST', { privateNote,summary,followUpRequired:false,followUpDate:null,followUpNote:'' }, 403);
  } else { appointmentId = resumeId; }
  await call('Valid demo start', 'Doctor A', `/doctor/consultations/${appointmentId}/action`, 'POST', {action:'start'});
  await call('Doctor saves notes and follow-up', 'Doctor A', `/doctor/consultations/${appointmentId}/notes`, 'POST', {privateNote, summary, followUpRequired:true,followUpDate:tomorrow,followUpNote:'DEMO follow-up shared information.'});
  const before = await call('Patient summary withheld before completion', 'Patient A', `/me/consultations/${appointmentId}`);
  assert.equal(before.consultation.note, null);
  await call('Valid demo completion', 'Doctor A', `/doctor/consultations/${appointmentId}/action`, 'POST', {action:'complete'});
  const after = await call('Patient receives only shared note', 'Patient A', `/me/consultations/${appointmentId}`);
  assert.equal(after.consultation.note.summary, summary);
  assert.equal(after.consultation.note.followUpDate, tomorrow);
  assert.ok(!JSON.stringify(after).includes(privateNote));
  assert.ok(!Object.hasOwn(after.consultation.note,'privateNote'));
  const own = await call('Doctor private note reload', 'Doctor A', '/doctor/appointments');
  assert.equal(own.consultations.find(a=>a.id===appointmentId).note.privateNote,privateNote);
  const other = await call('Doctor B cannot list Doctor A booking', 'Doctor B', '/doctor/appointments');
  assert.ok(!other.consultations.some(a=>a.id===appointmentId));
  const bslots = await call('Patient B discovers own test doctor slots', 'Patient B', `/doctors/${doctorB}/slots?date=${tomorrow}`);
  assert.ok(bslots.slots.length>=2);
  const second = await call('Patient B books Doctor B through API', 'Patient B', '/consultations/book','POST',{doctorId:doctorB,date:tomorrow,startsAt:bslots.slots[0].startsAt});
  const secondId=second.consultation.id;
  await call('Doctor A denied unrelated Patient B context','Doctor A',`/doctor/consultations/${secondId}/access`,'POST',{},404);
  await call('Doctor A denied Doctor B note','Doctor A',`/doctor/consultations/${secondId}/notes`,'POST',{privateNote,summary,followUpRequired:false,followUpDate:null,followUpNote:''},404);
  await call('Patient A denied Patient B appointment','Patient A',`/me/consultations/${secondId}`,'GET',undefined,404);
  const rescheduled=await call('Patient supported reschedule','Patient B',`/consultations/${secondId}/reschedule`,'POST',{date:tomorrow,startsAt:bslots.slots[1].startsAt});
  assert.equal(rescheduled.consultation.id,secondId);
  const cancelled=await call('Patient supported cancellation','Patient B',`/consultations/${secondId}/cancel`,'POST',{});
  assert.equal(cancelled.consultation.status,'CANCELLED');
  const runtime=JSON.parse(fs.readFileSync(path.join(root,'.validation/environment/runtime.json'),'utf8').replace(/^\uFEFF/,''));
  const url=new URL(runtime.env.DATABASE_URL);
  assert.equal(url.hostname,'127.0.0.1'); assert.equal(url.port,'55433'); assert.equal(url.pathname,'/pocket_doctor_test');
  const require=createRequire(path.join(root,'.validation/platform/services/api/package.json'));
  const client=new (require('pg').Client)({connectionString:runtime.env.DATABASE_URL});
  await client.connect();
  try {
    const row=await client.query('SELECT c.id,c."userId",c."doctorId",c.status,n."followUpDate" FROM "Consultation" c JOIN "ConsultationNote" n ON n."consultationId"=c.id WHERE c.id=$1',[appointmentId]);
    assert.equal(row.rows[0].userId,'81000000-0000-4000-8000-000000000003');
    assert.equal(row.rows[0].doctorId,doctorA); assert.equal(row.rows[0].status,'COMPLETED');
    fs.writeFileSync(path.join(evidence,'shared-appointment.json'),JSON.stringify({origin:'real Patient API booking; not Flutter UI',...row.rows[0]},null,2));
  } finally {await client.end();}
} catch (error) {
  outcomes.push({label:'Journey exception',pass:false,type:error.name,message:'Details withheld; inspect preceding status and source assertions'});
  process.exitCode=1;
} finally {
  for (const actor of ['Doctor A','Doctor B','Patient A','Patient B','Admin']) if(tokens.has(actor)) {
    try { await call(`${actor} logout`,actor,'/auth/logout','POST'); await call(`${actor} revoked session denied`,actor,'/auth/session','GET',undefined,401); }
    catch {process.exitCode=1;}
  }
  tokens.clear();
  fs.writeFileSync(path.join(evidence,'api-acceptance.json'),JSON.stringify({scope:'Actual HTTP and database acceptance, not Flutter UI',appointmentId,outcomes},null,2));
  console.log(JSON.stringify({checks:outcomes.length,failed:outcomes.filter(o=>!o.pass).length}));
}

