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
  var gShopState: ShopState
  var gSelected: seq[int]
  var gMode: string = "round"

  proc saveCurrent() =
    saveState(gRunState, gRoundState, gMode)

  proc onPlayHand() =
    if gSelected.len != 5: return
    var selCards: seq[Card]
    for idx in gSelected: selCards.add gRoundState.hand[idx]
    let kind = detectPokerHand(selCards)
    let res = gRoundState.playHand(gSelected)
    gSelected = @[]
    case res
    of RoundWon:
      gRunState.handLevels[kind] += 1
      let blindIdx = gRunState.progress.roundInAnte
      gRunState.progress.advanceRound()
      gRunState.money += cashForBlind(blindIdx)
      if gRunState.progress.hasWonRun():
        gMode = "win"
      else:
        gMode = "shop"
        gShopState = generateOfferings()
      saveCurrent()
    of HandConsumed:
      saveCurrent()
    of GameOver:
      gMode = "lose"
      clearState()

  proc startNewRound() =
    if gMode == "shop":
      gRunState.money += (gRunState.money * 5) div 100
    gMode = "round"
    let minHand = if effectForBlind(gRunState.progress) == FlushOrBetter: some(Flush) else: none(PokerHandKind)
    gRoundState = startRound(
      gRunState.handsPerRound,
      gRunState.discardsPerRound,
      gRunState.progress.targetChips,
      gRunState.deck,
      gRunState.jokers,
      minHand,
      gRunState.handLevels)
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
    elif gSelected.len < 8: gSelected.add(i)

  proc cardClick(i: int): proc() =
    result = proc() = toggleCard(i)

  proc buyItem(i: int) =
    if i < 0 or i >= gShopState.items.len: return
    if gRunState.jokers.len >= gRunState.maxJokerSlots: return
    let joker = gShopState.items[i].joker
    if purchase(gShopState, i, gRunState.money):
      gRunState.jokers.add joker

  proc buyClick(i: int): proc() =
    result = proc() = buyItem(i)

  proc onDiscard() =
    if gRoundState.discardsLeft <= 0 or gSelected.len == 0: return
    if discardCards(gRoundState, gSelected):
      gSelected = @[]
      gRunState.deck = gRoundState.deck
      saveCurrent()

  const sellPrice = 2
  proc onSell(jokerIndex: int) =
    if jokerIndex < 0 or jokerIndex >= gRunState.jokers.len: return
    gRunState.jokers.delete(jokerIndex)
    gRunState.money += sellPrice
    saveCurrent()

  proc sellClick(i: int): proc() =
    result = proc() = onSell(i)

  proc handLevelsText(): string =
    var parts: seq[string]
    for k in PokerHandKind:
      if gRunState.handLevels[k] > 1:
        parts.add handDisplayName(k) & " " & $gRunState.handLevels[k]
    if parts.len == 0: return ""
    result = parts[0]
    for i in 1 ..< parts.len: result.add ", "; result.add parts[i]

  const rerollCost = 1
  proc onReroll() =
    if gRunState.money >= rerollCost:
      gRunState.money -= rerollCost
      gShopState = generateOfferings()
      saveCurrent()

  const voucherPrice = 4
  proc onBuyVoucherHand() =
    if not gRunState.boughtExtraHand and gRunState.money >= voucherPrice:
      gRunState.money -= voucherPrice
      gRunState.boughtExtraHand = true
      gRunState.handsPerRound += 1
      saveCurrent()
  proc onBuyVoucherDiscard() =
    if not gRunState.boughtExtraDiscard and gRunState.money >= voucherPrice:
      gRunState.money -= voucherPrice
      gRunState.boughtExtraDiscard = true
      gRunState.discardsPerRound += 1
      saveCurrent()
  proc onBuyVoucherJokerSlot() =
    if not gRunState.boughtExtraJokerSlot and gRunState.money >= voucherPrice:
      gRunState.money -= voucherPrice
      gRunState.boughtExtraJokerSlot = true
      gRunState.maxJokerSlots += 1
      saveCurrent()

  proc sidebar(): VNode =
    result = buildHtml(tdiv(class = "sidebar")):
      tdiv(class = "instructions"):
        h3: text "How to play"
        ul:
          li: text "Select 5 cards to play a hand, or select 1–8 cards and use Discard to draw new ones (limited per round)."
          li:
            text "The "
            strong: text "Score"
            text " shown is your projected score for that selection (0 until you pick 5 cards). "
            strong: text "Target"
            text " is what you need to reach to beat the blind."
          li:
            text "Hit "
            strong: text "Play hand"
            text " — if your score meets the target, you beat the blind and earn $."
          li: text "Spend money in the shop on Jokers, then start the next round."
          li: text "Jokers you buy are always active — they boost every hand's score automatically."
      tdiv(class = "your-jokers"):
        h3: text "Your Jokers (" & $gRunState.jokers.len & "/" & $gRunState.maxJokerSlots & ")"
        if gRunState.jokers.len == 0:
          p(class = "jokers-empty"): text "None yet. Beat a blind, then buy some in the shop."
        else:
          p(class = "jokers-how"): text "Applied automatically to every hand — no button to use."
          ul:
            for j in gRunState.jokers:
              li: text j.name
      if handLevelsText().len > 0:
        tdiv(class = "hand-levels"):
          h3: text "Hand levels"
          p: text handLevelsText()
      tdiv(class = "sidebar-reset"):
        p(class = "sidebar-reset-label"): text "Start over (clears saved progress)"
        button(class = "btn", `data-new` = "1", onclick = doNewRun): text "New run"

  proc handPreview(): tuple[text: string, score: int] =
    if gSelected.len != 5: return ("", 0)
    var selCards: seq[Card]
    for idx in gSelected: selCards.add gRoundState.hand[idx]
    let kind = detectPokerHand(selCards)
    let score = computeScore(kind, selCards, gRoundState.jokers, gRoundState.handLevels)
    ("Hand: " & handDisplayName(kind) & " — Score: " & $score, score)

  proc createDom(): VNode =
    if gMode == "round" and gRoundState.hand.len < 5:
      gMode = "lose"
      clearState()
    let (playHint, projectedScore) = handPreview()
    result = buildHtml(tdiv(class = "game-layout")):
      tdiv(class = "table-wrap"):
        tdiv(class = "table"):
          if gMode == "round":
            tdiv(class = "table-blind"):
              span:
                if effectForBlind(gRunState.progress) == FlushOrBetter:
                  text blindDisplayName(gRunState.progress.currentBlind()) & ": Flush or better"
                else:
                  text blindDisplayName(gRunState.progress.currentBlind())
              span: text "Target"
              span(class = "value"): text $gRoundState.targetChips
              span: text "Score"
              span(class = "value"): text $projectedScore
              span: text "Hands left"
              span(class = "value"): text $gRoundState.handsLeft
              span: text "Discards left"
              span(class = "value"): text $gRoundState.discardsLeft
            tdiv(class = "table-play-zone"):
              if playHint.len > 0:
                span(class = "hint"): text playHint
              else:
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
                if gRoundState.discardsLeft > 0:
                  if gSelected.len >= 1:
                    button(class = "btn btn-secondary", onclick = onDiscard):
                      text "Discard (" & $gSelected.len & ")"
                  else:
                    span(class = "discard-hint"): text "Discard: select 1–8 cards above, then click Discard"
          elif gMode == "shop":
            tdiv(class = "table-shop"):
              tdiv(class = "shop-title"): text "Shop"
              tdiv(class = "shop-money"): text "$" & $gRunState.money
              if gRunState.jokers.len >= gRunState.maxJokerSlots:
                p(class = "shop-slots-full"): text "Joker slots full (" & $gRunState.maxJokerSlots & "/" & $gRunState.maxJokerSlots & "). Sell one to buy more."
              if gRunState.jokers.len > 0:
                tdiv(class = "shop-sell"):
                  p(class = "shop-sell-label"): text "Sell a Joker ($" & $sellPrice & " each):"
                  for i in 0 ..< gRunState.jokers.len:
                    let j = gRunState.jokers[i]
                    button(class = "btn btn-secondary", onclick = sellClick(i)):
                      text j.name & " — Sell ($" & $sellPrice & ")"
              tdiv(class = "shop-vouchers"):
                p(class = "shop-vouchers-label"): text "Vouchers (permanent):"
                if not gRunState.boughtExtraHand:
                  button(class = "btn btn-voucher", onclick = onBuyVoucherHand):
                    text "+1 Hand — $" & $voucherPrice
                if not gRunState.boughtExtraDiscard:
                  button(class = "btn btn-voucher", onclick = onBuyVoucherDiscard):
                    text "+1 Discard — $" & $voucherPrice
                if not gRunState.boughtExtraJokerSlot:
                  button(class = "btn btn-voucher", onclick = onBuyVoucherJokerSlot):
                    text "+1 Joker slot — $" & $voucherPrice
              tdiv(class = "shop-items"):
                for i in 0 ..< gShopState.items.len:
                  let it = gShopState.items[i]
                  if gRunState.jokers.len >= gRunState.maxJokerSlots:
                    button(class = "btn btn-disabled", disabled = true):
                      text it.joker.name & " ($" & $it.price & ")"
                  else:
                    button(class = "btn", onclick = buyClick(i)):
                      text it.joker.name & " ($" & $it.price & ")"
              tdiv(class = "table-actions"):
                if gRunState.money >= rerollCost:
                  button(class = "btn btn-secondary", onclick = onReroll): text "Reroll ($" & $rerollCost & ")"
                button(class = "btn", onclick = startNewRound): text "Skip"
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
      gRoundState.minHandKind = if effectForBlind(gRunState.progress) == FlushOrBetter: some(Flush) else: none(PokerHandKind)
      gRoundState.handLevels = gRunState.handLevels
      gMode = L.mode
      gSelected = @[]
      if gMode == "shop":
        gShopState = generateOfferings()
    else:
      gRunState = initRunState()
      startNewRound()
    setRenderer(createDom, "game")

  run()
else:
  discard
