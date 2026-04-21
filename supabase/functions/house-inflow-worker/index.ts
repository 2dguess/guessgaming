import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const CRON_SECRET = Deno.env.get("HOUSE_INFLOW_WORKER_CRON_SECRET") ?? "";

const DEFAULT_LIMIT = Number(Deno.env.get("HOUSE_INFLOW_WORKER_DEFAULT_LIMIT") ?? "50000");
const DEFAULT_MAX_ATTEMPTS = Number(Deno.env.get("HOUSE_INFLOW_WORKER_MAX_ATTEMPTS") ?? "5");
const DEFAULT_LOOPS = Number(Deno.env.get("HOUSE_INFLOW_WORKER_LOOPS") ?? "12");
const DEFAULT_SLEEP_MS = Number(Deno.env.get("HOUSE_INFLOW_WORKER_SLEEP_MS") ?? "5000");
const DEFAULT_REQUEUE_AFTER_SECONDS = Number(
  Deno.env.get("HOUSE_INFLOW_WORKER_REQUEUE_AFTER_SECONDS") ?? "120",
);

if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
  throw new Error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
}

const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { persistSession: false },
});

function response(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return response(405, { ok: false, error: "Use POST" });
  }

  const token = req.headers.get("x-cron-secret") ?? "";
  if (!CRON_SECRET || token !== CRON_SECRET) {
    return response(401, { ok: false, error: "Unauthorized" });
  }

  const payload = await req.json().catch(() => ({}));
  const limit = Math.min(Number(payload?.limit ?? DEFAULT_LIMIT), 200000);
  const maxAttempts = Math.min(Number(payload?.maxAttempts ?? DEFAULT_MAX_ATTEMPTS), 20);
  const loops = Math.min(Number(payload?.loops ?? DEFAULT_LOOPS), 60);
  const sleepMs = Math.min(Number(payload?.sleepMs ?? DEFAULT_SLEEP_MS), 30000);
  const requeueAfterSeconds = Math.min(
    Number(payload?.requeueAfterSeconds ?? DEFAULT_REQUEUE_AFTER_SECONDS),
    3600,
  );

  const runs: unknown[] = [];
  for (let i = 0; i < Math.max(1, loops); i++) {
    const { data, error } = await admin.rpc("process_house_inflow_queue", {
      p_limit: limit,
      p_max_attempts: maxAttempts,
      p_requeue_after_seconds: requeueAfterSeconds,
    });

    if (error) {
      return response(500, {
        ok: false,
        error: error.message,
        loop: i + 1,
        partial: runs,
      });
    }

    runs.push(data);

    // If current pass applied nothing, exit early.
    const applied = Number((data as Record<string, unknown> | null)?.applied ?? 0);
    const processed = Number((data as Record<string, unknown> | null)?.processed ?? 0);
    if (applied <= 0 && processed <= 0) {
      break;
    }

    if (i < loops - 1) {
      await sleep(Math.max(0, sleepMs));
    }
  }

  return response(200, {
    ok: true,
    config: { limit, maxAttempts, loops, sleepMs, requeueAfterSeconds },
    runs,
  });
});

