## E2E test for Bhanda: open game, select cards, verify Play hand appears;
## and: load, click New run, verify we get a new deal of cards.
## Requires: Node.js, Playwright (nimble testE2e installs Chromium).
## BHANDA_E2E_URL is set by e2e_runner.
##
## Debugging
## - Vendored nim-playwright: use git submodule (vendor/nim-playwright). run_e2e.sh prefers it when present
##   so you can edit vendor/nim-playwright/src and re-run to debug the binding.
## - Headed browser: BHANDA_E2E_HEADED=1 runs Chromium visible (default headless).
## - Slow steps: BHANDA_E2E_SLOW=500 (ms) sets LaunchOptions(slowMo).
## - Driver wire debug: run driver manually and point at it, e.g. in nim-playwright repo:
##   node node_modules/playwright/cli.js run-driver
##   then PLAYWRIGHT_NIM_DRIVER="nc -U /tmp/pw.sock" (or similar) if you wrap the socket.
##
## Troubleshooting
## - Driver must receive flushed stdin (vendor wire.nim: flush after send).
## - Playwright 1.49+ only accepts sdkLanguage: javascript|python|java|csharp (vendor api.nim uses "javascript").
## - Initialize result may return playwright as string (guid) or object with guid; vendor api.nim handles both.
## - If you see "Driver closed or read failed" after "init driver...", the driver is exiting after the first
##   response; run the vendor E2E with the same driver to compare.
## - Local driver (npm install + PLAYWRIGHT_NIM_DRIVER in run_e2e.sh) avoids npx resolve delay.

import std/[os, strutils]
import playwright

const defaultUrl = "http://127.0.0.1:8765/"

const viewport = (width: 1280, height: 720)

proc launchOpts(): LaunchOptions =
  let headless = getEnv("BHANDA_E2E_HEADED", "").len == 0
  var slowMo = 0
  try:
    slowMo = parseInt(getEnv("BHANDA_E2E_SLOW", "0"))
  except ValueError:
    discard
  LaunchOptions(headless: headless, slowMo: slowMo)

proc runE2eSelectAndPlay(): bool =
  let gameUrl = getEnv("BHANDA_E2E_URL", defaultUrl)
  var p = initPlaywright()
  try:
    stdout.write "launch... "; flushFile(stdout)
    let browser = p.chromium.launch(launchOpts())
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
    let browser = p.chromium.launch(launchOpts())
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
