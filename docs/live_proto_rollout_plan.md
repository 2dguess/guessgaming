# Live Protobuf Rollout Plan (Social + Live + Betting)

This plan is aligned with the current project structure:

- Flutter app root: `pubspec.yaml`
- Worker service: `workers/phase2-settlement-worker/`
- New proto schema: `proto/live_v1.proto`

## 1) Objectives

- Use one transport schema for social/live/betting realtime updates.
- Reduce payload size and parsing cost for high user traffic.
- Keep rollout safe with backward compatibility.

## 2) Event Model

Schema file: `proto/live_v1.proto`

- Envelope: `EventEnvelope`
- Social events:
  - `SocialPostCreated`
  - `SocialGiftSent`
- Live events:
  - `LiveDrawStateUpdated`
  - `LiveOddsUpdated`
- Betting events:
  - `BettingBetPlaced`
  - `BettingSettlementApplied`
- Common:
  - `SystemNotice`
  - `Heartbeat`

## 3) Compatibility Rules (Production Critical)

- Never change existing field numbers.
- Never delete old fields; deprecate and stop using them.
- Add new fields with new field numbers only.
- Keep old JSON path as fallback during migration window.

## 4) Codegen Setup

### Flutter side

1. Add dependencies in `pubspec.yaml`:
   - `protobuf`
   - `fixnum`
   - dev dependency: `protoc_plugin`
2. Generate Dart files from `proto/live_v1.proto`.
3. Wire decoder in live/social/betting state controllers.

### Node side (service/worker)

Use either:

- `protobufjs` runtime loading, or
- pre-generated JS/TS types via `protobufjs-cli` or `ts-proto`.

Recommended first step: runtime loading for faster initial integration.

## 5) Delivery Flow

1. Server publishes `EventEnvelope` (binary) to realtime channel.
2. Client subscribes by channel:
   - `realtime/social`
   - `realtime/live`
   - `realtime/betting`
3. Client dispatches by `payload` oneof type.

## 6) Rollout Stages

1. **Stage A (dual format)**: publish JSON + Protobuf in parallel.
2. **Stage B (beta group)**: selected clients consume Protobuf only.
3. **Stage C (full cutover)**: Protobuf default, JSON fallback retained.
4. **Stage D (cleanup)**: remove JSON fallback after stable window.

## 7) Monitoring During Rollout

- Decode failure count
- Event lag (server_ts_ms vs client receive time)
- Reconnect rate
- Payload size reduction
- Result delivery SLA (target <= 5 seconds)

## 8) Fail-safe Rollback

- Keep JSON publisher enabled until Protobuf error rate is near zero.
- Feature flag:
  - `useProtoLiveEvents = true/false`
- If decode failures spike, switch clients back to JSON immediately.

## 9) Tomorrow Execution Checklist (Non-coder Friendly)

1. Confirm schema exists: `proto/live_v1.proto`
2. Install protobuf compiler (`protoc`) on build machine.
3. Generate Flutter code.
4. Generate or load Node schema.
5. Start with Live-only channel in beta.
6. Expand to Social and Betting events.
7. Track SLA and errors for 24 hours before full rollout.
