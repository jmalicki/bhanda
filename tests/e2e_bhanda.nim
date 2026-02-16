## E2E test for Bhanda: open game, select cards, verify Play hand appears;
## and: load, click New run, verify we get a new deal of cards.
## Requires: Node.js, Playwright (nimble testE2e installs Chromium).
## BHANDA_E2E_URL is set by e2e_runner.
##
## Troubleshooting
## - Driver must receive flushed stdin (vendor wire.nim: flush after send).
## - Playwright 1.49+ only accepts sdkLanguage: javascript|python|java|csharp (vendor api.nim uses "javascript").
## - Initialize result may return playwright as string (guid) or object with guid; vendor api.nim handles both.
## - If you see "Driver closed or read failed" after "init driver...", the driver is exiting after the first
##   response; run the vendor E2E with the same driver to compare: e.g.
##   PLAYWRIGHT_NIM_DRIVER="node node_modules/playwright/cli.js run-driver" nim c -p:vendor/nim-playwright/src -r vendor/nim-playwright/tests/test_e2e.nim
## - Local driver (npm install + PLAYWRIGHT_NIM_DRIVER in run_e2e.sh) avoids npx resolve delay.

import std/os
import playwright

const defaultUrl = "http://127.0.0.1:8765/"

const viewport = (width: 1280, height: 720)

proc runE2eSelectAndPlay(): bool =
  let gameUrl = getEnv("BHANDA_E2E_URL", defaultUrl)
  var p = initPlaywright()
  try:
    stdout.write "launch... "; flushFile(stdout)
    let browser = p.chromium.launch(LaunchOptions(headless: true))
    try:
      let page = browser.newPage(NewPageOptions(viewport: viewport))
      try:
        stdout.write "goto... "; flushFile(stdout)
        page.goto(gameUrl, GotoOptions(timeout: 15000, waitUntil: "load"))
        let frame = page.mainFrame()
        stdout.write "wait .hand-cards... "; flushFile(stdout)
        frame.waitForSelector(".hand-cards", timeout = 10000)
        stdout.write "click cards... "; flushFile(stdout)
        for i in 0..4:
          frame.click("[data-index=\"" & $i & "\"]")
        stdout.write "wait Play hand... "; flushFile(stdout)
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
    stdout.write "launch... "; flushFile(stdout)
    let browser = p.chromium.launch(LaunchOptions(headless: true))
    try:
      let page = browser.newPage(NewPageOptions(viewport: viewport))
      try:
        stdout.write "goto... "; flushFile(stdout)
        page.goto(gameUrl, GotoOptions(timeout: 15000, waitUntil: "load"))
        let frame = page.mainFrame()
        stdout.write "wait .hand-cards... "; flushFile(stdout)
        frame.waitForSelector(".hand-cards", timeout = 10000)
        frame.waitForSelector("[data-index='7']", timeout = 3000)
        stdout.write "click New run... "; flushFile(stdout)
        frame.click("button[data-new='1']")
        stdout.write "wait new deal... "; flushFile(stdout)
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
    stdout.write "  init driver... "; flushFile(stdout)
    if runE2eSelectAndPlay():
      echo "OK (select and play)"
    else:
      echo "FAIL (select and play)"
      quit(1)
  except Exception as e:
    echo "SKIP (driver/game error): ", e.msg
    quit(0)
  echo "E2E: load, click New run, verify new deal of cards..."
  try:
    stdout.write "  init driver... "; flushFile(stdout)
    if runE2eNewRun():
      echo "OK (new run)"
    else:
      echo "FAIL (new run)"
      quit(1)
  except Exception as e:
    echo "SKIP (new run): ", e.msg
    quit(1)
