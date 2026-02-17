# Package

version       = "0.1.0"
author        = "Bhanda"
description   = "Bhanda: poker roguelike deck-builder in Nim (browser)"
license       = "MIT"
srcDir        = "src"
binDir        = "."

# Dependencies: karax for browser UI; nim-playwright for E2E (includes serve/serve_wait)
requires "karax"
requires "https://github.com/jmalicki/nim-playwright#head"

# Tasks (all compilation output goes into build/, which is gitignored)

task buildjs, "Build JavaScript bundle for browser":
  exec "mkdir -p build"
  exec "nim js -d:release -o:build/bhanda.js src/main.nim"

task deploy, "Build and copy bhanda.js to docs/ for GitHub Pages (playable in browser)":
  exec "mkdir -p build"
  exec "nim js -d:release -o:build/bhanda.js src/main.nim"
  exec "cp build/bhanda.js docs/bhanda.js"

task test, "Run all tests (C backend)":
  exec "mkdir -p build"
  exec "nim c -o:build/run_tests -r tests/run_tests.nim"

task testE2e, "E2E test with Playwright (builds JS, serves docs/ via nim-playwright serve, runs browser test; needs Node)":
  exec "nimble buildjs"
  exec "cp build/bhanda.js docs/bhanda.js"
  exec "npm install"
  exec "npx -y playwright install chromium"
  exec "bash tests/run_e2e.sh"

task lint, "Run compiler check on source and tests":
  exec "mkdir -p build"
  exec "nim check -o:build/cards src/cards.nim"
  exec "nim check -o:build/poker src/poker.nim"
  exec "nim check -o:build/scoring src/scoring.nim"
  exec "nim check -o:build/round src/round.nim"
  exec "nim check -o:build/blinds src/blinds.nim"
  exec "nim check -o:build/shop src/shop.nim"
  exec "nim check -o:build/game src/game.nim"
  exec "nim check -o:build/card_svg src/card_svg.nim"
  exec "nim check -o:build/storage src/storage.nim"
  exec "nim check -o:build/main src/main.nim"
  exec "nim check -o:build/run_tests tests/run_tests.nim"

task format, "Format source and tests with nimpretty":
  exec "nimpretty src/*.nim tests/*.nim"
