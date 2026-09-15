import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readiness } from './doctor-registration-readiness.mts';

test('missing provider stays unconfigured without enabling local storage', () => {
  const result = readiness({ APP_ENV: 'test' });
  assert.equal(result.storage, 'NOT_CONFIGURED');
  assert.equal(result.database, 'NOT_CONFIGURED');
  assert.equal(result.otp, 'NOT_CONFIGURED');
});
test('unknown provider is invalid and input values are never returned', () => {
  const value = 'unrecognized-private-provider';
  const result = readiness({ DOCTOR_CREDENTIAL_STORAGE: value });
  assert.equal(result.storage, 'INVALID_CONFIGURATION');
  assert.equal(JSON.stringify(result).includes(value), false);
});
test('incomplete local adapter configuration fails closed', () => {
  assert.equal(readiness({ APP_ENV: 'test', DOCTOR_CREDENTIAL_STORAGE: 'local-test' }).storage, 'INVALID_CONFIGURATION');
});
test('production cannot silently enable local storage', () => {
  assert.equal(readiness({ APP_ENV: 'production', DOCTOR_CREDENTIAL_STORAGE: 'local-test' }).storage, 'INVALID_CONFIGURATION');
});
