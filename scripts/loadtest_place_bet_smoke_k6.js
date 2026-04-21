import http from 'k6/http';
import { check, sleep } from 'k6';

/**
 * Single request smoke test (1 VU, 1 iteration).
 * Does not use `scenarios`, so CLI flags work as expected.
 *
 *   k6 run scripts/loadtest_place_bet_smoke_k6.js
 *
 * Env: SUPABASE_URL, SUPABASE_ANON_KEY, USER_JWT
 */

export const options = {
  vus: 1,
  iterations: 1,
  thresholds: {
    http_req_failed: ['rate<1'],
  },
};

const baseUrl = __ENV.SUPABASE_URL;
const anonKey = __ENV.SUPABASE_ANON_KEY;
const userJwt = __ENV.USER_JWT;

if (!baseUrl || !anonKey || !userJwt) {
  throw new Error(
    'Missing env vars. Required: SUPABASE_URL, SUPABASE_ANON_KEY, USER_JWT',
  );
}

const endpoint = `${baseUrl}/rest/v1/rpc/place_bet`;

export default function () {
  const digit = Math.floor(Math.random() * 100);
  const payload = JSON.stringify({
    p_digit: digit,
    p_amount: 100,
  });

  const headers = {
    'Content-Type': 'application/json',
    apikey: anonKey,
    Authorization: `Bearer ${userJwt}`,
  };

  const res = http.post(endpoint, payload, { headers });
  const ok = check(res, {
    'status is 200': (r) => r.status === 200,
    'response has success': (r) => {
      try {
        const body = JSON.parse(r.body);
        return body && Object.prototype.hasOwnProperty.call(body, 'success');
      } catch (_) {
        return false;
      }
    },
  });

  if (!ok) {
    console.log(`FAIL status=${res.status} body=${res.body}`);
  }

  sleep(0.05);
}
