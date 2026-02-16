#!/usr/bin/env bash
# Build E2E binary and runner, then run E2E (runner finds port, starts nimhttpd, runs test).
# Port and server logic live in Nim (tests/e2e_runner.nim). Timeout 90s to avoid hangs.
set -e
cd "$(dirname "$0")/.."
export PATH="${HOME}/.nimble/bin:${PATH:-}"

mkdir -p build
nim c -o:build/e2e_runner tests/e2e_runner.nim
nim c -o:build/e2e_bhanda -p:vendor/nim-playwright/src tests/e2e_bhanda.nim
exec timeout 90 ./build/e2e_runner
