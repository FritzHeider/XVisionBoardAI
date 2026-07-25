# ManifestMe API Proxy

A Cloudflare Worker that keeps the fal.ai / Gemini / Anthropic keys **out of the
shipped iOS app**. The app calls this Worker; the Worker injects the provider key
server-side and forwards the request. Optionally gated by App Attest so a leaked
proxy URL can't be driven from a fake client.

## Why

Today the three provider keys are compiled into the app (`Info.plist` ←
`Secrets.xcconfig`) and read client-side. Anyone can unzip the IPA or proxy the
traffic and extract them. Moving the keys behind this Worker is the only real fix.

## What's implemented vs. what you must finish

- ✅ **Key injection / forwarding** — complete and safe to deploy. This alone
  removes the keys from the app.
- ⚠️ **App Attest server validation** — structured but intentionally not
  cryptographically enforced yet (see the two `TODO(attest)` blocks in
  `src/index.js`). Keep `REQUIRE_ATTEST="false"` until you finish the CBOR +
  X.509 cert-chain validation, or real clients will be rejected.

## Deploy

```bash
npm install -g wrangler
cd proxy && npm install

# 1. Create the KV namespace and paste the returned id into wrangler.toml
wrangler kv namespace create ATTEST_KV

# 2. Set the three provider keys as secrets (never committed)
wrangler secret put FAL_API_KEY
wrangler secret put GEMINI_API_KEY
wrangler secret put ANTHROPIC_API_KEY

# 3. Fill APP_TEAM_ID in wrangler.toml with your Apple Developer Team ID
# 4. Deploy
wrangler deploy
```

`wrangler deploy` prints a `https://manifestme-proxy.<subdomain>.workers.dev` URL.

## Wire up the app

1. Set `APIConfig.proxyBaseURL` (in `Services/APIConfig.swift`) to that URL.
2. `FalAIService` already routes through the proxy when it's set (reference
   integration). Apply the same pattern to `GeminiImageService` and
   `ClaudeAPIService`: swap the direct base host for
   `APIConfig.url(provider:directURL:proxyPath:)` and attach
   `AppAttestManager.shared.assertionHeaders(for:)` instead of the client key.
3. Call `await AppAttestManager.shared.prepare()` once at launch (after login).
4. Remove the `ANTHROPIC_API_KEY` / `FAL_API_KEY` / `GEMINI_API_KEY` entries from
   `Info.plist`, and **rotate** the old fal + Gemini keys (they shipped in builds).

## Interim (before the proxy is live)

Keep `proxyBaseURL = nil` (direct mode) so TestFlight works, and set **hard spend
caps + rate limits** at Anthropic, fal.ai, and Google AI Studio now.

## Endpoints

| Route | Forwards to | Injects |
|---|---|---|
| `POST /attest/challenge` | — | issues one-time nonce |
| `POST /attest/verify` | — | registers a device key |
| `ANY /fal/<path>` | `https://queue.fal.run/<path>` | `Authorization: Key …` |
| `ANY /gemini/<path>` | `https://generativelanguage.googleapis.com/<path>` | `?key=…` |
| `POST /claude/v1/messages` | `https://api.anthropic.com/v1/messages` | `x-api-key` |
