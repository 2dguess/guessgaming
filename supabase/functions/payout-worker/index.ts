import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const CRON_SECRET = Deno.env.get("PAYOUT_WORKER_CRON_SECRET") ?? "";
const DEFAULT_LIMIT = Number(Deno.env.get("PAYOUT_WORKER_DEFAULT_LIMIT") ?? "2000");
const DEFAULT_MAX_ATTEMPTS = Number(Deno.env.get("PAYOUT_WORKER_MAX_ATTEMPTS") ?? "5");

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

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return response(405, { ok: false, error: "Use POST" });
  }

  const token = req.headers.get("x-cron-secret") ?? "";
  if (!CRON_SECRET || token !== CRON_SECRET) {
    return response(401, { ok: false, error: "Unauthorized" });
  }

  const payload = await req.json().catch(() => ({}));
  const limit = Math.min(Number(payload?.limit ?? DEFAULT_LIMIT), 5000);
  const maxAttempts = Math.min(Number(payload?.maxAttempts ?? DEFAULT_MAX_ATTEMPTS), 20);

  const { data, error } = await admin.rpc("process_due_payout_jobs", {
    p_limit: limit,
    p_max_attempts: maxAttempts,
  });

  if (error) {
    return response(500, { ok: false, error: error.message });
  }

  return response(200, { ok: true, result: data });
});

