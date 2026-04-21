# Play Store Policy Checklist (English)

This checklist helps you prepare a virtual-score entertainment app for Google Play and reduce rejection risk.

## 1) Product Positioning

- Do not use wording like `real money`, `cashout`, `withdraw`, or `earn cash` in app text, screenshots, or store listing copy.
- Keep this disclosure consistent across key surfaces:
  - Home/play screen
  - Dialogs and critical action screens
  - Store listing description
- Recommended disclosure text:
  - `Entertainment only. Score is virtual and has no cash value.`

## 2) No Real-Money Flow

- Scores/coins must not be redeemable for money, bank transfer, gift cards, crypto, or any transferable financial value.
- Keep reward language framed as virtual value only.
- Referral/invite rewards should also remain non-cash and non-transferable.

## 3) Age, Content, and Metadata

- Complete the content rating questionnaire carefully to avoid real-gambling implications.
- Add age-gating if your UI resembles betting mechanics.
- Ensure Privacy Policy and Terms links are live and reachable.

## 4) In-App Wording (Safe Defaults)

- `Bet` -> `Pick` or `Prediction`
- `Bet failed` -> `Prediction failed`
- `Payout` -> `Score allocation` or `Virtual score update`
- `Wallet` -> `Score balance` (optional but recommended)

## 5) Compliance Technical Checks

- Never log sensitive keys/tokens in app logs or alerts.
- Do not commit secret files (such as `.env`) to the repository.
- Keep debug-only panels (metrics/debug cards) disabled in release builds.

## 6) Release Gate (Before Upload)

- [ ] Store listing has no real-money/cash wording
- [ ] Screenshots do not imply real-money rewards
- [ ] Virtual-only disclosure appears in at least 2 places
- [ ] Privacy Policy URL is valid
- [ ] Terms URL is valid
- [ ] Debug UI is disabled in release
- [ ] Secret leakage scan is completed

## 7) If Google asks for clarification

You can use this response template:

`This app is an entertainment-only virtual score app. Users cannot cash out, withdraw, or convert scores into money, financial instruments, gift cards, or transferable assets. The app includes clear in-app disclosures that scores have no cash value.`

