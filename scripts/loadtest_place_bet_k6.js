import http from 'k6/http';
import { check, sleep } from 'k6';

/**
 * Usage:
 * k6 run scripts/loadtest_place_bet_k6.js ^
 *   -e SUPABASE_URL=https://<ref>.supabase.co ^
 *   -e SUPABASE_ANON_KEY=<anon_key> ^
 *   -e USER_JWT=<user_access_token>
 *
 * Smoke (this file defines `scenarios`; prefer smoke script for 1 request):
 *   k6 run scripts/loadtest_place_bet_smoke_k6.js
 */

export const options = {
  scenarios: {
    burst_1000: {
      executor: 'constant-vus',
      vus: 1000,
      duration: '30s',
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.01'], // <1% failures
    http_req_duration: ['p(95)<2000'], // p95 < 2s
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

  // Tiny jitter reduces request synchronization spikes.
  sleep(Math.random() * 0.2);
}

