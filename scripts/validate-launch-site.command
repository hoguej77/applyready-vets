#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
SITE_DIR="$ROOT_DIR/launch-site"
MODE="${1:---draft}"

if [[ "$MODE" != "--draft" && "$MODE" != "--release" ]]; then
  echo "Usage: validate-launch-site.command [--draft|--release]"
  exit 2
fi

required_files=(
  README.md
  styles.css
  index.html
  support.html
  privacy.html
  terms.html
  sources.html
)

problems=0
for name in "${required_files[@]}"; do
  if [[ ! -s "$SITE_DIR/$name" ]]; then
    echo "FAIL: missing or empty launch-site/$name"
    problems=$((problems + 1))
  fi
done

for page in "$SITE_DIR"/*.html; do
  for required in '<html lang="en">' '<meta charset="utf-8">' 'name="viewport"' 'skip-link' '<main id="main">'; do
    if ! grep -Fq "$required" "$page"; then
      echo "FAIL: ${page:t} is missing $required"
      problems=$((problems + 1))
    fi
  done
done

for href in index.html support.html privacy.html terms.html sources.html styles.css; do
  if ! grep -R -Fq "$href" "$SITE_DIR" --include='*.html'; then
    echo "FAIL: no page references $href"
    problems=$((problems + 1))
  fi
done

if [[ "$MODE" == "--release" ]]; then
  if grep -R -En '\[FINAL [^]]+\]|DRAFT|NOT FOR PUBLICATION|noindex,nofollow' "$SITE_DIR" --include='*.html' --include='*.md'; then
    echo "FAIL: release validation found draft markers, placeholders, or noindex directives."
    problems=$((problems + 1))
  fi

  if ! grep -R -Eq 'mailto:[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' "$SITE_DIR" --include='*.html'; then
    echo "FAIL: release validation requires a valid monitored domain email."
    problems=$((problems + 1))
  fi
fi

if (( problems > 0 )); then
  echo "RESULT: launch-site validation failed with $problems problem(s)."
  exit 1
fi

if [[ "$MODE" == "--draft" ]]; then
  echo "PASS: launch-site draft structure is complete. Publication remains blocked by intentional legal/company placeholders."
else
  echo "PASS: launch-site release structure contains no known draft markers. Independent review and live HTTPS verification still apply."
fi

