#!/bin/zsh

source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"
require_xcodegen

CORE_PACKAGE="$IOS/Packages/ApplyReadyVetsCore"
MAX_ATTEMPTS=2

function safe_remove_generated() {
  local path="$1"
  case "$path" in
    "$AUTOMATION/QualitySwiftPackage" \
    |"$AUTOMATION/QualityReleaseDerivedData" \
    |"$AUTOMATION/TestDerivedData" \
    |"$CORE_PACKAGE/.build")
      rm -rf "$path"
      ;;
    *)
      echo "Refusing to remove a path outside the generated-artifact allowlist: $path"
      exit 3
      ;;
  esac
}

function ensure_backend_tools() {
  if [[ ! -x "$BACKEND/.venv/bin/python" ]]; then
    echo "Creating the project-local Python environment…"
    python3 -m venv "$BACKEND/.venv"
  fi
  if [[ ! -x "$BACKEND/.venv/bin/pytest" || ! -x "$BACKEND/.venv/bin/ruff" ]]; then
    echo "Installing missing backend development tools into the project-local environment…"
    "$BACKEND/.venv/bin/pip" --disable-pip-version-check install -e "${BACKEND}[dev]"
  fi
}

function bounded_generated_repair() {
  echo "Applying the one allowed repair pass:"
  echo "  - clear only allowlisted generated build caches"
  echo "  - regenerate the Xcode project from ios/project.yml"
  echo "No source, private settings, drafts, documents, or app content will be changed."
  safe_remove_generated "$AUTOMATION/QualitySwiftPackage"
  safe_remove_generated "$AUTOMATION/QualityReleaseDerivedData"
  safe_remove_generated "$AUTOMATION/TestDerivedData"
  safe_remove_generated "$CORE_PACKAGE/.build"
  (cd "$IOS" && xcodegen generate)
}

ensure_backend_tools

for (( attempt = 1; attempt <= MAX_ATTEMPTS; attempt++ )); do
  echo
  echo "Quality validation attempt $attempt of $MAX_ATTEMPTS…"
  if HOGUE_NO_PAUSE=1 "$SCRIPT_DIR/quality-gate.command" \
      2>&1 | tee "$LOGS/repair-and-validate-attempt-${attempt}.log"; then
    echo
    echo "PASS: repair-and-validate completed on attempt $attempt."
    pause_if_double_clicked
    exit 0
  fi

  if (( attempt == MAX_ATTEMPTS )); then
    break
  fi
  bounded_generated_repair
done

echo
echo "FAIL: quality validation still fails after one bounded repair and one retry."
echo "No automatic source-code changes were attempted."
echo "Review $LOGS/repair-and-validate-attempt-1.log and"
echo "$LOGS/repair-and-validate-attempt-2.log."
exit 1
