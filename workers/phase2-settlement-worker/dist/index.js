import { Queue, QueueEvents, Worker } from "bullmq";
import { Redis } from "ioredis";
import { Pool } from "pg";
import { createClient } from "@supabase/supabase-js";
import { createRequire } from "module";
import "dotenv/config";
const redisUrl = required("REDIS_URL");
const databaseUrl = required("DATABASE_URL");
const pgSslMode = (process.env.PGSSLMODE || "").toLowerCase();
const BATCH_SIZE = toInt(process.env.BATCH_SIZE, 500);
const SCHEDULE_EVERY_MS = toInt(process.env.SCHEDULE_EVERY_MS, 60_000);
const MAX_ATTEMPTS = toInt(process.env.MAX_ATTEMPTS, 5);
const WORKER_CONCURRENCY = toInt(process.env.WORKER_CONCURRENCY, 1);
const REALTIME_CHANNEL = process.env.REALTIME_PROTO_CHANNEL || "realtime/betting";
const QUEUE_NAME = "phase2-settlement-batch";
const TICK_JOB_NAME = "tick";
const TICK_JOB_ID = "phase2:settlement-batch:tick";
const require = createRequire(import.meta.url);
const liveProto = require("./generated/live_v1.js");
const EventEnvelope = liveProto.gmaing.events.v1.EventEnvelope;
const connection = new Redis(redisUrl, {
    maxRetriesPerRequest: null,
});
const pool = new Pool({
    connectionString: databaseUrl,
    ssl: databaseUrl.includes("sslmode=require") || pgSslMode === "require"
        ? { rejectUnauthorized: false }
        : false,
});
pool.on("error", (err) => {
    // Prevent process crash on transient backend disconnects.
    console.error("[phase2-worker] pg pool idle client error", err);
});
const queue = new Queue(QUEUE_NAME, { connection });
const queueEvents = new QueueEvents(QUEUE_NAME, { connection });
const supabaseUrl = process.env.SUPABASE_URL;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const supabase = supabaseUrl && serviceRoleKey
    ? createClient(supabaseUrl, serviceRoleKey, {
        auth: { persistSession: false, autoRefreshToken: false },
    })
    : null;
process.on("uncaughtException", (err) => {
    console.error("[phase2-worker] uncaughtException", err);
});
process.on("unhandledRejection", (reason) => {
    console.error("[phase2-worker] unhandledRejection", reason);
});
function required(name) {
    const value = process.env[name];
    if (!value || value.trim().length === 0) {
        throw new Error(`${name} is required`);
    }
    return value;
}
function toInt(value, fallback) {
    if (!value)
        return fallback;
    const n = Number(value);
    if (!Number.isFinite(n))
        return fallback;
    return Math.max(1, Math.floor(n));
}
async function claimPendingRows(client, limit) {
    const query = `
    WITH picked AS (
      SELECT q.queue_id
      FROM public.pending_settlements q
      WHERE q.status = 'queued'
        AND (q.next_retry_at IS NULL OR q.next_retry_at <= NOW())
      ORDER BY q.created_at ASC
      LIMIT $1
      FOR UPDATE SKIP LOCKED
    )
    UPDATE public.pending_settlements q
    SET
      status = 'processing',
      attempts = q.attempts + 1,
      updated_at = NOW()
    FROM picked p
    WHERE q.queue_id = p.queue_id
      AND q.status = 'queued'
    RETURNING q.queue_id, q.bet_id, q.user_id, q.shard_id, q.amount, q.attempts;
  `;
    const res = await client.query(query, [limit]);
    return res.rows;
}
async function applyBatchTransaction(client, rows) {
    const queueIds = rows.map((r) => r.queue_id);
    const betIds = rows.map((r) => r.bet_id);
    const amounts = rows.map((r) => r.amount);
    await client.query("BEGIN");
    try {
        // Ensure admin wallet singleton row exists.
        await client.query(`
      INSERT INTO public.admin_wallet (balance, updated_at)
      SELECT 0, NOW()
      WHERE NOT EXISTS (SELECT 1 FROM public.admin_wallet)
    `);
        // Idempotent "apply once" by bet_id.
        // Only newly inserted bet_ids contribute to admin wallet delta.
        const inserted = await client.query(`
      WITH payload AS (
        SELECT
          UNNEST($1::uuid[]) AS queue_id,
          UNNEST($2::uuid[]) AS bet_id,
          UNNEST($3::integer[]) AS amount
      ),
      ins AS (
        INSERT INTO public.admin_wallet_inflow_applied (bet_id, amount, applied_at)
        SELECT p.bet_id, p.amount, NOW()
        FROM payload p
        ON CONFLICT (bet_id) DO NOTHING
        RETURNING amount
      )
      SELECT COALESCE(SUM(amount), 0)::bigint AS amount
      FROM ins;
      `, [queueIds, betIds, amounts]);
        const adminDelta = Number(inserted.rows[0]?.amount ?? 0);
        if (adminDelta > 0) {
            await client.query(`
        UPDATE public.admin_wallet
        SET
          balance = balance + $1::bigint,
          updated_at = NOW()
        WHERE id = (
          SELECT id
          FROM public.admin_wallet
          ORDER BY updated_at DESC
          LIMIT 1
          FOR UPDATE
        )
        `, [adminDelta]);
        }
        // Mark queue rows as applied (idempotent even on retries).
        const applied = await client.query(`
      UPDATE public.pending_settlements
      SET
        status = 'applied',
        applied_at = NOW(),
        updated_at = NOW(),
        error_message = NULL
      WHERE queue_id = ANY($1::uuid[])
      `, [queueIds]);
        await client.query("COMMIT");
        return { appliedRows: applied.rowCount ?? 0, adminDelta };
    }
    catch (err) {
        await client.query("ROLLBACK");
        throw err;
    }
}
async function moveBatchToDlq(client, rows, errMessage) {
    const queueIds = rows.map((r) => r.queue_id);
    const betIds = rows.map((r) => r.bet_id);
    const userIds = rows.map((r) => r.user_id);
    const shardIds = rows.map((r) => r.shard_id);
    const amounts = rows.map((r) => r.amount);
    await client.query("BEGIN");
    try {
        await client.query(`
      WITH payload AS (
        SELECT
          UNNEST($1::uuid[]) AS queue_id,
          UNNEST($2::uuid[]) AS bet_id,
          UNNEST($3::uuid[]) AS user_id,
          UNNEST($4::integer[]) AS shard_id,
          UNNEST($5::integer[]) AS amount
      )
      INSERT INTO public.settlement_dead_letter (
        bet_id,
        user_id,
        shard_id,
        amount,
        final_error,
        failed_attempts,
        payload,
        created_at
      )
      SELECT
        p.bet_id,
        p.user_id,
        p.shard_id,
        p.amount,
        $6::text,
        1,
        jsonb_build_object('queue_id', p.queue_id, 'reason', 'batch_transaction_failed'),
        NOW()
      FROM payload p
      ON CONFLICT (bet_id) DO UPDATE
      SET
        final_error = EXCLUDED.final_error,
        failed_attempts = public.settlement_dead_letter.failed_attempts + 1,
        payload = EXCLUDED.payload,
        created_at = NOW()
      `, [queueIds, betIds, userIds, shardIds, amounts, errMessage]);
        await client.query(`
      UPDATE public.pending_settlements
      SET
        status = CASE
          WHEN attempts >= $2 THEN 'failed'
          ELSE 'queued'
        END,
        next_retry_at = CASE
          WHEN attempts >= $2 THEN NULL
          ELSE NOW() + INTERVAL '15 seconds'
        END,
        error_message = $3::text,
        updated_at = NOW()
      WHERE queue_id = ANY($1::uuid[])
      `, [queueIds, MAX_ATTEMPTS, errMessage]);
        await client.query("COMMIT");
    }
    catch (dlqErr) {
        await client.query("ROLLBACK");
        console.error("[phase2-worker] failed to move batch to DLQ", dlqErr);
        throw dlqErr;
    }
}
async function processOneTick() {
    const client = await pool.connect();
    try {
        const claimed = await claimPendingRows(client, BATCH_SIZE);
        if (claimed.length === 0) {
            console.log("[phase2-worker] no queued rows");
            return;
        }
        try {
            const result = await applyBatchTransaction(client, claimed);
            await publishSettlementApplied(result, claimed.length);
            console.log(`[phase2-worker] applied rows=${result.appliedRows}, admin_delta=${result.adminDelta}, claimed=${claimed.length}`);
        }
        catch (err) {
            const message = err instanceof Error ? err.message : String(err);
            console.error(`[phase2-worker] batch transaction failed: ${message}`);
            await moveBatchToDlq(client, claimed, message.slice(0, 1000));
        }
    }
    finally {
        client.release();
    }
}
async function publishSettlementApplied(result, claimedRows) {
    if (!supabase)
        return;
    const payloadMessage = EventEnvelope.create({
        eventId: crypto.randomUUID(),
        serverTsMs: Date.now(),
        source: "betting",
        channel: REALTIME_CHANNEL,
        seq: Date.now(),
        bettingSettlementApplied: {
            runId: crypto.randomUUID(),
            settlementId: "",
            drawId: "",
            winningDigit: 0,
            claimedRows,
            appliedRows: result.appliedRows,
            adminDelta: result.adminDelta,
            appliedAtMs: Date.now(),
        },
    });
    const bytes = EventEnvelope.encode(payloadMessage).finish();
    const dataB64 = Buffer.from(bytes).toString("base64");
    try {
        await supabase.channel(REALTIME_CHANNEL).send({
            type: "broadcast",
            event: "live_v1",
            payload: { data_b64: dataB64 },
        });
    }
    catch (err) {
        console.error("[phase2-worker] realtime publish failed", err);
    }
}
async function bootstrap() {
    await queueEvents.waitUntilReady();
    // Repeat every 60s by default (BullMQ schedule).
    await queue.add(TICK_JOB_NAME, {}, {
        jobId: TICK_JOB_ID,
        repeat: { every: SCHEDULE_EVERY_MS },
        removeOnComplete: 50,
        removeOnFail: 200,
    });
    const worker = new Worker(QUEUE_NAME, async () => {
        await processOneTick();
    }, {
        connection,
        concurrency: WORKER_CONCURRENCY,
    });
    worker.on("completed", (job) => {
        console.log(`[phase2-worker] tick completed jobId=${job.id}`);
    });
    worker.on("failed", (job, err) => {
        console.error(`[phase2-worker] tick failed jobId=${job?.id}`, err);
    });
    console.log(`[phase2-worker] started queue=${QUEUE_NAME} every=${SCHEDULE_EVERY_MS}ms batchSize=${BATCH_SIZE}`);
}
bootstrap().catch((err) => {
    console.error("[phase2-worker] fatal startup error", err);
    process.exit(1);
});
