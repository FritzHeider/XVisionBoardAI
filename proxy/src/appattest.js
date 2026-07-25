// Apple App Attest server-side validation for Cloudflare Workers.
//
// Implements the flow from Apple's "Validating Apps That Connect to Your Server"
// and the axiom-security app-attest guidance:
//   - Attestation (once per key): verify cert chain to Apple's root, recompute
//     the nonce, check the app-id hash, check counter == 0, store the public key.
//   - Assertion (per request): verify the ECDSA signature with the stored key,
//     check the app-id hash, and require a strictly increasing counter.
//
// ⚠️ UNTESTED IN THIS ENVIRONMENT. A real attestation can only be produced by a
// physical iOS device running the real app, so this code was written to spec but
// not executed. Run it in ATTEST_MODE="monitor" and confirm the logs show
// attestation + assertions passing on a real device BEFORE switching to
// "enforce". The two most likely spots to need a tweak are flagged inline:
//   [RISK-1] the nonce OID extension slice, and
//   [RISK-2] the assertion signature message/hashing.

import * as x509 from "@peculiar/x509";

// Apple App Attest Root CA (G1). VERIFY this against Apple's official copy at
// https://www.apple.com/certificateauthority/private/ before trusting it — an
// incorrect root makes every attestation fail (visible in monitor-mode logs).
const APPLE_APP_ATTEST_ROOT_CA = `-----BEGIN CERTIFICATE-----
MIICITCCAaegAwIBAgIQC/O+DvHN0uD7jG5yH2IXmDAKBggqhkjOPQQDAzBSMSYw
JAYDVQQDDB1BcHBsZSBBcHAgQXR0ZXN0YXRpb24gUm9vdCBDQTETMBEGA1UECgwK
QXBwbGUgSW5jLjETMBEGA1UECAwKQ2FsaWZvcm5pYTAeFw0yMDAzMTgxODMyNTNa
Fw00NTAzMTUwMDAwMDBaMFIxJjAkBgNVBAMMHUFwcGxlIEFwcCBBdHRlc3RhdGlv
biBSb290IENBMRMwEQYDVQQKDApBcHBsZSBJbmMuMRMwEQYDVQQIDApDYWxpZm9y
bmlhMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAERTHhmLW07ATaFQIEVwTtT4dyctdh
NbJhFs/Ii2FdCgAHGbpphY3+d8qjuDngIN3WVhQUBHAoMeQ/cLiP1sOUtgjqK9au
Yen1mMEvRq9Sk3Jm5X8U62H+xTD3FE9TgS41o0IwQDAPBgNVHRMBAf8EBTADAQH/
MB0GA1UdDgQWBBSskRBTM72+aEH/pwyp5frq5eWKoTAOBgNVHQ8BAf8EBAMCAQYw
CgYIKoZIzj0EAwMDaAAwZQIwQgFGnByvsiVbpTKwSga0kP0e8EeDS4+sQmTvb7vn
53O5+FRXgeLhpJ06ysC5PrOyAjEA3QdpV9wexc9fjnnZ2gdlNsjBoNmC8DYr6r5G
+H8i1S6b4KwAOFxbYcRWQVzUxoxN
-----END CERTIFICATE-----`;

const NONCE_OID = "1.2.840.113635.100.8.2";

// --- small helpers ---

async function sha256(bytes) {
  return new Uint8Array(await crypto.subtle.digest("SHA-256", bytes));
}

function concat(...arrs) {
  const total = arrs.reduce((n, a) => n + a.length, 0);
  const out = new Uint8Array(total);
  let o = 0;
  for (const a of arrs) { out.set(a, o); o += a.length; }
  return out;
}

function eq(a, b) {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a[i] ^ b[i];
  return diff === 0;
}

function b64decode(s) {
  const bin = atob(s);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

function b64encode(bytes) {
  let s = "";
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s);
}

// --- minimal CBOR decoder (only the major types App Attest uses) ---

function cborDecode(bytes) {
  let o = 0;
  const dv = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);

  function readLen(ai) {
    if (ai < 24) return ai;
    if (ai === 24) return bytes[o++];
    if (ai === 25) { const v = dv.getUint16(o); o += 2; return v; }
    if (ai === 26) { const v = dv.getUint32(o); o += 4; return v; }
    if (ai === 27) { const v = Number(dv.getBigUint64(o)); o += 8; return v; }
    throw new Error("cbor: unsupported length " + ai);
  }

  function readItem() {
    const b = bytes[o++];
    const major = b >> 5;
    const ai = b & 0x1f;
    switch (major) {
      case 0: return readLen(ai);                       // unsigned int
      case 2: { const n = readLen(ai); const v = bytes.slice(o, o + n); o += n; return v; } // byte string
      case 3: { const n = readLen(ai); const v = new TextDecoder().decode(bytes.slice(o, o + n)); o += n; return v; } // text
      case 4: { const n = readLen(ai); const arr = []; for (let i = 0; i < n; i++) arr.push(readItem()); return arr; } // array
      case 5: { const n = readLen(ai); const m = {}; for (let i = 0; i < n; i++) { const k = readItem(); m[k] = readItem(); } return m; } // map
      case 7: { if (ai === 20) return false; if (ai === 21) return true; if (ai === 22) return null; throw new Error("cbor: unsupported simple " + ai); }
      default: throw new Error("cbor: unsupported major " + major);
    }
  }
  return readItem();
}

// authData layout (attestation includes attested credential data):
//   rpIdHash(32) | flags(1) | signCount(4) | aaguid(16) | credIdLen(2) | credId(..)
function parseAuthData(authData) {
  const dv = new DataView(authData.buffer, authData.byteOffset, authData.byteLength);
  const rpIdHash = authData.slice(0, 32);
  const counter = dv.getUint32(33);
  const aaguid = authData.slice(37, 53);
  const credIdLen = dv.getUint16(53);
  const credId = authData.slice(55, 55 + credIdLen);
  return { rpIdHash, counter, aaguid, credId };
}

// DER-encoded ECDSA signature -> raw r||s (P-256, 64 bytes) for WebCrypto verify.
function derSigToRaw(der) {
  let o = 0;
  if (der[o++] !== 0x30) throw new Error("sig: no SEQUENCE");
  if (der[o] & 0x80) o += 1 + (der[o] & 0x7f); else o += 1; // skip seq length
  function readInt() {
    if (der[o++] !== 0x02) throw new Error("sig: no INTEGER");
    let len = der[o++];
    let v = der.slice(o, o + len); o += len;
    while (v.length > 32 && v[0] === 0x00) v = v.slice(1); // strip leading zero
    const out = new Uint8Array(32);
    out.set(v, 32 - v.length); // left-pad to 32
    return out;
  }
  const r = readInt();
  const s = readInt();
  return concat(r, s);
}

async function appIdHash(env) {
  return sha256(new TextEncoder().encode(`${env.APP_TEAM_ID}.${env.APP_BUNDLE_ID}`));
}

// --- attestation (once per key) ---

export async function verifyAttestation({ keyIdB64, attestationB64, challengeBytes, env }) {
  x509.cryptoProvider.set(crypto);

  const att = cborDecode(b64decode(attestationB64));
  if (att.fmt !== "apple-appattest") throw new Error("bad fmt: " + att.fmt);
  const x5c = att.attStmt.x5c;           // [leafDER, intermediateDER]
  const authData = att.authData;

  // 1. Certificate chain: leaf <- intermediate <- Apple root
  const leaf = new x509.X509Certificate(new Uint8Array(x5c[0]));
  const intermediate = new x509.X509Certificate(new Uint8Array(x5c[1]));
  const root = new x509.X509Certificate(APPLE_APP_ATTEST_ROOT_CA);
  const now = new Date();
  const leafOk = await leaf.verify({ publicKey: intermediate.publicKey, date: now });
  const interOk = await intermediate.verify({ publicKey: root.publicKey, date: now });
  if (!leafOk || !interOk) throw new Error("cert chain verification failed");

  // 2. Nonce: SHA256(authData || clientDataHash), clientDataHash = SHA256(challenge)
  const clientDataHash = await sha256(challengeBytes);
  const expectedNonce = await sha256(concat(authData, clientDataHash));
  // [RISK-1] The nonce lives in the OID 1.2.840.113635.100.8.2 extension as
  // SEQUENCE { [1] { OCTET STRING nonce } }; the nonce is its final 32 bytes.
  const ext = leaf.getExtension(NONCE_OID);
  if (!ext) throw new Error("nonce extension missing");
  const extBytes = new Uint8Array(ext.value);
  const certNonce = extBytes.slice(extBytes.length - 32);
  if (!eq(expectedNonce, certNonce)) throw new Error("nonce mismatch");

  // 3. Public key hash == credId == keyId
  const spki = new Uint8Array(leaf.publicKey.rawData);
  const ecKey = await crypto.subtle.importKey("spki", spki, { name: "ECDSA", namedCurve: "P-256" }, true, ["verify"]);
  const rawPoint = new Uint8Array(await crypto.subtle.exportKey("raw", ecKey)); // 65-byte uncompressed point
  const pubKeyHash = await sha256(rawPoint);
  const { rpIdHash, counter, aaguid, credId } = parseAuthData(authData);
  if (!eq(pubKeyHash, credId)) throw new Error("public key hash != credId");
  if (!eq(pubKeyHash, b64decode(keyIdB64))) throw new Error("public key hash != keyId");

  // 4. App-id hash
  if (!eq(rpIdHash, await appIdHash(env))) throw new Error("app-id (rpIdHash) mismatch");

  // 5. Counter must start at 0
  if (counter !== 0) throw new Error("initial counter != 0");

  // aaguid: "appattestdevelop" on dev builds, "appattest\0..\0" in production.
  const aaguidStr = new TextDecoder().decode(aaguid).replace(/\0+$/, "");
  if (aaguidStr !== "appattest" && aaguidStr !== "appattestdevelop") {
    throw new Error("unexpected aaguid: " + aaguidStr);
  }

  // Store the SPKI public key + counter for future assertions.
  await env.ATTEST_KV.put(`pubkey:${keyIdB64}`, b64encode(spki));
  await env.ATTEST_KV.put(`counter:${keyIdB64}`, "0");
  return { environment: aaguidStr === "appattest" ? "production" : "development" };
}

// --- assertion (per request) ---

export async function verifyAssertion({ keyIdB64, assertionB64, body, env }) {
  const spkiB64 = await env.ATTEST_KV.get(`pubkey:${keyIdB64}`);
  if (!spkiB64) throw new Error("unknown key id (never attested)");

  const assertion = cborDecode(b64decode(assertionB64));
  const signature = assertion.signature;           // DER ECDSA
  const authData = assertion.authenticatorData;    // rpIdHash(32)|flags(1)|counter(4)

  // App-id hash
  const rpIdHash = authData.slice(0, 32);
  if (!eq(rpIdHash, await appIdHash(env))) throw new Error("assertion app-id mismatch");

  // [RISK-2] Signature is over SHA256(authenticatorData || clientDataHash), where
  // clientDataHash = SHA256(body). WebCrypto (hash: SHA-256) hashes the message we
  // pass, so pass (authenticatorData || clientDataHash) — NOT the pre-hashed nonce.
  const clientDataHash = await sha256(body);
  const message = concat(authData, clientDataHash);
  const rawSig = derSigToRaw(signature);
  const spki = b64decode(spkiB64);
  const key = await crypto.subtle.importKey("spki", spki, { name: "ECDSA", namedCurve: "P-256" }, false, ["verify"]);
  const sigOk = await crypto.subtle.verify({ name: "ECDSA", hash: "SHA-256" }, key, rawSig, message);
  if (!sigOk) throw new Error("assertion signature invalid");

  // Counter strictly increasing (replay protection)
  const dv = new DataView(authData.buffer, authData.byteOffset, authData.byteLength);
  const counter = dv.getUint32(33);
  const prev = parseInt((await env.ATTEST_KV.get(`counter:${keyIdB64}`)) ?? "0", 10);
  if (counter <= prev) throw new Error(`counter not increasing (${counter} <= ${prev})`);
  await env.ATTEST_KV.put(`counter:${keyIdB64}`, String(counter));
  return true;
}
