#!/usr/bin/env bash
# Build E2E binaries (server wrapper, launcher, runner, test), then run launcher
# (blocks until server ready or failed), then runner (runs test, kills server).
# Timeout 120s. Use local Playwright (npm install) so driver starts without npx delay.
set -e
cd "$(dirname "$0")/.."
export PATH="${HOME}/.nimble/bin:${PATH:-}"

if [ -f node_modules/playwright/package.json ]; then
  export PLAYWRIGHT_NIM_DRIVER="node node_modules/playwright/cli.js run-driver"
fi

mkdir -p build
# nimhttpd compiles with "style.css".slurp relative to its package dir; ensure it exists
NIMHTTPD_DIR="$(nimble path nimhttpd)"
[ -f style.css ] && cp style.css "$NIMHTTPD_DIR/"
nim c -o:build/e2e_server tests/e2e_server.nim
nim c -o:build/e2e_serve tests/e2e_serve.nim
nim c -o:build/e2e_runner tests/e2e_runner.nim

# Prefer vendored nim-playwright (submodule) so we can debug; else use nimble path
if [ -d vendor/nim-playwright/src ]; then
  PLAYWRIGHT_SRC="$(cd "$(dirname "$0")/.." && pwd)/vendor/nim-playwright/src"
else
  PLAYWRIGHT_SRC="$(nimble path nim_playwright)/src"
fi
nim c -o:build/e2e_bhanda -p:"$PLAYWRIGHT_SRC" tests/e2e_bhanda.nim

# Launcher does not return until server is ready or failed; outputs "PORT PID"
./build/e2e_serve > build/e2e_serve.out
read -r E2E_PORT E2E_PID < build/e2e_serve.out
export BHANDA_E2E_URL="http://127.0.0.1:${E2E_PORT}/"
export SERVER_PID="$E2E_PID"
exec timeout 120 ./build/e2e_runner
