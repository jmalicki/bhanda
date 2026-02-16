#!/usr/bin/env bash
# Serve docs/ with nimhttpd, then run E2E test against local build.
set -e
cd "$(dirname "$0")/.."
PORT=8765
# Run nimhttpd (from nimble) in background: serve docs/ at PORT
export PATH="${HOME}/.nimble/bin:${PATH:-}"
nimhttpd -p:$PORT -a:127.0.0.1 docs &
SERVPID=$!
cleanup() { kill $SERVPID 2>/dev/null || true; }
trap cleanup EXIT
sleep 1
BHANDA_E2E_URL="http://127.0.0.1:$PORT/" nim c -p:vendor/nim-playwright/src -r tests/e2e_bhanda.nim
