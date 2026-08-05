#!/usr/bin/env python3
"""Submit ManifestMe 1.0 for App Review.

Uses the reviewSubmissions flow: create a submission, add the version (and any
READY_TO_SUBMIT subscriptions) as items, then flip submitted=true. Nothing is
sent to Apple until that final PATCH, so a failure partway leaves an unsubmitted
draft submission rather than a half-sent review.

Env vars match asc_metadata.py.
"""

import json
import os
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
    req = urllib.request.Request(BASE + path, data=data, method=method)
    req.add_header("Authorization", f"Bearer {token()}")
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as resp:
            raw = resp.read()
            return json.loads(raw) if raw else {"_ok": resp.status}
    except urllib.error.HTTPError as exc:
        return {"_err": exc.code, "_detail": exc.read().decode(errors="replace")[:600]}


def main() -> None:
    version = next(
        v
        for v in call("GET", f"/v1/apps/{APP_ID}/appStoreVersions?limit=20")["data"]
        if v["attributes"]["appStoreState"] == "PREPARE_FOR_SUBMISSION"
    )

    # Reuse an in-progress submission if one exists; Apple allows only one.
    existing = call(
        "GET", f"/v1/apps/{APP_ID}/reviewSubmissions?filter[state]=READY_FOR_REVIEW"
    )
    submission = (existing.get("data") or [None])[0]

    if submission is None:
        created = call(
            "POST",
            "/v1/reviewSubmissions",
            {
                "data": {
                    "type": "reviewSubmissions",
                    "attributes": {"platform": "IOS"},
                    "relationships": {
                        "app": {"data": {"type": "apps", "id": APP_ID}}
                    },
                }
            },
        )
        if created.get("_err"):
            print(f"create submission FAILED {created['_err']}\n{created['_detail']}")
            return
        submission = created["data"]
    sid = submission["id"]
    print(f"review submission {sid} (state={submission['attributes'].get('state')})")

    item = call(
        "POST",
        "/v1/reviewSubmissionItems",
        {
            "data": {
                "type": "reviewSubmissionItems",
                "relationships": {
                    "reviewSubmission": {
                        "data": {"type": "reviewSubmissions", "id": sid}
                    },
                    "appStoreVersion": {
                        "data": {"type": "appStoreVersions", "id": version["id"]}
                    },
                },
            }
        },
    )
    print(
        "  version item: "
        + (f"error {item['_err']} {item['_detail']}" if item.get("_err") else "added")
    )

    # Subscriptions are NOT addable here. reviewSubmissionItems only accepts
    # appStoreVersion, appEvent, custom product pages and version experiments;
    # POSTing a 'subscription' relationship 409s with RELATIONSHIP.UNKNOWN.
    # App Store Connect attaches READY_TO_SUBMIT subscriptions to the app's
    # review itself, so just report their state and let the operator confirm.
    gid = call("GET", f"/v1/apps/{APP_ID}/subscriptionGroups")["data"][0]["id"]
    for sub in call("GET", f"/v1/subscriptionGroups/{gid}/subscriptions")["data"]:
        attrs = sub["attributes"]
        print(f"  subscription {attrs['productId']}: {attrs['state']} (not added here)")

    final = call(
        "PATCH",
        f"/v1/reviewSubmissions/{sid}",
        {
            "data": {
                "type": "reviewSubmissions",
                "id": sid,
                "attributes": {"submitted": True},
            }
        },
    )
    if final.get("_err"):
        print(f"\nSUBMIT FAILED {final['_err']}\n{final['_detail']}")
        return
    print(f"\nSUBMITTED. state={final['data']['attributes'].get('state')}")


if __name__ == "__main__":
    main()
