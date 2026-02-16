#!/usr/bin/env bash
# Build E2E binary and runner, then run E2E (runner finds port, starts nimhttpd, runs test).
# Port and server logic live in Nim (tests/e2e_runner.nim). Timeout 120s.
# Use local Playwright (npm install) so driver starts without npx resolve delay.
set -e
cd "$(dirname "$0")/.."
export PATH="${HOME}/.nimble/bin:${PATH:-}"

if [ -f node_modules/playwright/package.json ]; then
  export PLAYWRIGHT_NIM_DRIVER="node node_modules/playwright/cli.js run-driver"
fi

mkdir -p build
nim c -o:build/e2e_runner tests/e2e_runner.nim
nim c -o:build/e2e_bhanda -p:vendor/nim-playwright/src tests/e2e_bhanda.nim
exec timeout 120 ./build/e2e_runner
