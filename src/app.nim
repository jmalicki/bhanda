## App state and game logic (actions).
## No UI: state vars and handlers that mutate them; UI imports this and reads state / calls procs.

when defined(js):
  import std/options
  import std/strutils
  import std/sugar
  import game
  import round
  import blinds
  import shop
  import storage

  var gRunState*: RunState
  var gRoundState*: RoundState
  var gShopState*: ShopState
  var gSelected*: seq[int]
  var gMode*: GameMode = ModeRound

  const sellPrice* = 2
  const rerollCost* = 1
  const voucherPrice* = 4

  proc saveCurrent*() =
    saveState(gRunState, gRoundState, gMode)

  proc onPlayHand*() =
    if gSelected.len != 5: return
    let selCards = collect(newSeq):
      for idx in gSelected: gRoundState.hand[idx]
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
        gMode = ModeWin
      else:
        gMode = ModeShop
        gShopState = generateOfferings()
      saveCurrent()
    of HandConsumed:
      saveCurrent()
    of GameOver:
      gMode = ModeLose
      clearState()

  proc startNewRound*() =
    if gMode == ModeShop:
      gRunState.money += (gRunState.money * 5) div 100
    gMode = ModeRound
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

  proc doNewRun*() =
    clearState()
    gRunState = initRunState()
    startNewRound()

  proc toggleCard*(i: int) =
    let pos = gSelected.find(i)
    if pos >= 0: gSelected.del(pos)
    elif gSelected.len < 8: gSelected.add(i)

  proc cardClick*(i: int): proc() =
    result = proc() = toggleCard(i)

  proc buyItem*(i: int) =
    if i < 0 or i >= gShopState.items.len: return
    if gRunState.jokers.len >= gRunState.maxJokerSlots: return
    let joker = gShopState.items[i].joker
    if purchase(gShopState, i, gRunState.money):
      gRunState.jokers.add joker

  proc buyClick*(i: int): proc() =
    result = proc() = buyItem(i)

  proc onDiscard*() =
    if gRoundState.discardsLeft <= 0 or gSelected.len == 0: return
    if discardCards(gRoundState, gSelected):
      gSelected = @[]
      gRunState.deck = gRoundState.deck
      saveCurrent()

  proc onSell*(jokerIndex: int) =
    if jokerIndex < 0 or jokerIndex >= gRunState.jokers.len: return
    gRunState.jokers.delete(jokerIndex)
    gRunState.money += sellPrice
    saveCurrent()

  proc sellClick*(i: int): proc() =
    result = proc() = onSell(i)

  proc handLevelsText*(): string =
    let parts = collect(newSeq):
      for k in PokerHandKind:
        if gRunState.handLevels[k] > 1:
          handDisplayName(k) & " " & $gRunState.handLevels[k]
    if parts.len == 0: return ""
    result = parts.join(", ")

  proc onReroll*() =
    if gRunState.money >= rerollCost:
      gRunState.money -= rerollCost
      gShopState = generateOfferings()
      saveCurrent()

  template buyVoucher*(flag: untyped, field: untyped) =
    if not gRunState.flag and gRunState.money >= voucherPrice:
      gRunState.money -= voucherPrice
      gRunState.flag = true
      gRunState.field += 1
      saveCurrent()
  proc onBuyVoucherHand*() = buyVoucher(boughtExtraHand, handsPerRound)
  proc onBuyVoucherDiscard*() = buyVoucher(boughtExtraDiscard, discardsPerRound)
  proc onBuyVoucherJokerSlot*() = buyVoucher(boughtExtraJokerSlot, maxJokerSlots)

  proc handPreview*(): tuple[text: string, score: int] =
    if gSelected.len != 5: return ("", 0)
    let selCards = collect(newSeq):
      for idx in gSelected: gRoundState.hand[idx]
    let kind = detectPokerHand(selCards)
    let score = computeScore(kind, selCards, gRoundState.jokers, gRoundState.handLevels)
    ("Hand: " & handDisplayName(kind) & " — Score: " & $score, score)

  proc checkLoseCondition*() =
    if gMode == ModeRound and gRoundState.hand.len < 5:
      gMode = ModeLose
      clearState()

  proc applyLoaded*(L: LoadedState) =
    gRunState = L.runState
    gRoundState = L.roundState
    gRoundState.minHandKind = if effectForBlind(gRunState.progress) == FlushOrBetter: some(Flush) else: none(PokerHandKind)
    gRoundState.handLevels = gRunState.handLevels
    gMode = L.mode
    gSelected = @[]
    if gMode == ModeShop:
      gShopState = generateOfferings()

  proc initNewRun*() =
    gRunState = initRunState()
    startNewRound()
