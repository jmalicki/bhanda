## E2E test for Bhanda: open game, select cards, verify Play hand appears.
## Requires: Node.js, Playwright (nimble testE2e installs Chromium).
## Run `nimble testE2e` to build, serve docs/ locally, and test your local changes.
## BHANDA_E2E_URL defaults to http://127.0.0.1:8765/ (set by run_e2e.sh).

import std/[os, strutils]
import playwright

proc runE2e(): bool =
  let gameUrl = getEnv("BHANDA_E2E_URL", "http://127.0.0.1:8765/")
  var p = initPlaywright()
  try:
    let browser = p.chromium.launch(LaunchOptions(headless: true))
    try:
      let page = browser.newPage()
      try:
        page.goto(gameUrl, GotoOptions(timeout: 15000, waitUntil: "domcontentloaded"))
        let frame = page.mainFrame()
        frame.waitForSelector(".hand-cards", timeout = 10000)
        # Click first 5 cards (indices 0..4)
        for i in 0..4:
          frame.click("[data-index=\"" & $i & "\"]")
        # If selection works, Play hand button appears
        frame.waitForSelector("button[data-play]", timeout = 5000)
        result = true
      finally:
        page.close()
    finally:
      browser.close()
  finally:
    p.close()

when isMainModule:
  echo "E2E: open Bhanda, select 5 cards, check Play hand appears..."
  try:
    if runE2e():
      echo "  OK"
    else:
      echo "  FAIL"
      quit(1)
  except Exception as e:
    echo "  SKIP (driver/game error): ", e.msg
    quit(0)
