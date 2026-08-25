#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKEND="$ROOT/backend"
POLICY_CHECK="$SCRIPT_DIR/check-source-policy.command"
OUTPUT_DIR="${HOGUE_PACKAGE_OUTPUT_DIR:-$ROOT/..}"
VALIDATE_ONLY="${HOGUE_PACKAGE_VALIDATE_ONLY:-0}"
VERSION="$(sed -n 's/^version = "\(.*\)"/\1/p' "$BACKEND/pyproject.toml" | head -1)"

if ! print -r -- "$VERSION" | /usr/bin/grep -Eq '^[0-9]+([.][0-9]+){1,3}([A-Za-z0-9._-]*)?$'; then
  echo "Unable to determine a safe package version from backend/pyproject.toml."
  exit 1
fi
if [[ ! -x "$POLICY_CHECK" ]]; then
  echo "Source policy checker is missing or is not executable: $POLICY_CHECK"
  exit 1
fi
if [[ "$VALIDATE_ONLY" != "0" && "$VALIDATE_ONLY" != "1" ]]; then
  echo "HOGUE_PACKAGE_VALIDATE_ONLY must be 0 or 1."
  exit 2
fi

ARCHIVE_NAME="ApplyReadyVets_Source_${VERSION}_M4.zip"
ARCHIVE="$OUTPUT_DIR/$ARCHIVE_NAME"
CHECKSUM="$ARCHIVE.sha256"
STAGING="$(mktemp -d "${TMPDIR:-/tmp}/applyreadyvets-package.XXXXXX")"
PACKAGE_ROOT="$STAGING/ApplyReadyVets"
TEMP_ARCHIVE="$STAGING/$ARCHIVE_NAME"

function cleanup_package_staging() {
  rm -rf "$STAGING"
}

function pause_if_double_clicked() {
  if [[ -t 0 && "${HOGUE_NO_PAUSE:-0}" != "1" ]]; then
    echo
    echo "Press any key to close this window."
    read -k 1
    echo
  fi
}

trap cleanup_package_staging EXIT

echo "Staging a privacy-safe source package…"
mkdir -p "$PACKAGE_ROOT"
/usr/bin/rsync -a \
  --include '.env.example' \
  --include '*/.env.example' \
  --exclude '.env' \
  --exclude '*/.env' \
  --exclude '.env.*' \
  --exclude '*/.env.*' \
  --exclude '.DS_Store' \
  --exclude '._*' \
  --exclude '.git/' \
  --exclude '.automation/' \
  --exclude 'automation/' \
  --exclude '.build/' \
  --exclude '.venv/' \
  --exclude '__pycache__/' \
  --exclude '.pytest_cache/' \
  --exclude '.ruff_cache/' \
  --exclude '*.egg-info/' \
  --exclude 'build/' \
  --exclude 'dist/' \
  --exclude 'DerivedData/' \
  --exclude 'logs/' \
  --exclude 'tmp/' \
  --exclude 'attachments/' \
  --exclude 'uploads/' \
  --exclude 'exports/' \
  --exclude 'downloads/' \
  --exclude 'xcuserdata/' \
  --exclude '*.xcuserstate' \
  --exclude '*.[Pp][Dd][Ff]' \
  --exclude '*.[Dd][Oo][Cc]' \
  --exclude '*.[Dd][Oo][Cc][Xx]' \
  --exclude '*.[Rr][Tt][Ff]' \
  --exclude '*.[Pp][Aa][Gg][Ee][Ss]' \
  --exclude '*.[Pp][Pp][Tt]' \
  --exclude '*.[Pp][Pp][Tt][Xx]' \
  --exclude '*.[Xx][Ll][Ss]' \
  --exclude '*.[Xx][Ll][Ss][Xx]' \
  --exclude '*.[Zz][Ii][Pp]' \
  --exclude '*.[Pp][Ee][Mm]' \
  --exclude '*.[Kk][Ee][Yy]' \
  --exclude '*.[Pp]12' \
  --exclude '*.[Pp]8' \
  --exclude '*.[Mm][Oo][Bb][Ii][Ll][Ee][Pp][Rr][Oo][Vv][Ii][Ss][Ii][Oo][Nn]' \
  --exclude '*.[Aa][Pp][Pp]' \
  --exclude '*.[Ii][Pp][Aa]' \
  --exclude '*.[Dd][Ss][Yy][Mm]' \
  "$ROOT/" "$PACKAGE_ROOT/"

echo "Generating the per-file SHA-256 manifest…"
/usr/bin/python3 - "$PACKAGE_ROOT" <<'PY'
from __future__ import annotations

import hashlib
import sys
from pathlib import Path

root = Path(sys.argv[1])
manifest = root / "SOURCE_MANIFEST.sha256"
lines: list[str] = []
for path in sorted(root.rglob("*"), key=lambda item: item.relative_to(root).as_posix()):
    if path.is_symlink():
        raise SystemExit(f"Symbolic links are not allowed in the source package: {path}")
    if not path.is_file() or path == manifest:
        continue
    relative = path.relative_to(root).as_posix()
    if any(ord(character) < 32 for character in relative):
        raise SystemExit(f"Control characters are not allowed in package paths: {relative!r}")
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    lines.append(f"{digest}  {relative}\n")
manifest.write_text("".join(lines), encoding="utf-8")
PY

echo "Checking the staged directory for private data, secrets, and build artifacts…"
HOGUE_NO_PAUSE=1 "$POLICY_CHECK" --require-manifest "$PACKAGE_ROOT"

echo "Creating and checking the candidate ZIP…"
/usr/bin/ditto -c -k --norsrc --noextattr --noqtn --noacl --keepParent \
  "$PACKAGE_ROOT" "$TEMP_ARCHIVE"
HOGUE_NO_PAUSE=1 "$POLICY_CHECK" --require-manifest "$TEMP_ARCHIVE"

if [[ "$VALIDATE_ONLY" == "1" ]]; then
  echo "PASS: a clean package was staged, checksummed, archived, and verified."
  pause_if_double_clicked
  exit 0
fi

mkdir -p "$OUTPUT_DIR"
/bin/mv -f "$TEMP_ARCHIVE" "$ARCHIVE"
if ! HOGUE_NO_PAUSE=1 "$POLICY_CHECK" --require-manifest "$ARCHIVE"; then
  rm -f "$ARCHIVE" "$CHECKSUM"
  echo "The published ZIP failed final verification and was removed."
  exit 1
fi

(
  cd "$OUTPUT_DIR"
  /usr/bin/shasum -a 256 "$ARCHIVE_NAME" > "${ARCHIVE_NAME}.sha256"
)

echo "Clean source package created:"
echo "$ARCHIVE"
echo "Archive checksum:"
echo "$CHECKSUM"
/bin/cat "$CHECKSUM"
pause_if_double_clicked
