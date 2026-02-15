## Main entry point for Bhanda (browser).
## Compile with: nim js -o:bhanda.js src/main.nim

when defined(js):
  import std/dom
  import std/strutils
  import std/options
  import game
  import round
  import blinds
  import shop
  import ui
  import storage

  var gRunState: RunState   ## Run-level state (progress, money, deck, Jokers).
  var gRoundState: RoundState  ## Current round (hand, deck, target).
  var gSelected: seq[int]  ## Indices of cards currently selected for play (max 5).
  var gMode: string = "round"  ## "round" | "shop" | "win" | "lose".

  proc saveCurrent() =
    saveState(gRunState, gRoundState, gMode)

  proc render() =
    ## Refresh the DOM for the current mode (round, shop, win, or lose).
    if gMode == "round":
      ui.renderGame(gRoundState.hand, gSelected, 0, gRoundState.targetChips, gRoundState.handsLeft)
    elif gMode == "shop":
      ui.renderShop(@[], gRunState.money)
    elif gMode == "win":
      ui.renderWin()
    elif gMode == "lose":
      ui.renderLose()

  proc onPlayHand() =
    ## Play the 5 selected cards; update state for RoundWon / HandConsumed / GameOver and re-render.
    if gSelected.len != 5: return
    let res = gRoundState.playHand(gSelected)
    gSelected = @[]
    case res
    of RoundWon:
      let blindIdx = gRunState.progress.roundInAnte
      gRunState.progress.advanceRound()
      gRunState.money += cashForBlind(blindIdx)
      if gRunState.progress.hasWonRun():
        gMode = "win"
      else:
        gMode = "shop"
      saveCurrent()
    of HandConsumed:
      saveCurrent()
    of GameOver:
      gMode = "lose"
      clearState()
    render()

  proc startNewRound() =
    ## Start a new round: shuffle, draw 8, set mode to round, and render.
    gMode = "round"
    gRoundState = startRound(
      gRunState.handsPerRound,
      gRunState.discardsPerRound,
      gRunState.progress.targetChips,
      gRunState.deck,
      gRunState.jokers)
    gRunState.deck = gRoundState.deck
    gSelected = @[]
    saveCurrent()
    render()

  proc run() =
    ## State is saved automatically at key points (after play, new round, leave shop). On load, restore from localStorage if present. Reset button clears and starts fresh.
    let loaded = loadState()
    if loaded.isSome:
      let L = loaded.get()
      gRunState = L.runState
      gRoundState = L.roundState
      gMode = L.mode
      gSelected = @[]
      render()
    else:
      gRunState = initRunState()
      startNewRound()
    let el = document.getElementById("game")
    if not el.isNil:
      el.addEventListener("click", proc(ev: Event) =
        # Click might be on SVG/text inside the card div — find ancestor with data-* attributes.
        var node = cast[Element](ev.target)
        if node.isNil and not ev.target.isNil:
          let n = cast[Node](ev.target)
          if not n.isNil and not n.parentElement.isNil: node = n.parentElement
        while not node.isNil:
          let dataIndex = node.getAttribute("data-index")
          let dataPlay = node.getAttribute("data-play")
          let dataNext = node.getAttribute("data-next")
          let dataNew = node.getAttribute("data-new")
          if dataPlay != "":
            onPlayHand()
            return
          if dataNext != "":
            startNewRound()
            return
          if dataNew != "":
            clearState()
            gRunState = initRunState()
            startNewRound()
            return
          if dataIndex != "":
            let idx = parseInt($dataIndex)
            let pos = gSelected.find(idx)
            if pos >= 0: gSelected.del(pos)
            elif gSelected.len < 5: gSelected.add(idx)
            render()
            return
          node = node.parentElement
      )
  run()
else:
  discard
