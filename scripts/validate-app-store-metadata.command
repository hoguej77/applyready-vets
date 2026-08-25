#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
METADATA_FILE="$ROOT_DIR/app-store-metadata.json"
MODE="${1:---draft}"

if [[ "$MODE" != "--draft" && "$MODE" != "--release" ]]; then
  echo "Usage: validate-app-store-metadata.command [--draft|--release]"
  exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "FAIL: jq is required to validate app-store-metadata.json."
  exit 1
fi

if ! jq empty "$METADATA_FILE" >/dev/null 2>&1; then
  echo "FAIL: app-store-metadata.json is not valid JSON."
  exit 1
fi

problems=0

value() {
  jq -r "$1 // \"\"" "$METADATA_FILE"
}

check_bytes() {
  local label="$1"
  local selector="$2"
  local maximum="$3"
  local text_value byte_count
  text_value="$(value "$selector")"
  byte_count="$(LC_ALL=C print -rn -- "$text_value" | wc -c | tr -d ' ')"
  if (( byte_count == 0 || byte_count > maximum )); then
    echo "FAIL: $label is $byte_count bytes; required range is 1-$maximum."
    problems=$((problems + 1))
  fi
}

check_bytes "App name" '.listing.name' 30
check_bytes "Subtitle" '.listing.subtitle' 30
check_bytes "Promotional text" '.listing.promotional_text' 170
check_bytes "Description" '.listing.description' 4000
check_bytes "Keywords" '.listing.keywords' 100
check_bytes "Review notes" '.review.notes' 4000

name="$(value '.listing.name')"
name_bytes="$(LC_ALL=C print -rn -- "$name" | wc -c | tr -d ' ')"
if (( name_bytes < 2 )); then
  echo "FAIL: App name must be at least 2 bytes."
  problems=$((problems + 1))
fi

keywords="$(value '.listing.keywords')"
if print -rn -- "$keywords" | grep -Eqi '(^|,)[[:space:]]*(linkedin|indeed|workday|chatgpt|gemini|copilot|apple|canva)([[:space:]]*,|$)'; then
  echo "FAIL: Keywords contain another app or company name."
  problems=$((problems + 1))
fi

public_copy="$(jq -r '[.listing.name,.listing.subtitle,.listing.promotional_text,.listing.description,.listing.keywords,.in_app_purchase.display_name,.in_app_purchase.description] | join("\n")' "$METADATA_FILE")"
if print -rn -- "$public_copy" | grep -Eqi 'guaranteed job|guaranteed interview|beats every ATS|100% ATS|VA approved|official VA app|self-healing|perfect AI'; then
  echo "FAIL: Public metadata contains a prohibited or unprovable claim."
  problems=$((problems + 1))
fi

for selector in '.listing.support_url' '.listing.privacy_policy_url' '.listing.marketing_url'; do
  url_value="$(value "$selector")"
  if [[ "$MODE" == "--release" ]]; then
    if [[ ! "$url_value" =~ '^https://[^[:space:]]+$' || "$url_value" == *"[FINAL_"* || "$url_value" == *"example."* ]]; then
      echo "FAIL: $selector must be a final public HTTPS URL."
      problems=$((problems + 1))
    fi
  fi
done

if [[ "$(value '.in_app_purchase.product_id')" != "com.jonathanhogue.applyreadyvets.complete.lifetime" ]]; then
  echo "FAIL: Complete product ID does not match the shipping StoreKit contract."
  problems=$((problems + 1))
fi

if [[ "$(value '.in_app_purchase.type')" != "non-consumable" ]]; then
  echo "FAIL: Complete must remain a non-consumable."
  problems=$((problems + 1))
fi

if [[ "$(value '.in_app_purchase.us_launch_price')" != '$5.99' ]]; then
  echo "FAIL: U.S. launch price differs from the approved $5.99 decision."
  problems=$((problems + 1))
fi

if [[ "$MODE" == "--release" ]]; then
  if grep -Eq '\[FINAL_[^]]+\]|"status"[[:space:]]*:[[:space:]]*"draft"' "$METADATA_FILE"; then
    echo "FAIL: Release metadata still contains draft markers or owner placeholders."
    problems=$((problems + 1))
  fi

  email="$(value '.review.contact_email')"
  if [[ ! "$email" =~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' ]]; then
    echo "FAIL: App Review contact email is not a final valid address."
    problems=$((problems + 1))
  fi

  if [[ "$(value '.privacy_answer_draft.revalidate_against_final_signed_binary')" != "true" ]]; then
    echo "FAIL: Final-binary privacy revalidation must remain required."
    problems=$((problems + 1))
  fi

  if [[ "$(value '.build.marketing_version')" != "1.0.0" ]]; then
    echo "FAIL: The first public App Store metadata version must be finalized as 1.0.0 after beta approval."
    problems=$((problems + 1))
  fi

  build_number="$(value '.build.build_number')"
  if [[ ! "$build_number" =~ '^[0-9]+$' ]] || (( build_number <= 18 )); then
    echo "FAIL: The public submission requires a new numeric build number greater than beta build 18."
    problems=$((problems + 1))
  fi
fi

if (( problems > 0 )); then
  echo "RESULT: App Store metadata validation failed with $problems problem(s)."
  exit 1
fi

if [[ "$MODE" == "--draft" ]]; then
  echo "PASS: App Store metadata draft is structurally valid and within Apple's current text limits."
  echo "NOTE: Final URLs, contact details, signed-binary privacy answers, screenshots, and App Store Connect review remain required."
else
  echo "PASS: App Store metadata has no known local release blockers. Apple App Review remains authoritative."
fi
