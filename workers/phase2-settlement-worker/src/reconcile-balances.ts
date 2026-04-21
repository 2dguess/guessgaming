import "dotenv/config";
import { Redis } from "ioredis";
import { Pool } from "pg";

const redisUrl = process.env.REDIS_URL;
const databaseUrl = process.env.DATABASE_URL;
const sampleLimit = Number(process.env.RECON_SAMPLE_LIMIT || "500");
const pgSslMode = (process.env.PGSSLMODE || "").toLowerCase();

if (!redisUrl || !databaseUrl) {
  throw new Error("REDIS_URL and DATABASE_URL are required");
}

const redis = new Redis(redisUrl, { maxRetriesPerRequest: null });
const pool = new Pool({
  connectionString: databaseUrl,
  ssl:
    databaseUrl.includes("sslmode=require") || pgSslMode === "require"
      ? { rejectUnauthorized: false }
      : false,
});

function redisKey(userId: string): string {
  return `wallet:balance:${userId}`;
}

async function run(): Promise<void> {
  const client = await pool.connect();
  try {
    const users = await client.query<{
      user_id: string;
      pg_balance: string;
    }>(
      `
      SELECT
        w.user_id::text AS user_id,
        (COALESCE(w.available_balance, 0)::bigint + COALESCE(w.locked_balance, 0)::bigint)::text AS pg_balance
      FROM public.wallets w
      ORDER BY w.updated_at DESC
      LIMIT $1
      `,
      [sampleLimit]
    );

    let mismatches = 0;
    for (const row of users.rows) {
      const key = redisKey(row.user_id);
      const redisRaw = await redis.get(key);
      const redisBalance = Number(redisRaw ?? "0");
      const pgBalance = Number(row.pg_balance);
      const delta = pgBalance - redisBalance;

      if (delta !== 0) {
        mismatches += 1;
        await client.query(
          `
          INSERT INTO public.balance_reconciliation_logs (
            user_id,
            pg_balance,
            redis_balance,
            delta,
            checked_at,
            note
          ) VALUES ($1::uuid, $2::bigint, $3::bigint, $4::bigint, NOW(), $5::text)
          `,
          [row.user_id, pgBalance, redisBalance, delta, "redis vs postgres mismatch"]
        );
      }
    }

    console.log(
      `[reconcile-balances] scanned=${users.rows.length} mismatches=${mismatches}`
    );
  } finally {
    client.release();
    await pool.end();
    await redis.quit();
  }
}

run().catch((err) => {
  console.error("[reconcile-balances] fatal error", err);
  process.exit(1);
});

