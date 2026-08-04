#!/usr/bin/env python3
"""Upload the App Review screenshot for each ManifestMe subscription.

All three subscriptions sat in MISSING_METADATA because their review screenshots
were either absent or stuck in assetDeliveryState=FAILED (a reservation that was
created but whose bytes never landed). Apple will not clear MISSING_METADATA
until each product has a screenshot that has actually been delivered.

The upload is a four-step dance: reserve -> PUT the bytes to each returned
upload operation -> PATCH uploaded=true with an md5 -> poll until the asset
delivery state settles.

Env vars match asc_metadata.py. Usage:
    python3 scripts/asc_iap_screenshots.py <path-to-png>
"""

import hashlib
import json
import os
import sys
import time
import urllib.error
import urllib.request

import jwt

BASE = "https://api.appstoreconnect.apple.com"
APP_ID = "6751253658"


def token() -> str:
    with open(os.path.expanduser(os.environ["ASC_KEY_PATH"])) as fh:
        key = fh.read()
    now = int(time.time())
    return jwt.encode(
        {
            "iss": os.environ["ASC_ISSUER_ID"],
            "iat": now,
            "exp": now + 900,
            "aud": "appstoreconnect-v1",
        },
        key,
        algorithm="ES256",
        headers={"kid": os.environ["ASC_KEY_ID"], "typ": "JWT"},
    )


def call(method: str, path: str, body: dict | None = None) -> dict:
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(
        path if path.startswith("http") else BASE + path, data=data, method=method
    )
    req.add_header("Authorization", f"Bearer {token()}")
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as resp:
            raw = resp.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as exc:
        return {"_err": exc.code, "_detail": exc.read().decode(errors="replace")[:400]}


def put_bytes(op: dict, blob: bytes) -> None:
    chunk = blob[op["offset"] : op["offset"] + op["length"]]
    req = urllib.request.Request(op["url"], data=chunk, method=op["method"])
    for header in op.get("requestHeaders", []):
        req.add_header(header["name"], header["value"])
    with urllib.request.urlopen(req) as resp:
        if resp.status not in (200, 201, 204):
            raise RuntimeError(f"upload chunk failed: HTTP {resp.status}")


def upload_for(sub_id: str, product: str, blob: bytes, filename: str) -> None:
    existing = call("GET", f"/v1/subscriptions/{sub_id}/appStoreReviewScreenshot")
    current = existing.get("data")
    if current:
        state = (current["attributes"].get("assetDeliveryState") or {}).get("state")
        # A FAILED reservation can never be completed; it must be replaced.
        print(f"  {product}: existing screenshot state={state} -> deleting")
        call("DELETE", f"/v1/subscriptionAppStoreReviewScreenshots/{current['id']}")

    created = call(
        "POST",
        "/v1/subscriptionAppStoreReviewScreenshots",
        {
            "data": {
                "type": "subscriptionAppStoreReviewScreenshots",
                "attributes": {"fileName": filename, "fileSize": len(blob)},
                "relationships": {
                    "subscription": {"data": {"type": "subscriptions", "id": sub_id}}
                },
            }
        },
    )
    if created.get("_err"):
        print(f"  {product}: reserve FAILED {created['_err']} {created['_detail']}")
        return

    shot_id = created["data"]["id"]
    for op in created["data"]["attributes"].get("uploadOperations") or []:
        put_bytes(op, blob)

    done = call(
        "PATCH",
        f"/v1/subscriptionAppStoreReviewScreenshots/{shot_id}",
        {
            "data": {
                "type": "subscriptionAppStoreReviewScreenshots",
                "id": shot_id,
                "attributes": {
                    "uploaded": True,
                    "sourceFileChecksum": hashlib.md5(blob).hexdigest(),
                },
            }
        },
    )
    if done.get("_err"):
        print(f"  {product}: commit FAILED {done['_err']} {done['_detail']}")
        return
    state = (done["data"]["attributes"].get("assetDeliveryState") or {}).get("state")
    print(f"  {product}: uploaded, assetDeliveryState={state}")


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit("Usage: asc_iap_screenshots.py <path-to-png>")
    path = os.path.expanduser(sys.argv[1])
    blob = open(path, "rb").read()
    filename = os.path.basename(path)
    print(f"Uploading {filename} ({len(blob):,} bytes) to each subscription\n")

    gid = call("GET", f"/v1/apps/{APP_ID}/subscriptionGroups")["data"][0]["id"]
    subs = call("GET", f"/v1/subscriptionGroups/{gid}/subscriptions")["data"]
    for sub in subs:
        upload_for(sub["id"], sub["attributes"]["productId"], blob, filename)

    print("\nPolling for state to settle...")
    for _ in range(10):
        time.sleep(6)
        rows = []
        for sub in call("GET", f"/v1/subscriptionGroups/{gid}/subscriptions")["data"]:
            attrs = sub["attributes"]
            shot = call(
                "GET", f"/v1/subscriptions/{sub['id']}/appStoreReviewScreenshot"
            ).get("data")
            delivery = (
                (shot["attributes"].get("assetDeliveryState") or {}).get("state")
                if shot
                else "NONE"
            )
            rows.append((attrs["productId"], attrs["state"], delivery))
        for product, state, delivery in rows:
            print(f"  {product:<34} {state:<18} asset={delivery}")
        if all(delivery == "COMPLETE" for _, _, delivery in rows):
            break
        print("  ---")


if __name__ == "__main__":
    main()
