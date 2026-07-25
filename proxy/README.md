# ManifestMe API Proxy

A Cloudflare Worker that keeps the fal.ai / Gemini keys **out of the shipped iOS
app**. The app calls this Worker; the Worker injects the provider key server-side
and forwards the request. Optionally gated by App Attest so a leaked proxy URL
can't be driven from a fake client.

## Why

Today both provider keys are compiled into the app (`Info.plist` ←
`Secrets.xcconfig`) and read client-side. Anyone can unzip the IPA or proxy the
traffic and extract them. Moving the keys behind this Worker is the only real fix.

## What's implemented vs. what you must verify

- ✅ **Key injection / forwarding** — complete and safe to deploy. This alone
  removes the keys from the app.
- ✅ **App Attest server validation** — fully implemented in `appattest.js`
  (cert chain to Apple's root, nonce, app-id hash, counter, ECDSA assertion
  verification). It bundles and parses cleanly, but the **crypto was written to
  Apple's spec and NOT runtime-tested** — a valid attestation can only be
  produced by a physical device. So it ships in `ATTEST_MODE="monitor"`:
  it validates and logs every request but still forwards. Confirm the logs show
  passing attestation + assertions on a real device, then switch to `"enforce"`.

## App Attest verification checklist (do before `enforce`)

1. Deploy with `ATTEST_MODE = "monitor"` and `APP_TEAM_ID` set.
2. Confirm the embedded Apple root CA in `appattest.js` matches Apple's official
   copy at <https://www.apple.com/certificateauthority/private/>.
3. Run the app on a **real device** (App Attest doesn't work in Simulator) with
   `APIConfig.proxyBaseURL` set. Trigger a generation.
4. Tail the Worker logs: `npx wrangler tail`. You want to see
   `[attest] registered …` once and `[attest] ok …` on each request. If you see
   `[attest] FAIL (…)`, the reason names the failing check — the two most
   likely are `nonce mismatch` (RISK-1: the OID extension slice) and
   `assertion signature invalid` (RISK-2: the signature message/hashing).
5. Once logs are consistently green, set `ATTEST_MODE = "enforce"` and redeploy.

## Deploy

```bash
npm install -g wrangler
cd proxy && npm install

# 1. Create the KV namespace and paste the returned id into wrangler.toml
wrangler kv namespace create ATTEST_KV

# 2. Set the two provider keys as secrets (never committed)
wrangler secret put FAL_API_KEY
wrangler secret put GEMINI_API_KEY

# 3. Fill APP_TEAM_ID in wrangler.toml with your Apple Developer Team ID
#    (and keep ATTEST_MODE = "monitor" for the first deploy)
# 4. Deploy
wrangler deploy
```

`wrangler deploy` prints a `https://manifestme-proxy.<subdomain>.workers.dev` URL.

## Wire up the app

1. Set `APIConfig.proxyBaseURL` (in `Services/APIConfig.swift`) to that URL.
2. `FalAIService` already routes through the proxy when it's set (reference
   integration). Apply the same pattern to `GeminiImageService` and
   `GeminiTextService`: swap the direct base host for
   `APIConfig.url(provider:directURL:proxyPath:)` and attach
   `AppAttestManager.shared.assertionHeaders(for:)` instead of the client key.
3. Call `await AppAttestManager.shared.prepare()` once at launch (after login).
4. Remove the `FAL_API_KEY` / `GEMINI_API_KEY` entries from `Info.plist`, and
   **rotate** the old fal + Gemini keys (they shipped in builds).

## Interim (before the proxy is live)

Keep `proxyBaseURL = nil` (direct mode) so TestFlight works, and set **hard spend
caps + rate limits** at fal.ai and Google AI Studio now.

## Endpoints

| Route | Forwards to | Injects |
|---|---|---|
| `POST /attest/challenge` | — | issues one-time nonce |
| `POST /attest/verify` | — | registers a device key |
| `ANY /fal/<path>` | `https://queue.fal.run/<path>` | `Authorization: Key …` |
| `ANY /gemini/<path>` | `https://generativelanguage.googleapis.com/<path>` | `?key=…` |
