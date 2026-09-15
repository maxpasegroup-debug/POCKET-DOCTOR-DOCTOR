import fs from 'node:fs';
import path from 'node:path';
const root = path.resolve(import.meta.dirname, '..');
const privateRuntime = JSON.parse(fs.readFileSync(path.join(root, '.validation/environment/runtime.json'), 'utf8').replace(/^\uFEFF/, ''));
const secrets = Object.entries(privateRuntime.env)
  .filter(([key, value]) => /SECRET|TOKEN|PASSWORD|DATABASE_URL|API_KEY/.test(key) && typeof value === 'string' && value.length >= 16)
  .map(([, value]) => value);
const password = decodeURIComponent(new URL(privateRuntime.env.DATABASE_URL).password);
if (password) secrets.push(password);
const targets = ['scripts', 'artifacts/environment'].flatMap(dir => fs.readdirSync(path.join(root, dir)).filter(f => /\.(mjs|mts|ps1|json|log)$/.test(f)).map(f => path.join(root, dir, f)));
targets.push(path.join(root, 'docs/doctor-test-environment.md'));
const candidates = [];
for (const file of targets) {
  if (file.endsWith('secret-scan.json')) continue;
  const content = fs.readFileSync(file, 'utf8');
  if (secrets.some(value => content.includes(value)) || /-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/.test(content)
    || /postgres(?:ql)?:\/\/[^\s'"/]+:[^\s'"@]+@/.test(content)) candidates.push(path.relative(root, file));
}
const result = { filesScanned: targets.length, configuredSecretMatchesOrCredentialPatterns: candidates, privateRuntimeExcludedAndIgnored: true };
fs.writeFileSync(path.join(root, 'artifacts/environment/secret-scan.json'), JSON.stringify(result, null, 2));
console.log(JSON.stringify({ filesScanned: targets.length, candidateCount: candidates.length }));
process.exitCode = candidates.length ? 1 : 0;
