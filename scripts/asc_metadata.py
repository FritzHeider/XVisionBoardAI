#!/usr/bin/env python3
"""Read and update App Store Connect metadata for ManifestMe via the ASC REST API.

Driving the App Store Connect web UI with a browser agent proved unreliable: it is
a React app, so JS value assignment silently no-ops, and vision agents loop on the
scrolling form. The REST API sets the same fields deterministically.

Usage:
    export ASC_ISSUER_ID="<uuid from ASC -> Users and Access -> Integrations>"
    export ASC_KEY_ID="<key id, e.g. AWK9GDP739>"
    export ASC_KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_<key id>.p8"

The key must have App Manager or Admin access; a Developer-scoped key 401s.
Never commit the .p8 itself — Apple lets you download it exactly once.

    python3 scripts/asc_metadata.py read     # report current state, change nothing
    python3 scripts/asc_metadata.py apply    # write the values in DESIRED, then re-read

`read` is the default. `apply` never submits for review; it only sets fields.
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
LOCALE = "en-US"

# Source of truth for these strings is APP_STORE_LISTING.md. Keep them in sync.
DESIRED_LOCALIZATION = {
    "promotionalText": (
        "Not a stock photo. Not a stranger. You. ManifestMe turns one selfie "
        "into an AI vision board of the life you're calling in — and "
        "affirmations to match."
    ),
    "keywords": (
        "law,of,attraction,money,loa,mindset,affirmations,gratitude,journal,"
        "goals,dream,collage,photo,visual"
    ),
    "supportUrl": "https://manifestme.fritzthatcat.com/",
    "marketingUrl": "https://manifestme.fritzthatcat.com/",
}

DESIRED_VERSION = {"copyright": "2026 Fritz Heider"}

# demoAccountRequired must be False: the app ships a guest path, and claiming a
# sign-in is required while supplying no credentials is a review rejection.
DESIRED_REVIEW_DETAIL = {
    "demoAccountRequired": False,
    "notes": (
        'No sign-in is required. Tap "Continue without an account" on the '
        "welcome screen to use the full app. No demo credentials are needed.\n"
        "To see the core feature: allow camera or pick a photo, enter a goal, "
        "tap generate. A one-time consent screen explains that the selfie goes "
        "to fal.ai and the goal text to Google Gemini; tap \"I Agree\" to "
        "proceed. Generation takes 30s-3min and requires network.\n"
        "Free tier includes 1 vision board so the full flow can be exercised "
        "without purchasing.\n"
        "Pro unlocks three things, each verifiable in sandbox: unlimited "
        'boards, HD watermark-free exports (free exports are watermarked "Made '
        'with ManifestMe" at standard resolution), and audio affirmations '
        '("Read Aloud" on a board\'s detail screen).\n'
        "Privacy Policy and Terms of Use are linked in-app at Profile > Legal, "
        "and on the paywall. Account deletion is available in Profile > Delete "
        "Account.\n"
        "Contact: support@fritzthatcat.com"
    ),
}

# Version states that still accept metadata edits.
EDITABLE_STATES = {
    "PREPARE_FOR_SUBMISSION",
    "DEVELOPER_REJECTED",
    "REJECTED",
    "METADATA_REJECTED",
    "INVALID_BINARY",
}


def token() -> str:
    issuer = os.environ.get("ASC_ISSUER_ID")
    key_id = os.environ.get("ASC_KEY_ID")
    key_path = os.path.expanduser(os.environ.get("ASC_KEY_PATH", ""))
    missing = [
        name
        for name, val in (
            ("ASC_ISSUER_ID", issuer),
            ("ASC_KEY_ID", key_id),
            ("ASC_KEY_PATH", key_path),
        )
        if not val
    ]
    if missing:
        sys.exit(f"Missing env var(s): {', '.join(missing)}. See the docstring.")
    if not os.path.exists(key_path):
        sys.exit(f"Private key not found at {key_path}")
    with open(key_path) as fh:
        private_key = fh.read()
    now = int(time.time())
    return jwt.encode(
        {"iss": issuer, "iat": now, "exp": now + 900, "aud": "appstoreconnect-v1"},
        private_key,
        algorithm="ES256",
        headers={"kid": key_id, "typ": "JWT"},
    )


def call(method: str, path: str, body: dict | None = None) -> dict:
    url = path if path.startswith("http") else f"{BASE}{path}"
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", f"Bearer {token()}")
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as resp:
            raw = resp.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode(errors="replace")
        sys.exit(f"{method} {url} -> HTTP {exc.code}\n{detail}")


def editable_version() -> dict:
    versions = call("GET", f"/v1/apps/{APP_ID}/appStoreVersions?limit=20")["data"]
    for ver in versions:
        state = ver["attributes"].get("appStoreState") or ver["attributes"].get(
            "appVersionState"
        )
        if state in EDITABLE_STATES:
            return ver
    states = [
        (v["attributes"].get("versionString"), v["attributes"].get("appStoreState"))
        for v in versions
    ]
    sys.exit(f"No editable version found. Versions/states: {states}")


def localization_for(version_id: str) -> dict:
    locs = call(
        "GET", f"/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations"
    )["data"]
    for loc in locs:
        if loc["attributes"]["locale"] == LOCALE:
            return loc
    sys.exit(f"No {LOCALE} localization. Found: "
             f"{[l['attributes']['locale'] for l in locs]}")


def report(version: dict, loc: dict, review: dict | None) -> None:
    def show(label: str, value) -> None:
        if value is None or value == "":
            print(f"  {label:<18} EMPTY")
        else:
            text = str(value).replace("\n", " ")
            print(f"  {label:<18} {text[:72]}{'…' if len(text) > 72 else ''}")

    print(f"\nVersion {version['attributes'].get('versionString')} "
          f"({version['attributes'].get('appStoreState')})  id={version['id']}")
    print(f"\n{LOCALE} localization  id={loc['id']}")
    for field in ("promotionalText", "keywords", "supportUrl", "marketingUrl"):
        show(field, loc["attributes"].get(field))
    show("description", loc["attributes"].get("description"))
    print("\nVersion-level")
    show("copyright", version["attributes"].get("copyright"))
    print("\nApp Review detail")
    if review is None:
        print("  (none created yet)")
    else:
        show("demoAccountRequired", review["attributes"].get("demoAccountRequired"))
        show("demoAccountName", review["attributes"].get("demoAccountName"))
        show("notes", review["attributes"].get("notes"))


def review_detail(version_id: str) -> dict | None:
    try:
        return call(
            "GET", f"/v1/appStoreVersions/{version_id}/appStoreReviewDetail"
        ).get("data")
    except SystemExit:
        return None


def main() -> None:
    mode = (sys.argv[1] if len(sys.argv) > 1 else "read").lower()
    if mode not in {"read", "apply"}:
        sys.exit("Usage: asc_metadata.py [read|apply]")

    version = editable_version()
    loc = localization_for(version["id"])
    review = review_detail(version["id"])

    print("=== BEFORE ===")
    report(version, loc, review)

    if mode == "read":
        print("\nRead-only. Re-run with 'apply' to write.")
        return

    print("\n=== APPLYING ===")
    call(
        "PATCH",
        f"/v1/appStoreVersionLocalizations/{loc['id']}",
        {
            "data": {
                "type": "appStoreVersionLocalizations",
                "id": loc["id"],
                "attributes": DESIRED_LOCALIZATION,
            }
        },
    )
    print("  localization fields patched")

    call(
        "PATCH",
        f"/v1/appStoreVersions/{version['id']}",
        {
            "data": {
                "type": "appStoreVersions",
                "id": version["id"],
                "attributes": DESIRED_VERSION,
            }
        },
    )
    print("  copyright patched")

    if review:
        call(
            "PATCH",
            f"/v1/appStoreReviewDetails/{review['id']}",
            {
                "data": {
                    "type": "appStoreReviewDetails",
                    "id": review["id"],
                    "attributes": DESIRED_REVIEW_DETAIL,
                }
            },
        )
        print("  review detail patched")
    else:
        call(
            "POST",
            "/v1/appStoreReviewDetails",
            {
                "data": {
                    "type": "appStoreReviewDetails",
                    "attributes": DESIRED_REVIEW_DETAIL,
                    "relationships": {
                        "appStoreVersion": {
                            "data": {
                                "type": "appStoreVersions",
                                "id": version["id"],
                            }
                        }
                    },
                }
            },
        )
        print("  review detail created")

    # Re-fetch from the server rather than trusting the write responses.
    version = editable_version()
    loc = localization_for(version["id"])
    review = review_detail(version["id"])
    print("\n=== AFTER (re-fetched from API) ===")
    report(version, loc, review)


if __name__ == "__main__":
    main()
