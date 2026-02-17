#!/usr/bin/env bash
# Build E2E binaries, run server launcher (blocks until ready), then runner (runs test, kills server).
# Timeout 120s. Use local Playwright (npm install) so driver starts without npx delay.
set -e
cd "$(dirname "$0")/.."
export PATH="${HOME}/.nimble/bin:${PATH:-}"

if [ -f node_modules/playwright/package.json ]; then
  export PLAYWRIGHT_NIM_DRIVER="node node_modules/playwright/cli.js run-driver"
fi

mkdir -p build

# Prefer vendored nim-playwright (submodule); else use nimble path
if [ -d vendor/nim-playwright/src ]; then
  PLAYWRIGHT_SRC="$(cd "$(dirname "$0")/.." && pwd)/vendor/nim-playwright/src"
  PLAYWRIGHT_ROOT="$(cd "$(dirname "$0")/.." && pwd)/vendor/nim-playwright"
  # Build nim-playwright's serve and serve_wait into our build dir
  (cd "$PLAYWRIGHT_ROOT" && nimble buildServe 2>/dev/null) || true
  (cd "$PLAYWRIGHT_ROOT" && nimble buildServeWait 2>/dev/null) || true
  SERVE_BIN="$PLAYWRIGHT_ROOT/tools/nimplaywright-serve"
  SERVE_WAIT_BIN="$PLAYWRIGHT_ROOT/tools/nimplaywright-serve-wait"
else
  PLAYWRIGHT_ROOT="$(nimble path nim_playwright)"
  PLAYWRIGHT_SRC="$PLAYWRIGHT_ROOT/src"
  (cd "$PLAYWRIGHT_ROOT" && nimble buildServe 2>/dev/null) || true
  (cd "$PLAYWRIGHT_ROOT" && nimble buildServeWait 2>/dev/null) || true
  SERVE_BIN="$PLAYWRIGHT_ROOT/tools/nimplaywright-serve"
  SERVE_WAIT_BIN="$PLAYWRIGHT_ROOT/tools/nimplaywright-serve-wait"
fi

nim c -o:build/e2e_runner tests/e2e_runner.nim
nim c -o:build/e2e_bhanda -p:"$PLAYWRIGHT_SRC" tests/e2e_bhanda.nim

# Launcher does not return until server is ready or failed; outputs "PORT PID"
export PLAYWRIGHT_SERVE_BIN="$SERVE_BIN"
"$SERVE_WAIT_BIN" docs > build/e2e_serve.out
read -r E2E_PORT E2E_PID < build/e2e_serve.out
export BHANDA_E2E_URL="http://127.0.0.1:${E2E_PORT}/"
export SERVER_PID="$E2E_PID"
exec timeout 120 ./build/e2e_runner
