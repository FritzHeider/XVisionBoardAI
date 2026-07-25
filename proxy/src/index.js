// ManifestMe API proxy (Cloudflare Worker)
//
// Purpose: keep the fal.ai / Gemini / Anthropic keys OUT of the shipped app.
// The app calls this Worker; the Worker injects the provider key server-side and
// forwards. Optionally requires an App Attest assertion so a stolen proxy URL
// can't be replayed from a fake client.
//
// Routes:
//   POST /attest/challenge            -> { challenge }  (one-time, for attestKey)
//   POST /attest/verify               -> registers a device key (attestation)
//   ANY  /fal/<path>                  -> https://queue.fal.run/<path>      (+ Authorization: Key)
//   ANY  /gemini/<path>               -> https://generativelanguage.googleapis.com/<path> (+ ?key=)
//
// Provider routes carry these headers when ATTEST_MODE != "off":
//   X-Attest-Key-Id   : the DCAppAttestService key id registered via /attest/verify
//   X-Attest-Assertion: base64 assertion over SHA256(rawBody)
//
// ATTEST_MODE (wrangler.toml [vars]):
//   "off"     — no attestation; proxy relies on spend caps + Cloudflare rate limiting
//   "monitor" — validate every request and LOG pass/fail, but still forward
//               (use this to confirm the crypto works on a real device first)
//   "enforce" — reject requests that fail attestation/assertion (401)
//
// Full validation lives in appattest.js. It is written to Apple's spec but was
// NOT runtime-tested (a valid attestation needs a real device), so ship in
// "monitor" first and read the logs before switching to "enforce".

import { verifyAttestation, verifyAssertion } from "./appattest.js";

const PROVIDERS = {
  fal: {
    base: "https://queue.fal.run",
    apply: (headers, env) => headers.set("Authorization", `Key ${env.FAL_API_KEY}`),
  },
  gemini: {
    base: "https://generativelanguage.googleapis.com",
    // Gemini takes the key as a query param; handled in forward().
    apply: () => {},
  },
};

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const [, root, ...rest] = url.pathname.split("/");

    try {
      if (root === "attest" && rest[0] === "challenge") return challenge(env);
      if (root === "attest" && rest[0] === "verify") return handleAttestVerify(request, env);
      if (PROVIDERS[root]) return forward(root, rest.join("/"), url.search, request, env);
      return json({ error: "not found" }, 404);
    } catch (err) {
      return json({ error: String(err && err.message || err) }, 500);
    }
  },
};

// --- Provider forwarding (the actual key-injection fix) ---

async function forward(providerName, path, search, request, env) {
  const provider = PROVIDERS[providerName];

  const bodyBuf = request.method === "GET" || request.method === "HEAD"
    ? null
    : await request.arrayBuffer();
  const body = bodyBuf ? new Uint8Array(bodyBuf) : new Uint8Array(0);

  const mode = env.ATTEST_MODE || "off";
  if (mode !== "off") {
    const keyId = request.headers.get("X-Attest-Key-Id");
    const assertion = request.headers.get("X-Attest-Assertion");
    let ok = false, reason = "missing attestation headers";
    if (keyId && assertion) {
      try {
        await verifyAssertion({ keyIdB64: keyId, assertionB64: assertion, body, env });
        ok = true;
      } catch (e) { reason = e.message; }
    }
    if (ok) {
      console.log(`[attest] ok key=${keyId?.slice(0, 12)}… ${providerName}/${path}`);
    } else {
      console.warn(`[attest] FAIL (${reason}) key=${keyId?.slice(0, 12)}… ${providerName}/${path}`);
      if (mode === "enforce") return json({ error: "attestation required" }, 401);
    }
  }

  let target = `${provider.base}/${path}`;
  const params = new URLSearchParams(search);
  if (providerName === "gemini") params.set("key", env.GEMINI_API_KEY);
  const qs = params.toString();
  if (qs) target += `?${qs}`;

  const headers = new Headers(request.headers);
  // Never forward client-side auth or attestation headers upstream.
  headers.delete("Authorization");
  headers.delete("x-api-key");
  headers.delete("X-Attest-Key-Id");
  headers.delete("X-Attest-Assertion");
  headers.delete("host");
  provider.apply(headers, env);

  const upstream = await fetch(target, {
    method: request.method,
    headers,
    body: bodyBuf, // null for GET/HEAD; original bytes otherwise
  });

  // Stream the provider response straight back.
  return new Response(upstream.body, {
    status: upstream.status,
    headers: upstream.headers,
  });
}

// --- App Attest ---

async function challenge(env) {
  const bytes = crypto.getRandomValues(new Uint8Array(32));
  const challenge = b64(bytes);
  // One-time, short-lived. Keyed by its own value; consumed on verify.
  await env.ATTEST_KV.put(`challenge:${challenge}`, "1", { expirationTtl: 300 });
  return json({ challenge });
}

async function handleAttestVerify(request, env) {
  const { keyId, attestation, challenge } = await request.json();
  if (!keyId || !attestation || !challenge) return json({ error: "missing fields" }, 400);

  const seen = await env.ATTEST_KV.get(`challenge:${challenge}`);
  if (!seen) return json({ error: "unknown or expired challenge" }, 400);
  await env.ATTEST_KV.delete(`challenge:${challenge}`);

  const challengeBytes = b64decode(challenge);
  try {
    const info = await verifyAttestation({ keyIdB64: keyId, attestationB64: attestation, challengeBytes, env });
    console.log(`[attest] registered key=${keyId.slice(0, 12)}… env=${info.environment}`);
    return json({ ok: true, environment: info.environment });
  } catch (e) {
    console.warn(`[attest] verify FAILED key=${keyId.slice(0, 12)}…: ${e.message}`);
    return json({ error: "attestation failed", detail: e.message }, 400);
  }
}

// --- helpers ---

function b64decode(s) {
  const bin = atob(s);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

function json(obj, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { "content-type": "application/json" },
  });
}

function b64(bytes) {
  let s = "";
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s);
}
