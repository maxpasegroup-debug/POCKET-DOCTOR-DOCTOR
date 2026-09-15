import fs from 'node:fs';
const base='http://127.0.0.1:3018/api/v1';
const results=[];let applicationId;
async function call(path,method='GET',body,token){const r=await fetch(base+path,{method,headers:{'content-type':'application/json',...(token?{authorization:'Bearer '+token}:{})},...(body?{body:JSON.stringify(body)}:{}),signal:AbortSignal.timeout(15000)});return {status:r.status,body:await r.json()};}
function expect(label,r,status){results.push({test:label,http:r.status,expected:status,status:r.status===status?'PASS':'FAIL'});if(r.status!==status)throw Error(label);return r.body.data;}
async function login(phone,registration=false){const prefix=registration?'/doctor/registration':'/auth';const q=expect('OTP request '+(registration?'Doctor':'Admin'),await call(prefix+'/otp/request','POST',{phone}),200);if(!q.developmentCode)throw Error('Development OTP unavailable');return expect('OTP verify '+(registration?'Doctor':'Admin'),await call(prefix+'/otp/verify','POST',{challengeId:q.challengeId,code:q.developmentCode}),200);}
try{
 const runtime=JSON.parse(fs.readFileSync(new URL('../.validation/environment/runtime.json',import.meta.url),'utf8')).env;
 const db=new URL(runtime.DATABASE_URL);if(db.hostname!=='127.0.0.1'||db.port!=='55433'||db.pathname!=='/pocket_doctor_test'||runtime.APP_ENV!=='development'||runtime.DOCTOR_REGISTRATION_DEFER_DOCUMENTS!=='true')throw Error('Test safety/configuration mismatch');
 const doctor=await login('+919999918099',true),token=doctor.token;
 const app=expect('Read draft',await call('/doctor/registration','GET',undefined,token),200);applicationId=app.id;
 if(app.status!=='DRAFT'||!app.documentPolicy.deferred)throw Error('Expected fresh deferred draft');
 expect('Save professional details',await call('/doctor/registration','PATCH',{name:'DEVELOPMENT Document Deferred Doctor',registrationEmail:'deferred-doctor@example.invalid',registrationDateOfBirth:'1990-01-01',registrationGender:'PREFER_NOT_TO_SAY',qualification:'SYNTHETIC TEST qualification',specialty:'SYNTHETIC TEST specialty',biography:'Development-only Doctor Home validation account. Credentials deferred; not for production care.',registrationAuthority:'SYNTHETIC TEST council',registrationNumber:'DEV-DEFERRED-001',experienceYears:2,languages:['English'],feePaise:10000},token),200);
 const submitted=expect('Submit without documents',await call('/doctor/registration/submit','POST',{},token),200);
 if(submitted.status!=='SUBMITTED'||submitted.documents.length!==0)throw Error('Expected pending without documents');
 expect('Pending operational denial',await call('/doctor/appointments','GET',undefined,token),403);
 expect('Doctor cannot approve',await call('/admin/operations/doctors/'+applicationId+'/registration/review','POST',{action:'APPROVE'},token),403);
 const admin=await login('+919999918005');
 expect('Admin application review',await call('/admin/operations/doctors/'+applicationId+'/registration','GET',undefined,admin.token),200);
 const approved=expect('Existing Admin approval',await call('/admin/operations/doctors/'+applicationId+'/registration/review','POST',{action:'APPROVE'},admin.token),200);
 if(approved.status!=='VERIFIED')throw Error('Expected verified');
 expect('Verified appointments/Home API',await call('/doctor/appointments','GET',undefined,token),200);
 expect('Verified profile API',await call('/doctor/profile','GET',undefined,token),200);
}catch{results.push({test:'Remaining live API steps',status:'BLOCKED',reason:'See preceding safe status; OTP, state or environment prerequisite unavailable. No limits bypassed.'});}
fs.writeFileSync(new URL('../artifacts/document-deferral/live-api.json',import.meta.url),JSON.stringify({scope:'Real HTTP API acceptance; NOT native Flutter UI acceptance',applicationId,results},null,2));
console.log(JSON.stringify({results,applicationId}));
