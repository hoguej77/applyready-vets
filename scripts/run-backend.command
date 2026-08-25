#!/bin/zsh

source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

if [[ ! -x "$BACKEND/.venv/bin/uvicorn" ]]; then
  echo "Backend is not set up yet. Running setup first…"
  HOGUE_NO_PAUSE=1 "$SCRIPT_DIR/setup.command"
fi

echo "Starting ApplyReady Vets at http://127.0.0.1:8000"
echo "API documentation: http://127.0.0.1:8000/docs"
echo "Keep this window open. Press Control-C to stop."
cd "$BACKEND"
exec .venv/bin/uvicorn app.main:app --env-file .env --host 127.0.0.1 --port 8000
