## Main entry point for Bhanda (browser).
## Uses Karax for UI; compiles with: nim js -o:bhanda.js src/main.nim

when defined(js):
  include karax/prelude
  import std/options
  import game
  import round
  import blinds
  import shop
  import storage
  import card_svg

  var gRunState: RunState
  var gRoundState: RoundState
  var gSelected: seq[int]
  var gMode: string = "round"

  proc saveCurrent() =
    saveState(gRunState, gRoundState, gMode)

  proc onPlayHand() =
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

  proc startNewRound() =
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

  proc doNewRun() =
    clearState()
    gRunState = initRunState()
    startNewRound()

  proc toggleCard(i: int) =
    let pos = gSelected.find(i)
    if pos >= 0: gSelected.del(pos)
    elif gSelected.len < 5: gSelected.add(i)

  proc cardClick(i: int): proc() =
    result = proc() = toggleCard(i)

  proc sidebar(): VNode =
    result = buildHtml(tdiv(class = "sidebar")):
      tdiv(class = "instructions"):
        h3: text "How to play"
        ul:
          li: text "Click 5 cards to select your hand."
          li:
            text "Hit "
            strong: text "Play hand"
            text " — score must meet the target."
          li: text "Beat the blind to earn $ and advance."
          li: text "Spend money in the shop on Jokers, then start the next round."
      tdiv(class = "sidebar-reset"):
        p(class = "sidebar-reset-label"): text "Start over (clears saved progress)"
        button(class = "btn", `data-new` = "1", onclick = doNewRun): text "New run"

  proc createDom(): VNode =
    result = buildHtml(tdiv(class = "game-layout")):
      tdiv(class = "table-wrap"):
        tdiv(class = "table"):
          if gMode == "round":
            tdiv(class = "table-blind"):
              span: text "Target"
              span(class = "value"): text $gRoundState.targetChips
              span: text "Score"
              span(class = "value"): text "0"
              span: text "Hands left"
              span(class = "value"): text $gRoundState.handsLeft
            tdiv(class = "table-play-zone"):
              span(class = "hint"): text "Select 5 cards below to play"
            tdiv(class = "hand-area"):
              tdiv(class = "label"): text "Your hand"
              tdiv(class = "hand-cards"):
                for i in 0 ..< gRoundState.hand.len:
                  let c = gRoundState.hand[i]
                  let sel = gSelected.find(i) >= 0
                  if sel:
                    tdiv(class = "card selected", `data-index` = cstring($i), onclick = cardClick(i)):
                      verbatim(cardToSvg(c))
                  else:
                    tdiv(class = "card", `data-index` = cstring($i), onclick = cardClick(i)):
                      verbatim(cardToSvg(c))
              tdiv(class = "table-actions"):
                if gSelected.len == 5:
                  button(class = "btn", `data-play` = "1", onclick = onPlayHand): text "Play hand"
          elif gMode == "shop":
            tdiv(class = "table-shop"):
              tdiv(class = "shop-title"): text "Shop"
              tdiv(class = "shop-money"): text "$" & $gRunState.money
              tdiv(class = "shop-items"): discard
              tdiv(class = "table-actions"):
                button(class = "btn"): text "Skip"
                button(class = "btn", onclick = startNewRound): text "Next round"
          elif gMode == "win":
            tdiv(class = "end-screen"):
              h2: text "You won!"
              p: text "Run complete."
          else:
            tdiv(class = "end-screen"):
              h2: text "Game over"
              p: text "Better luck next time."
      sidebar()

  proc run() =
    let loaded = loadState()
    if loaded.isSome:
      let L = loaded.get()
      gRunState = L.runState
      gRoundState = L.roundState
      gMode = L.mode
      gSelected = @[]
    else:
      gRunState = initRunState()
      startNewRound()
    setRenderer(createDom, "game")

  run()
else:
  discard
