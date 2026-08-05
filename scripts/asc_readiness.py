#!/usr/bin/env python3
"""Report App Store Connect submission readiness for ManifestMe. Read-only.

Checks the preconditions App Store Connect enforces before a version can be
submitted. Reports only; it never writes and never submits.

Env vars are the same as asc_metadata.py (ASC_ISSUER_ID / ASC_KEY_ID /
ASC_KEY_PATH).
"""

import json
import os
import sys
import time
import urllib.error
import urllib.request

import jwt

APP_ID = "6751253658"
BASE = "https://api.appstoreconnect.apple.com"


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


def get(path: str):
    """GET returning parsed JSON, or an {'_error': ...} marker on HTTP failure.

    Several of these endpoints 404 legitimately (e.g. no build attached yet), so
    a failure is information rather than a reason to abort the whole report.
    """
    req = urllib.request.Request(f"{BASE}{path}", method="GET")
    req.add_header("Authorization", f"Bearer {token()}")
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read() or "{}")
    except urllib.error.HTTPError as exc:
        return {"_error": exc.code, "_detail": exc.read().decode(errors="replace")[:200]}


def line(ok: bool | None, label: str, detail: str) -> None:
    mark = {True: "PASS", False: "BLOCK", None: "????"}[ok]
    print(f"  [{mark:>5}] {label:<26} {detail}")


def main() -> None:
    versions = get(f"/v1/apps/{APP_ID}/appStoreVersions?limit=20")
    version = next(
        v
        for v in versions["data"]
        if v["attributes"].get("appStoreState") == "PREPARE_FOR_SUBMISSION"
    )
    vid = version["id"]
    print(f"\nManifestMe {version['attributes']['versionString']} "
          f"({version['attributes']['appStoreState']})\n")

    # Build — the hardest blocker. No build, no submission.
    build = get(f"/v1/appStoreVersions/{vid}/build")
    if build.get("_error") or not build.get("data"):
        line(False, "Build attached", "NO BUILD ATTACHED to this version")
    else:
        a = build["data"]["attributes"]
        line(True, "Build attached", f"build {a.get('version')} ({a.get('processingState')})")

    # Age rating.
    infos = get(f"/v1/apps/{APP_ID}/appInfos")
    info = infos["data"][0] if infos.get("data") else None
    if info:
        iid = info["id"]
        attrs = info["attributes"]
        rating = attrs.get("appStoreAgeRating")
        line(bool(rating), "Age rating", rating or "NOT SET")
        state = attrs.get("appStoreState") or attrs.get("state")
        print(f"          appInfo state: {state}")

        locs = get(f"/v1/appInfos/{iid}/appInfoLocalizations")
        for loc in locs.get("data", []):
            la = loc["attributes"]
            if la.get("locale") == "en-US":
                line(bool(la.get("name")), "App name", la.get("name") or "EMPTY")
                line(bool(la.get("subtitle")), "Subtitle", la.get("subtitle") or "EMPTY")
                line(
                    bool(la.get("privacyPolicyUrl")),
                    "Privacy policy URL",
                    la.get("privacyPolicyUrl") or "EMPTY",
                )
        locales = [l["attributes"].get("locale") for l in locs.get("data", [])]
        print(f"          localizations: {locales}")

    # Pricing. The appPriceSchedule resource always exists, so its presence
    # proves nothing — an app with no price tier ever chosen still returns one.
    # The real signal is whether manualPrices has an entry.
    prices = get(f"/v1/appPriceSchedules/{APP_ID}/manualPrices?include=appPricePoint")
    if prices.get("_error") or not prices.get("data"):
        line(False, "Price tier", "NOT SET (no manualPrices entry)")
    else:
        amounts = [
            inc["attributes"].get("customerPrice")
            for inc in prices.get("included", [])
            if inc["type"] == "appPricePoints"
        ]
        shown = amounts[0] if amounts else "?"
        label = "Free" if shown in ("0", "0.0", "0.00") else shown
        line(True, "Price tier", label)

    # Subscriptions.
    groups = get(f"/v1/apps/{APP_ID}/subscriptionGroups")
    if groups.get("_error"):
        line(None, "Subscriptions", f"could not read (HTTP {groups['_error']})")
    else:
        for g in groups.get("data", []):
            subs = get(f"/v1/subscriptionGroups/{g['id']}/subscriptions")
            for s in subs.get("data", []):
                sa = s["attributes"]
                ok = sa.get("state") in {"APPROVED", "READY_TO_SUBMIT", "IN_REVIEW"}
                line(ok, "  IAP " + str(sa.get("productId", ""))[-16:],
                     str(sa.get("state")))

    # Screenshots.
    locs = get(f"/v1/appStoreVersions/{vid}/appStoreVersionLocalizations")
    for loc in locs.get("data", []):
        if loc["attributes"].get("locale") != "en-US":
            continue
        sets = get(f"/v1/appStoreVersionLocalizations/{loc['id']}/appScreenshotSets")
        for s in sets.get("data", []):
            dt = s["attributes"].get("screenshotDisplayType")
            shots = get(f"/v1/appScreenshotSets/{s['id']}/appScreenshots")
            n = len(shots.get("data", []))
            line(n >= 1, f"  Screenshots {dt}", f"{n} uploaded")

    print("\nNOT CHECKABLE VIA API: the App Privacy questionnaire ('nutrition")
    print("label') has no public read endpoint. Confirm it shows Published in")
    print("the ASC web UI before submitting.\n")


if __name__ == "__main__":
    main()
