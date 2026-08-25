#!/bin/zsh

source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

if curl -fsS http://127.0.0.1:8000/v1/health >/dev/null 2>&1; then
  echo "Backend is already running."
  exit 0
fi

if [[ ! -x "$BACKEND/.venv/bin/uvicorn" ]]; then
  HOGUE_NO_PAUSE=1 "$SCRIPT_DIR/setup.command"
fi

cd "$BACKEND"
nohup .venv/bin/uvicorn app.main:app --env-file .env --host 127.0.0.1 --port 8000 \
  >"$LOGS/backend.log" 2>&1 &
echo $! > "$LOGS/backend.pid"

for _ in {1..30}; do
  if curl -fsS http://127.0.0.1:8000/v1/health >/dev/null 2>&1; then
    echo "Backend started (PID $(cat "$LOGS/backend.pid"))."
    exit 0
  fi
  sleep 0.25
done

echo "Backend did not become ready. See $LOGS/backend.log"
exit 1
