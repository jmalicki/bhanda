# Package

version       = "0.1.0"
author        = "Bhanda"
description   = "Bhanda: poker roguelike deck-builder in Nim (browser)"
license       = "MIT"
srcDir        = "src"
binDir        = "."

# Dependencies (none required for JS build)

# Tasks

task buildjs, "Build JavaScript bundle for browser":
  exec "nim js -d:release -o:bhanda.js src/main.nim"

task deploy, "Build and copy bhanda.js to docs/ for GitHub Pages (playable in browser)":
  exec "nim js -d:release -o:bhanda.js src/main.nim"
  exec "cp bhanda.js docs/bhanda.js"

task test, "Run all tests (C backend)":
  exec "nim c -r tests/run_tests.nim"

task lint, "Run compiler check on source and tests":
  exec "nim check src/cards.nim"
  exec "nim check src/poker.nim"
  exec "nim check src/scoring.nim"
  exec "nim check src/round.nim"
  exec "nim check src/blinds.nim"
  exec "nim check src/shop.nim"
  exec "nim check src/game.nim"
  exec "nim check src/card_svg.nim"
  exec "nim check src/ui.nim"
  exec "nim check src/main.nim"
  exec "nim check tests/run_tests.nim"

task format, "Format source and tests with nimpretty":
  exec "nimpretty src/*.nim tests/*.nim"
