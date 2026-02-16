## Main entry point for Bhanda (browser).
## Bootstraps app state from storage and mounts the UI.
## Compiles with: nim js -o:bhanda.js src/main.nim

when defined(js):
  include karax/prelude
  import std/options
  import app
  import storage
  import ui

  proc run() =
    let loaded = loadState()
    if loaded.isSome:
      applyLoaded(loaded.get())
    else:
      initNewRun()
    setRenderer(createDom, "game")

  run()
else:
  discard
