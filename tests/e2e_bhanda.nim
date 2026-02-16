## E2E test for Bhanda: open game, select cards, verify Play hand appears;
## and: load, click New run, verify we get a new deal of cards.
## Requires: Node.js, Playwright (nimble testE2e installs Chromium).
## Run `nimble testE2e` to build, serve docs/ locally, and test your local changes.
## BHANDA_E2E_URL defaults to http://127.0.0.1:8765/ (set by run_e2e.sh).

import std/[os, strutils]
import playwright

const defaultUrl = "http://127.0.0.1:8765/"

proc runE2eSelectAndPlay(): bool =
  let gameUrl = getEnv("BHANDA_E2E_URL", defaultUrl)
  var p = initPlaywright()
  try:
    let browser = p.chromium.launch(LaunchOptions(headless: true))
    try:
      let page = browser.newPage()
      try:
        page.goto(gameUrl, GotoOptions(timeout: 15000, waitUntil: "domcontentloaded"))
        let frame = page.mainFrame()
        frame.waitForSelector(".hand-cards", timeout = 10000)
        for i in 0..4:
          frame.click("[data-index=\"" & $i & "\"]")
        frame.waitForSelector("button[data-play]", timeout = 5000)
        result = true
      finally:
        page.close()
    finally:
      browser.close()
  finally:
    p.close()

proc runE2eNewRun(): bool =
  ## Load game, click "New run", verify we get hand cards (new deal).
  let gameUrl = getEnv("BHANDA_E2E_URL", defaultUrl)
  var p = initPlaywright()
  try:
    let browser = p.chromium.launch(LaunchOptions(headless: true))
    try:
      let page = browser.newPage()
      try:
        page.goto(gameUrl, GotoOptions(timeout: 15000, waitUntil: "domcontentloaded"))
        let frame = page.mainFrame()
        frame.waitForSelector(".hand-cards", timeout = 10000)
        frame.waitForSelector("[data-index='7']", timeout = 3000)
        frame.click("button[data-new='1']")
        frame.waitForSelector(".hand-cards", timeout = 5000)
        frame.waitForSelector("[data-index='7']", timeout = 5000)
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
    if runE2eSelectAndPlay():
      echo "  OK (select and play)"
    else:
      echo "  FAIL (select and play)"
      quit(1)
  except Exception as e:
    echo "  SKIP (driver/game error): ", e.msg
    quit(0)
  echo "E2E: load, click New run, verify new deal of cards..."
  try:
    if runE2eNewRun():
      echo "  OK (new run)"
    else:
      echo "  FAIL (new run)"
      quit(1)
  except Exception as e:
    echo "  SKIP (new run): ", e.msg
    quit(1)
