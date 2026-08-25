#!/bin/zsh

source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

function usage() {
  echo "Usage: release-preflight.command [--release-candidate|--app-store|--beta|--self-test]"
  echo
  echo "  --release-candidate  Require the Release storefront to be enabled."
  echo "  --app-store          Also require a signing team and public Support/Privacy URLs."
  echo "  --beta               Require the Release storefront to be disabled."
  echo "  --self-test          Test the bounded project-setting parser and mode policy."
}

PREFLIGHT_MODE="${HOGUE_PREFLIGHT_MODE:-release-candidate}"
case "${1:-}" in
  "")
    ;;
  --release-candidate)
    PREFLIGHT_MODE="release-candidate"
    ;;
  --app-store)
    PREFLIGHT_MODE="app-store"
    ;;
  --beta)
    PREFLIGHT_MODE="beta"
    ;;
  --self-test)
    PREFLIGHT_MODE="self-test"
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    usage
    exit 2
    ;;
esac

if (( $# > 1 )); then
  usage
  exit 2
fi

if [[ "$PREFLIGHT_MODE" != "release-candidate" \
      && "$PREFLIGHT_MODE" != "app-store" \
      && "$PREFLIGHT_MODE" != "beta" \
      && "$PREFLIGHT_MODE" != "self-test" ]]; then
  echo "HOGUE_PREFLIGHT_MODE must be release-candidate, app-store, or beta."
  exit 2
fi

echo "ApplyReady Vets release preflight"
if [[ "$PREFLIGHT_MODE" == "self-test" ]]; then
  echo "Testing bounded preflight parsing and StoreKit mode policy."
else
  echo "Mode: $PREFLIGHT_MODE"
  echo "Checking the source-controlled release contract without signing or uploading."
fi
echo

/usr/bin/python3 - "$ROOT" "$PREFLIGHT_MODE" <<'PY'
from __future__ import annotations

import ast
import json
import plistlib
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
mode = sys.argv[2]
project = root / "ios/project.yml"
app_info = root / "ios/ApplyReadyVets/Resources/Info.plist"
share_info = root / "ios/ApplyReadyVetsShare/Info.plist"
widget_info = root / "ios/ApplyReadyVetsWidget/Info.plist"
privacy = root / "ios/ApplyReadyVets/Resources/PrivacyInfo.xcprivacy"
app_entitlements = root / "ios/ApplyReadyVets/Resources/ApplyReadyVets.entitlements"
share_entitlements = root / "ios/ApplyReadyVetsShare/ApplyReadyVetsShare.entitlements"
widget_entitlements = root / "ios/ApplyReadyVetsWidget/ApplyReadyVetsWidget.entitlements"
storefront = root / "ios/ApplyReadyVets/Features/LegalAndSupportView.swift"
entitlement_manager = root / "ios/ApplyReadyVets/Services/EntitlementManager.swift"
storekit_configuration = root / "ios/ApplyReadyVets/Resources/ApplyReadyVets.storekit"
app_intents = root / "ios/ApplyReadyVets/Services/CareerAppIntents.swift"
ui_audit = root / "ios/ApplyReadyVetsUITests/AccessibilityAuditTests.swift"
store_guide = root / "APPLE_APP_STORE_SUBMISSION_GUIDE.md"
backend_project = root / "backend/pyproject.toml"
backend_init = root / "backend/app/__init__.py"

errors: list[str] = []
passes: list[str] = []


def require(condition: bool, success: str, failure: str) -> None:
    if condition:
        passes.append(success)
    else:
        errors.append(failure)


def load_plist(path: Path) -> dict:
    try:
        with path.open("rb") as handle:
            return plistlib.load(handle)
    except Exception as exc:
        errors.append(f"{path.relative_to(root)} is not a valid property list: {exc}")
        return {}


def parse_project_scalars(text: str) -> dict[tuple[str, ...], str]:
    """Parse the scalar mapping paths used by project.yml in linear time.

    This intentionally isn't a general YAML parser. It handles the indentation-
    based mappings and quoted scalar values used for XcodeGen build settings,
    rejects duplicate app configuration paths, and never searches across
    arbitrary blocks.
    """

    stack: list[tuple[int, str]] = []
    scalars: dict[tuple[str, ...], str] = {}
    for line_number, raw_line in enumerate(text.splitlines(), start=1):
        if not raw_line.strip() or raw_line.lstrip().startswith(("#", "- ")):
            continue
        if "\t" in raw_line[: len(raw_line) - len(raw_line.lstrip())]:
            raise ValueError(f"tab indentation at line {line_number}")

        indent = len(raw_line) - len(raw_line.lstrip(" "))
        stripped = raw_line.strip()
        if ":" not in stripped:
            continue
        key, raw_value = stripped.split(":", 1)
        key = key.strip()
        if not key:
            raise ValueError(f"empty mapping key at line {line_number}")

        while stack and indent <= stack[-1][0]:
            stack.pop()
        path = tuple(item[1] for item in stack) + (key,)
        value = raw_value.strip()
        if not value:
            stack.append((indent, key))
            continue

        if value[:1] in {"\"", "'"}:
            try:
                decoded = ast.literal_eval(value)
            except (SyntaxError, ValueError) as exc:
                raise ValueError(
                    f"invalid quoted scalar at line {line_number}: {exc}"
                ) from exc
            if not isinstance(decoded, str):
                decoded = str(decoded)
            value = decoded

        protected_prefix = (
            "targets",
            "ApplyReadyVets",
            "settings",
            "configs",
        )
        if path in scalars and path[: len(protected_prefix)] == protected_prefix:
            raise ValueError(
                f"duplicate scalar path at line {line_number}: {'/'.join(path)}"
            )
        scalars[path] = value
    return scalars


def storefront_values(text: str) -> tuple[str | None, str | None]:
    scalars = parse_project_scalars(text)
    prefix = ("targets", "ApplyReadyVets", "settings", "configs")
    return (
        scalars.get(prefix + ("Debug", "HOGUE_STOREFRONT_ENABLED")),
        scalars.get(prefix + ("Release", "HOGUE_STOREFRONT_ENABLED")),
    )


def storefront_matches(text: str, selected_mode: str) -> bool:
    debug_value, release_value = storefront_values(text)
    expected_release = "YES" if selected_mode in {"release-candidate", "app-store"} else "NO"
    return debug_value == "YES" and release_value == expected_release


if mode == "self-test":
    fixture = """
targets:
  ApplyReadyVets:
    settings:
      configs:
        Debug:
          HOGUE_API_BASE_URL: http://127.0.0.1:8000
          HOGUE_STOREFRONT_ENABLED: "YES"
        Release:
          HOGUE_API_BASE_URL: ""
          HOGUE_STOREFRONT_ENABLED: "{release_value}"
"""
    candidate = fixture.format(release_value="YES")
    beta = fixture.format(release_value="NO")
    assert storefront_matches(candidate, "release-candidate")
    assert storefront_matches(candidate, "app-store")
    assert not storefront_matches(candidate, "beta")
    assert storefront_matches(beta, "beta")
    assert not storefront_matches(beta, "release-candidate")

    adversarial = candidate + "\n".join(
        f"  unrelated_setting_{index}: value" for index in range(25_000)
    )
    assert storefront_matches(adversarial, "release-candidate")

    duplicate = candidate + """
        Release:
          HOGUE_STOREFRONT_ENABLED: "YES"
"""
    try:
        parse_project_scalars(duplicate)
    except ValueError:
        pass
    else:
        raise AssertionError("duplicate scalar paths must be rejected")

    print("PASS: release-candidate mode accepts an enabled Release storefront.")
    print("PASS: app-store mode accepts an enabled Release storefront.")
    print("PASS: beta mode accepts a disabled Release storefront.")
    print("PASS: each mode rejects the other mode's storefront contract.")
    print("PASS: the bounded parser handles a 25,000-line fixture without cross-block regex.")
    print("PASS: duplicate project-setting paths are rejected.")
    print()
    print("RESULT: RELEASE PREFLIGHT SELF-TEST PASSED.")
    sys.exit(0)


required_files = [
    project,
    app_info,
    share_info,
    widget_info,
    privacy,
    app_entitlements,
    share_entitlements,
    widget_entitlements,
    storefront,
    entitlement_manager,
    storekit_configuration,
    app_intents,
    ui_audit,
    store_guide,
    backend_project,
    backend_init,
]
missing = [str(path.relative_to(root)) for path in required_files if not path.is_file()]
require(not missing, "Required release files are present.", f"Missing required files: {', '.join(missing)}")
if missing:
    for line in errors:
        print(f"FAIL: {line}")
    sys.exit(1)

project_text = project.read_text(encoding="utf-8")
storefront_text = storefront.read_text(encoding="utf-8")
entitlement_text = entitlement_manager.read_text(encoding="utf-8")
intent_text = app_intents.read_text(encoding="utf-8")
audit_text = ui_audit.read_text(encoding="utf-8")
guide_text = store_guide.read_text(encoding="utf-8")
backend_project_text = backend_project.read_text(encoding="utf-8")
backend_init_text = backend_init.read_text(encoding="utf-8")

app_plist = load_plist(app_info)
share_plist = load_plist(share_info)
widget_plist = load_plist(widget_info)
privacy_plist = load_plist(privacy)
app_entitlements_plist = load_plist(app_entitlements)
share_entitlements_plist = load_plist(share_entitlements)
widget_entitlements_plist = load_plist(widget_entitlements)

try:
    project_scalars = parse_project_scalars(project_text)
except ValueError as exc:
    project_scalars = {}
    errors.append(f"ios/project.yml build settings could not be parsed safely: {exc}")

bundle_id = "com.jonathanhogue.applyreadyvets"
share_bundle_id = f"{bundle_id}.share"
widget_bundle_id = f"{bundle_id}.widget"
app_group = "group.com.jonathanhogue.applyreadyvets"

require(
    f"PRODUCT_BUNDLE_IDENTIFIER: {bundle_id}" in project_text
    and f"PRODUCT_BUNDLE_IDENTIFIER: {share_bundle_id}" in project_text
    and f"PRODUCT_BUNDLE_IDENTIFIER: {widget_bundle_id}" in project_text,
    "App, Share extension, and widget bundle identifiers are consistent.",
    "Expected app, Share extension, or widget bundle identifier is missing.",
)
require(
    "PRODUCT_NAME: ApplyReadyVets" in project_text
    and "CFBundleDisplayName: ApplyReady Vets" in project_text
    and "MusterForward" not in project_text,
    "The generated targets use the ApplyReady Vets identity.",
    "Project identity is inconsistent or still exposes the retired target name.",
)

versions = re.findall(r"^\s*MARKETING_VERSION:\s*[\"']?([^\s\"']+)", project_text, re.MULTILINE)
builds = re.findall(r"^\s*CURRENT_PROJECT_VERSION:\s*[\"']?([^\s\"']+)", project_text, re.MULTILINE)
require(
    len(versions) == 3 and len(set(versions)) == 1,
    f"App, Share extension, and widget marketing versions match ({versions[0] if versions else 'unknown'}).",
    f"Marketing versions do not match: {versions}",
)
current_version = versions[0] if versions else ""
require(
    f'version = "{current_version}"' in backend_project_text
    and f'__version__ = "{current_version}"' in backend_init_text,
    f"iOS and optional-service versions match ({current_version or 'unknown'}).",
    "The iOS and optional-service versions do not match.",
)
require(
    len(builds) == 3 and len(set(builds)) == 1 and all(value.isdigit() for value in builds),
    f"App, Share extension, and widget build numbers match ({builds[0] if builds else 'unknown'}).",
    f"Build numbers are invalid or do not match: {builds}",
)

expected_placeholders = {
    "CFBundleShortVersionString": "$(MARKETING_VERSION)",
    "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
}
require(
    all(app_plist.get(key) == value for key, value in expected_placeholders.items())
    and all(share_plist.get(key) == value for key, value in expected_placeholders.items())
    and all(widget_plist.get(key) == value for key, value in expected_placeholders.items()),
    "App and extension property lists inherit the Xcode marketing version and build number.",
    "App or extension property list has a hard-coded/mismatched version.",
)
require(
    app_plist.get("CFBundleDisplayName") == "ApplyReady Vets"
    and share_plist.get("CFBundleDisplayName") == "Save to ApplyReady Vets",
    "User-facing app and Share action names are correct.",
    "A user-facing display name is incorrect.",
)
require(
    app_plist.get("ITSAppUsesNonExemptEncryption") is False,
    "The app declares that this reviewed binary uses no non-exempt encryption.",
    (
        "ITSAppUsesNonExemptEncryption must be false only after confirming the "
        "final binary still uses no non-exempt encryption."
    ),
)
require(
    widget_plist.get("CFBundleDisplayName") == "ApplyReady Vets"
    and widget_plist.get("NSExtension", {}).get("NSExtensionPointIdentifier")
    == "com.apple.widgetkit-extension",
    "The widget display name and extension point are correct.",
    "The widget display name or extension point is incorrect.",
)
settings_prefix = ("targets", "ApplyReadyVets", "settings", "configs")
debug_storefront = project_scalars.get(
    settings_prefix + ("Debug", "HOGUE_STOREFRONT_ENABLED")
)
release_storefront = project_scalars.get(
    settings_prefix + ("Release", "HOGUE_STOREFRONT_ENABLED")
)
expected_release_storefront = "YES" if mode in {"release-candidate", "app-store"} else "NO"
require(
    app_plist.get("HOGUE_STOREFRONT_ENABLED") == "$(HOGUE_STOREFRONT_ENABLED)"
    and debug_storefront == "YES"
    and release_storefront == expected_release_storefront,
    (
        "Storefront settings match release-candidate mode "
        "(Debug YES, Release YES)."
        if mode in {"release-candidate", "app-store"}
        else "Storefront settings match beta mode (Debug YES, Release NO)."
    ),
    (
        f"Storefront settings do not match {mode} mode: expected Debug YES and "
        f"Release {expected_release_storefront}, found Debug "
        f"{debug_storefront or 'missing'} and Release "
        f"{release_storefront or 'missing'}."
    ),
)
release_api_base_url = project_scalars.get(
    settings_prefix + ("Release", "HOGUE_API_BASE_URL")
)
require(
    release_api_base_url == "",
    "Release builds ship without a default optional-service endpoint.",
    (
        "Release optional-service endpoint is not explicitly blank "
        f"(found {release_api_base_url!r})."
    ),
)


def is_public_https_url(raw_value: str | None) -> bool:
    if not raw_value or not raw_value.startswith("https://"):
        return False
    from urllib.parse import urlsplit

    try:
        parsed = urlsplit(raw_value)
    except ValueError:
        return False
    host = (parsed.hostname or "").lower()
    disallowed_host = (
        host in {
            "localhost", "0.0.0.0", "::1", "example.com", "example.org", "example.net"
        }
        or host.startswith(("127.", "10.", "192.168.", "169.254.", "fc", "fd", "fe80:"))
        or host.endswith((".local", ".internal", ".example", ".invalid", ".test"))
    )
    parts = host.split(".")
    if len(parts) == 4 and all(part.isdigit() for part in parts):
        octets = [int(part) for part in parts]
        disallowed_host = disallowed_host or (
            octets[0] == 172 and 16 <= octets[1] <= 31
        )
    return bool(
        host
        and parsed.username is None
        and parsed.password is None
        and parsed.fragment == ""
        and not disallowed_host
    )


support_url = project_scalars.get(
    settings_prefix + ("Release", "APPLYREADYVETS_SUPPORT_URL")
)
privacy_policy_url = project_scalars.get(
    settings_prefix + ("Release", "APPLYREADYVETS_PRIVACY_POLICY_URL")
)
require(
    app_plist.get("APPLYREADYVETS_SUPPORT_URL") == "$(APPLYREADYVETS_SUPPORT_URL)"
    and app_plist.get("APPLYREADYVETS_PRIVACY_POLICY_URL")
    == "$(APPLYREADYVETS_PRIVACY_POLICY_URL)",
    "The shipping app inherits its public Support and Privacy URLs from Release settings.",
    "The shipping Info.plist is missing the configurable Support or Privacy URL.",
)
if mode == "app-store":
    development_team = project_scalars.get(("settings", "base", "DEVELOPMENT_TEAM"))
    require(
        bool(development_team),
        "An Apple Developer team is selected for automatic signing.",
        "App Store mode requires DEVELOPMENT_TEAM in ios/project.yml.",
    )
    require(
        is_public_https_url(support_url),
        "A public HTTPS Support URL is configured for the shipping app.",
        "App Store mode requires a valid public HTTPS APPLYREADYVETS_SUPPORT_URL.",
    )
    require(
        is_public_https_url(privacy_policy_url),
        "A public HTTPS Privacy Policy URL is configured for the shipping app.",
        "App Store mode requires a valid public HTTPS APPLYREADYVETS_PRIVACY_POLICY_URL.",
    )

app_groups = app_entitlements_plist.get("com.apple.security.application-groups", [])
share_groups = share_entitlements_plist.get("com.apple.security.application-groups", [])
widget_groups = widget_entitlements_plist.get("com.apple.security.application-groups", [])
require(
    app_groups == [app_group]
    and share_groups == [app_group]
    and widget_groups == [app_group],
    "App, Share extension, and widget declare the same App Group.",
    "App Group entitlements are missing or inconsistent.",
)
require(
    privacy_plist.get("NSPrivacyTracking") is False
    and privacy_plist.get("NSPrivacyTrackingDomains") == []
    and all(
        item.get("NSPrivacyCollectedDataTypeTracking") is False
        for item in privacy_plist.get("NSPrivacyCollectedDataTypes", [])
    ),
    "Privacy manifest declares no tracking or tracking domains.",
    "Privacy manifest contains tracking or an incomplete tracking declaration.",
)

product_ids = [
    f"{bundle_id}.complete.lifetime",
]
require(
    all(product_id in entitlement_text and product_id in guide_text for product_id in product_ids),
    "StoreKit product identifiers match the App Store setup guide.",
    "StoreKit product identifiers differ between code and the App Store guide.",
)
try:
    storekit_payload = json.loads(storekit_configuration.read_text(encoding="utf-8"))
    configured_product_ids = {
        item.get("productID")
        for item in storekit_payload.get("products", [])
        if isinstance(item, dict)
    }
except Exception as exc:
    storekit_payload = {}
    configured_product_ids = set()
    errors.append(f"Local StoreKit configuration is invalid JSON: {exc}")
require(
    configured_product_ids == set(product_ids)
    and "storeKitConfiguration: ApplyReadyVets/Resources/ApplyReadyVets.storekit" in project_text,
    "The local StoreKit catalog and Run scheme contain the one expected lifetime product.",
    "The StoreKit test catalog, product IDs, or Run-scheme configuration is incomplete.",
)
configured_products = {
    item.get("productID"): item
    for item in storekit_payload.get("products", [])
    if isinstance(item, dict)
}
require(
    configured_products.get(f"{bundle_id}.complete.lifetime", {}).get("displayPrice") == "5.99",
    "The local Complete test product uses the approved $5.99 U.S. launch price.",
    "The local Complete test price is not $5.99.",
)
require(
    "- Resources/ApplyReadyVets.storekit" in project_text
    and re.search(
        r"ApplyReadyVetsTests:\s*(?:.|\n)*?"
        r"path:\s*ApplyReadyVets/Resources/ApplyReadyVets\.storekit\s*\n"
        r"\s*buildPhase:\s*resources",
        project_text,
    )
    is not None,
    "The StoreKit catalog is test-only and excluded from the shipping app bundle.",
    "The local StoreKit catalog could be copied into the shipping app bundle.",
)
require(
    "performAccessibilityAudit" in audit_text
    and "ApplyReadyVetsUITests" in project_text,
    "Automated accessibility auditing is part of the Xcode test scheme.",
    "Accessibility audit test or UI-test target is missing.",
)
required_intents = [
    "StartVeteranApplicationIntent",
    "ReviewTruthLockIntent",
    "BuildLinkedInProfileIntent",
    "SaveJobLinkIntent",
]
require(
    all(name in intent_text for name in required_intents)
    and "AppShortcutsProvider" in intent_text,
    "Privacy-safe Siri/Shortcuts actions are registered.",
    "One or more required App Intents are missing.",
)
for line in passes:
    print(f"PASS: {line}")
for line in errors:
    print(f"FAIL: {line}")

print()
print("PUBLIC RELEASE BLOCKERS (expected; not changed by this local check):")
print("- Select Jonathan's paid Apple Developer team and register all three bundle IDs plus the App Group.")
print("- Publish final HTTPS support and privacy-policy pages.")
print("- Create matching App Store Connect products, then validate signed sandbox purchase and restore behavior.")
print("- Test purchase, pending, cancellation, restore, refund/revocation, and Ask to Buy behavior.")
print("- Run signed physical-device tests for Share Sheet, Siri, Apple on-device assistance, accessibility, and export.")
print("- Complete App Store privacy answers, age rating, screenshots, review notes, agreements, tax, and banking.")
print("- Obtain independent legal, privacy, accessibility, employment, veteran-benefits, and OPSEC review.")

if errors:
    print()
    print(f"RESULT: LOCAL PREFLIGHT FAILED ({len(errors)} problem{'s' if len(errors) != 1 else ''}).")
    sys.exit(1)

print()
print(
    f"RESULT: LOCAL {mode.upper()} PREFLIGHT PASSED. "
    "Public release remains blocked by the user-controlled items above."
)
PY

pause_if_double_clicked
