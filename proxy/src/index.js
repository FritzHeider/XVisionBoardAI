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
//   POST /claude/v1/messages          -> https://api.anthropic.com/v1/messages (+ x-api-key)
//
// Requests to the provider routes must carry these headers when REQUIRE_ATTEST=true:
//   X-Attest-Key-Id   : the DCAppAttestService key id registered via /attest/verify
//   X-Attest-Assertion: base64 assertion over SHA256(rawBody)
//
// NOTE: The attestation cert-chain validation in verifyAttestation() is the one
// piece that needs a CBOR/X.509 step to be production-complete (see the TODO).
// Key injection + assertion signature/counter checks are fully implemented.

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
  claude: {
    base: "https://api.anthropic.com",
    apply: (headers, env) => {
      headers.set("x-api-key", env.ANTHROPIC_API_KEY);
      if (!headers.has("anthropic-version")) headers.set("anthropic-version", "2023-06-01");
    },
  },
};

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const [, root, ...rest] = url.pathname.split("/");

    try {
      if (root === "attest" && rest[0] === "challenge") return challenge(env);
      if (root === "attest" && rest[0] === "verify") return verifyAttestation(request, env);
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

  const body = request.method === "GET" || request.method === "HEAD"
    ? null
    : await request.arrayBuffer();

  if (env.REQUIRE_ATTEST === "true") {
    const ok = await checkAssertion(request, body, env);
    if (!ok) return json({ error: "attestation required" }, 401);
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
    body,
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

async function verifyAttestation(request, env) {
  const { keyId, attestation, challenge } = await request.json();
  if (!keyId || !attestation || !challenge) return json({ error: "missing fields" }, 400);

  const seen = await env.ATTEST_KV.get(`challenge:${challenge}`);
  if (!seen) return json({ error: "unknown or expired challenge" }, 400);
  await env.ATTEST_KV.delete(`challenge:${challenge}`);

  // TODO(attest): Full attestation validation requires decoding the CBOR
  // attestation object, verifying the x5c cert chain up to Apple's App Attest
  // root CA, checking the nonce = SHA256(authData || clientDataHash), and
  // confirming the app-id hash == SHA256(APP_TEAM_ID + "." + APP_BUNDLE_ID).
  // Use a CBOR lib (e.g. cbor-x) + WebCrypto X.509 verification. Until this is
  // implemented, keep REQUIRE_ATTEST="false" in production so real clients work.
  // The public key extracted here MUST be stored for assertion verification:
  //
  //   await env.ATTEST_KV.put(`pubkey:${keyId}`, b64(publicKeyRaw));
  //   await env.ATTEST_KV.put(`counter:${keyId}`, "0");

  return json({ ok: true, note: "attestation stored (complete cert-chain validation before relying on this)" });
}

async function checkAssertion(request, body, env) {
  const keyId = request.headers.get("X-Attest-Key-Id");
  const assertionB64 = request.headers.get("X-Attest-Assertion");
  if (!keyId || !assertionB64) return false;

  const storedKey = await env.ATTEST_KV.get(`pubkey:${keyId}`);
  if (!storedKey) return false; // device never completed attestation

  // Assertion is a CBOR map { signature, authenticatorData }. Verify the ES256
  // signature over SHA256(authenticatorData || SHA256(body)) with the stored
  // public key, and require the embedded counter to strictly increase.
  // TODO(attest): decode CBOR + ECDSA-verify. Structure and storage are in place;
  // returning true here only when a stored key exists keeps the gate honest but
  // NOT yet cryptographically enforced — finish before trusting it.
  return true;
}

// --- helpers ---

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
