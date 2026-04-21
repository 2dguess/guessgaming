## Mission Verifier Worker

Processes `mission_verification_jobs` queue and finalizes mission claims.

### Deploy

```bash
supabase functions deploy mission-verifier --no-verify-jwt
```

### Required env vars

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `MISSION_VERIFIER_CRON_SECRET` (shared secret for scheduler requests)
- `MISSION_VERIFIER_MAX_ATTEMPTS` (optional, default `5`)
- `MISSION_VERIFIER_ALLOW_PROOF_URL_AUTO` (optional, default `false`)

### Trigger format (scheduler / cron)

`POST /functions/v1/mission-verifier`

Headers:

- `x-cron-secret: <MISSION_VERIFIER_CRON_SECRET>`
- `content-type: application/json`

Body:

```json
{
  "limit": 20
}
```

### Current verification policy

- `facebook` / `youtube`:
  - user must have linked social account in `user_social_accounts`.
  - if `MISSION_VERIFIER_ALLOW_PROOF_URL_AUTO=false`: mark `manual_review`.
  - if `true`: URL-shaped `target_ref` is treated as verified (placeholder mode).
- `custom`: always `manual_review`.

### Production hardening checklist

1. Replace placeholder verification with official platform APIs:
   - Facebook Graph API (page follow/like/comment/share checks)
   - YouTube Data API (like/comment/subscription/view checks where available)
2. Store and rotate OAuth tokens securely.
3. Add anti-replay validation per claim/proof.
4. Add metrics + alerting for failed jobs.
5. Add dead-letter workflow for repeated failures.

