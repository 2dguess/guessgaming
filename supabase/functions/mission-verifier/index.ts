import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type VerificationResult = "verified" | "failed" | "manual_review";

interface JobRow {
  job_id: string;
  claim_id: string;
  user_id: string;
  mission_id: string;
  platform: "facebook" | "youtube" | "custom";
  verification_action: string;
  target_ref: string | null;
  status: "queued" | "processing" | "verified" | "failed" | "manual_review";
  attempt_count: number;
}

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const CRON_SECRET = Deno.env.get("MISSION_VERIFIER_CRON_SECRET") ?? "";
const MAX_ATTEMPTS = Number(Deno.env.get("MISSION_VERIFIER_MAX_ATTEMPTS") ?? "5");
const ALLOW_PROOF_URL_AUTO =
  (Deno.env.get("MISSION_VERIFIER_ALLOW_PROOF_URL_AUTO") ?? "false").toLowerCase() === "true";

if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
  throw new Error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
}

const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { persistSession: false },
});

function jsonResponse(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

async function hasLinkedSocialAccount(userId: string, platform: string) {
  const { data, error } = await admin
    .from("user_social_accounts")
    .select("id, is_verified")
    .eq("user_id", userId)
    .eq("platform", platform)
    .maybeSingle();
  if (error) throw error;
  return Boolean(data);
}

async function getMissionReward(missionId: string) {
  const { data, error } = await admin
    .from("missions")
    .select("reward_coin")
    .eq("mission_id", missionId)
    .maybeSingle();
  if (error) throw error;
  return Number(data?.reward_coin ?? 0);
}

async function getWalletForUpdate(userId: string) {
  const { data, error } = await admin
    .from("wallets")
    .select("balance")
    .eq("user_id", userId)
    .maybeSingle();
  if (error) throw error;
  return Number(data?.balance ?? 0);
}

async function creditMissionReward(job: JobRow) {
  const reward = await getMissionReward(job.mission_id);
  if (reward <= 0) throw new Error("Invalid mission reward");

  const before = await getWalletForUpdate(job.user_id);
  const after = before + reward;

  const { error: upsertWalletError } = await admin
    .from("wallets")
    .upsert({ user_id: job.user_id, balance: after, updated_at: new Date().toISOString() });
  if (upsertWalletError) throw upsertWalletError;

  const { error: txError } = await admin.from("coin_transactions").insert({
    user_id: job.user_id,
    delta: reward,
    balance_after: after,
    source_type: "mission_claim",
    source_id: job.mission_id,
    note: "Verified social mission reward",
    created_by: job.user_id,
    created_at: new Date().toISOString(),
  });
  if (txError) throw txError;
}

async function verifyJob(job: JobRow): Promise<{ result: VerificationResult; reason?: string }> {
  if (job.platform === "custom") {
    return { result: "manual_review", reason: "Custom platform requires manual check" };
  }

  const linked = await hasLinkedSocialAccount(job.user_id, job.platform);
  if (!linked) {
    return { result: "failed", reason: `No linked ${job.platform} account` };
  }

  // Production-ready hook point:
  // Replace below with official Facebook/YouTube API verification by target_ref + action.
  if (!ALLOW_PROOF_URL_AUTO) {
    return { result: "manual_review", reason: "Auto verification disabled" };
  }

  if (job.target_ref && /^https?:\/\//i.test(job.target_ref)) {
    return { result: "verified" };
  }
  return { result: "manual_review", reason: "Missing valid target_ref URL" };
}

async function processOneJob(job: JobRow) {
  await admin
    .from("mission_verification_jobs")
    .update({
      status: "processing",
      attempt_count: job.attempt_count + 1,
    })
    .eq("job_id", job.job_id);

  try {
    const { result, reason } = await verifyJob(job);

    if (result === "verified") {
      await creditMissionReward(job);
      await admin
        .from("mission_claims")
        .update({
          status: "approved",
          reviewed_at: new Date().toISOString(),
          review_note: "Auto-verified by worker",
        })
        .eq("claim_id", job.claim_id);
    } else if (result === "failed") {
      await admin
        .from("mission_claims")
        .update({
          status: "rejected",
          reviewed_at: new Date().toISOString(),
          review_note: reason ?? "Verification failed",
        })
        .eq("claim_id", job.claim_id);
    }

    await admin
      .from("mission_verification_jobs")
      .update({
        status: result,
        processed_at: new Date().toISOString(),
        last_error: reason ?? null,
      })
      .eq("job_id", job.job_id);
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    const nextStatus = job.attempt_count + 1 >= MAX_ATTEMPTS ? "failed" : "queued";
    await admin
      .from("mission_verification_jobs")
      .update({
        status: nextStatus,
        last_error: message,
        processed_at: new Date().toISOString(),
      })
      .eq("job_id", job.job_id);
  }
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return jsonResponse(405, { ok: false, error: "Use POST" });
  }

  const token = req.headers.get("x-cron-secret") ?? "";
  if (!CRON_SECRET || token !== CRON_SECRET) {
    return jsonResponse(401, { ok: false, error: "Unauthorized" });
  }

  const body = await req.json().catch(() => ({}));
  const limit = Math.min(Number(body?.limit ?? 20), 100);

  const { data, error } = await admin
    .from("mission_verification_jobs")
    .select("job_id, claim_id, user_id, mission_id, platform, verification_action, target_ref, status, attempt_count")
    .eq("status", "queued")
    .order("created_at", { ascending: true })
    .limit(limit);

  if (error) {
    return jsonResponse(500, { ok: false, error: error.message });
  }

  const jobs = (data ?? []) as JobRow[];
  for (const job of jobs) {
    await processOneJob(job);
  }

  return jsonResponse(200, { ok: true, processed: jobs.length });
});

