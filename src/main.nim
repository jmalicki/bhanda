## Main entry point for Bhanda (browser).
## Compile with: nim js -o:bhanda.js src/main.nim

when defined(js):
  import std/dom
  import std/strutils
  import game
  import round
  import blinds
  import shop
  import ui

  var gRunState: RunState   ## Run-level state (progress, money, deck, Jokers).
  var gRoundState: RoundState  ## Current round (hand, deck, target).
  var gSelected: seq[int]  ## Indices of cards currently selected for play (max 5).
  var gMode: string = "round"  ## "round" | "shop" | "win" | "lose".

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
    of HandConsumed:
      discard
    of GameOver:
      gMode = "lose"
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
    render()

  proc run() =
    ## Initialize state, draw first round, and attach click handler for cards / Play / Next.
    gRunState = initRunState()
    startNewRound()
    let el = document.getElementById("game")
    if not el.isNil:
      el.addEventListener("click", proc(ev: Event) =
        let target = ev.target
        if target.isNil: return
        let dataIndex = target.getAttribute("data-index")
        let dataPlay = target.getAttribute("data-play")
        let dataNext = target.getAttribute("data-next")
        if dataPlay != "": onPlayHand()
        elif dataNext != "": startNewRound()
        elif dataIndex != "":
          let idx = parseInt($dataIndex)
          let pos = gSelected.find(idx)
          if pos >= 0: gSelected.del(pos)
          elif gSelected.len < 5: gSelected.add(idx)
          render()
      )
  run()
else:
  discard
