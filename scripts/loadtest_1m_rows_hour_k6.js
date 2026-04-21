import http from 'k6/http';
import { check, sleep } from 'k6';

/**
 * Target: ~1,000,000 house_inflow_queue rows per hour => ~278 enqueues/sec (place_bet).
 *
 * WARNING — balance:
 *   Each pick uses p_amount (default 100). At 278 req/s for 1h =>
 *   278 * 3600 * 100 = 100,080,000 score/hour from ONE user unless you lower amount
 *   or use many test accounts (not implemented here).
 *
 * Usage (PowerShell, from repo root):
 *   $env:SUPABASE_URL="https://<ref>.supabase.co"
 *   $env:SUPABASE_ANON_KEY="<anon>"
 *   $env:USER_JWT="<access_token>"
 *   $env:DURATION="10m"          # optional; default 10m (full 1h => DURATION=1h)
 *   $env:TARGET_RPS="278"      # optional; default 278 (= 1M/h)
 *   $env:P_AMOUNT="100"        # optional; min bet from your DB (often 100)
 *   k6 run scripts/loadtest_1m_rows_hour_k6.js
 *
 * During test: run house-inflow-worker so queued rows become applied; watch
 * house_inflow_queue_kpi and rows_per_sec_10m in SQL.
 */

const targetRps = Number(__ENV.TARGET_RPS || '278');
const duration = __ENV.DURATION || '10m';
const pAmount = Number(__ENV.P_AMOUNT || '100');

export const options = {
  scenarios: {
    one_m_per_hour_pace: {
      executor: 'constant-arrival-rate',
      rate: targetRps,
      timeUnit: '1s',
      duration,
      preAllocatedVUs: Math.min(2000, Math.max(100, targetRps * 2)),
      maxVUs: 3000,
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.05'],
    http_req_duration: ['p(95)<5000'],
  },
};

const baseUrl = __ENV.SUPABASE_URL;
const anonKey = __ENV.SUPABASE_ANON_KEY;
const userJwt = __ENV.USER_JWT;

if (!baseUrl || !anonKey || !userJwt) {
  throw new Error(
    'Missing env: SUPABASE_URL, SUPABASE_ANON_KEY, USER_JWT',
  );
}

const endpoint = `${baseUrl}/rest/v1/rpc/place_bet`;

export default function () {
  const digit = Math.floor(Math.random() * 100);
  const payload = JSON.stringify({
    p_digit: digit,
    p_amount: pAmount,
  });

  const headers = {
    'Content-Type': 'application/json',
    apikey: anonKey,
    Authorization: `Bearer ${userJwt}`,
  };

  const res = http.post(endpoint, payload, { headers });
  const ok = check(res, {
    'status is 200': (r) => r.status === 200,
    success: (r) => {
      try {
        const body = JSON.parse(r.body);
        return body && body.success === true;
      } catch (_) {
        return false;
      }
    },
  });

  if (!ok) {
    console.log(`FAIL status=${res.status} body=${String(res.body).slice(0, 500)}`);
  }

  sleep(0.01);
}

export function handleSummary(data) {
  const reqs = data.metrics.http_reqs?.values?.count ?? 0;
  const failed = data.metrics.http_req_failed?.values?.rate;
  const failPct =
    failed !== undefined ? (failed * 100).toFixed(2) + '%' : 'n/a';
  return {
    stdout: `
========================================
1M/h pace test (enqueue) — target ${targetRps} req/s, duration ${duration}
Total http_reqs: ${reqs}
http_req_failed rate: ${failPct}
========================================
`,
  };
}
