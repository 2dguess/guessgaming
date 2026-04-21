import "dotenv/config";
import { createClient } from "@supabase/supabase-js";
import protobuf from "protobufjs";

async function main(): Promise<void> {
  const url = process.env.SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  const channel = process.env.REALTIME_PROTO_CHANNEL || "realtime/betting";

  if (!url || !key) {
    throw new Error("SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required");
  }

  const root = protobuf.loadSync("../../proto/live_v1.proto");
  const EventEnvelope = root.lookupType("gmaing.events.v1.EventEnvelope");

  const payload = {
    event_id: `smoke-${Date.now()}`,
    server_ts_ms: Date.now(),
    source: "betting",
    channel,
    seq: Date.now(),
    heartbeat: { heartbeat_seq: 1 },
  };

  const verifyErr = EventEnvelope.verify(payload);
  if (verifyErr) {
    throw new Error(`protobuf verify failed: ${verifyErr}`);
  }

  const bytes = EventEnvelope.encode(EventEnvelope.create(payload)).finish();
  const data_b64 = Buffer.from(bytes).toString("base64");

  const supabase = createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const res = await supabase
    .channel(channel)
    .httpSend("live_v1", { data_b64 }, { type: "broadcast" });

  console.log("[send-live-proto-test] channel=", channel);
  console.log("[send-live-proto-test] response=", JSON.stringify(res));
}

main().catch((err) => {
  console.error("[send-live-proto-test] error:", err?.message || err);
  process.exit(1);
});
