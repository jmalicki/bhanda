## Property-based tests: invariants over hands, jokers, and round states.
## Quickcheck drives choices directly via compact encodings (ints); we decode and run the property.

import std/[random, unittest, options, math]
import ../src/cards
import ../src/poker
import ../src/scoring
import ../src/round
import ../src/shop
import property_ai

const trials = 300

## --- Compact choice encodings (quickcheck samples these directly) ---
## Play: which 5 cards from 8. C(8,5)=56 so one int 0..55.
const playChoiceMax = 55  # C(8,5)-1

func binom(n, k: int): int =
  if k < 0 or k > n: return 0
  if k == 0 or k == n: return 1
  result = 1
  for i in 0 ..< k: result = result * (n - i) div (i + 1)

func unrankCombination(rank: int; n, k: int): seq[int] =
  ## rank in 0 .. binom(n,k)-1 → k indices in 0..n-1 (lex order).
  var r = max(0, rank)
  let total = binom(n, k)
  if total <= 0 or r >= total: return @[]
  if k == 0: return @[]
  for a in 0 .. (n - k):
    let c = binom(n - 1 - a, k - 1)
    if r < c:
      let rest = unrankCombination(r, n - 1 - a, k - 1)
      result = @[a]
      for x in rest: result.add(x + a + 1)
      return result
    r -= c
  @[]

proc playIndicesFromChoice*(choice: int; handLen: int): seq[int] =
  ## Decode compact play choice (0..playChoiceMax for handLen=8) → 5 indices.
  if handLen < 5: return @[]
  let maxRank = binom(handLen, 5) - 1
  unrankCombination(min(choice, max(0, maxRank)), handLen, 5)

## Discard: which subset of 8 cards. 2^8=256 so one int 0..255.
const discardChoiceMax = 255

proc discardIndicesFromChoice*(choice: int; handLen: int): seq[int] =
  ## Bit i set → discard index i. handLen caps which bits we use.
  result = @[]
  for i in 0 ..< min(handLen, 16):
    if (choice and (1 shl i)) != 0:
      result.add i

## Shop: which subset of 4 items to buy. 2^4=16 so one int 0..15. Buy in descending index so deletes don't shift.
const shopChoiceMax = 15

iterator shopPurchaseIndicesFromChoice*(choice: int; numOfferings: int): int =
  ## Yield current-shop indices to buy, in descending order (so each purchase is valid).
  for i in countdown(min(numOfferings, 16) - 1, 0):
    if (choice and (1 shl i)) != 0:
      yield i

proc shopPurchaseOrder*(choice: int; numOfferings: int): seq[int] =
  for i in shopPurchaseIndicesFromChoice(choice, numOfferings): result.add i

## --- Generators that need a seed (deck order, joker set, levels) ---
proc fiveCards*(seed: int): seq[Card] =
  var d = newDeck()
  d.shuffle(seed)
  d.draw(5)

proc jokers*(seed: int; maxLen: int = 5): seq[Joker] =
  let catalog = shopCatalog
  var r = initRand(seed)
  let n = r.rand(maxLen + 1)
  for _ in 0 ..< n:
    let hi = catalog.len - 1
    let i = r.rand(0 .. hi)
    result.add catalog[i].joker

proc handLevels*(seed: int): array[PokerHandKind, int] =
  var r = initRand(seed)
  for k in PokerHandKind:
    result[k] = r.rand(1 .. 5)

proc shopOfferings*(seed: int; count: int): ShopState =
  let catalog = shopCatalog
  var r = initRand(seed)
  var indices = newSeq[int](catalog.len)
  for i in 0 ..< catalog.len: indices[i] = i
  shuffle(r, indices)
  let n = min(count, catalog.len)
  result.items = newSeq[ShopItem](n)
  for i in 0 ..< n:
    result.items[i] = catalog[indices[i]]

## Quickcheck: drive choices directly (compact ints). Optionally also a seed for deck/jokers/levels.
template quickcheck(name: string, body: untyped) =
  test name:
    randomize()
    for _ in 0 ..< trials:
      let seed {.inject.} = rand(1 .. 1_000_000_000)
      body

template quickcheckAi(name: string; body: untyped) =
  test name:
    randomize()
    for _ in 0 ..< trials:
      let seed {.inject.} = rand(1 .. 1_000_000_000)
      let dispersion {.inject.} = rand(0 .. dispersionMax)
      let strategy {.inject.} = rand(0 .. strategyMax)
      let risk {.inject.} = rand(0 .. riskMax)
      let discardsBeforePlay {.inject.} = rand(0 .. discardsBeforePlayMax)
      let params {.inject.} = AiParams(dispersion: dispersion, strategy: strategy, risk: risk, discardsBeforePlay: discardsBeforePlay)
      body

suite "property: scoring":
  quickcheck "score is non-negative for any hand kind, 5 cards, jokers, levels":
    let cards = fiveCards(seed)
    let jokers = jokers(seed + 1)
    let levels = handLevels(seed + 2)
    for kind in PokerHandKind:
      let s = computeScore(kind, cards, jokers, levels)
      if s < 0:
        echo "Counterexample seed: ", seed
      check s >= 0

  quickcheck "adding non-negative AddChips joker never decreases score":
    let cards = fiveCards(seed)
    let j = jokers(seed + 1)
    let levels = handLevels(seed + 2)
    for kind in PokerHandKind:
      let baseScore = computeScore(kind, cards, j, levels)
      let extra = Joker(name: "+C", effect: AddChips, value: (seed + ord(kind)) mod 101)
      let withExtra = computeScore(kind, cards, j & extra, levels)
      if withExtra < baseScore:
        echo "Counterexample seed: ", seed
      check withExtra >= baseScore

  quickcheck "adding non-negative AddMult joker never decreases score":
    let cards = fiveCards(seed)
    let j = jokers(seed + 1)
    let levels = handLevels(seed + 2)
    for kind in PokerHandKind:
      let baseScore = computeScore(kind, cards, j, levels)
      let extra = Joker(name: "+M", effect: AddMult, value: (seed + ord(kind)) mod 6)
      let withExtra = computeScore(kind, cards, j & extra, levels)
      if withExtra < baseScore:
        echo "Counterexample seed: ", seed
      check withExtra >= baseScore

  quickcheck "MultMult with value >= 1 never decreases score (when base score positive)":
    let cards = fiveCards(seed)
    let j = jokers(seed + 1)
    let levels = handLevels(seed + 2)
    for kind in PokerHandKind:
      let baseScore = computeScore(kind, cards, j, levels)
      if baseScore > 0:
        let extra = Joker(name: "xM", effect: MultMult, value: 1 + (seed + ord(kind)) mod 4)
        let withExtra = computeScore(kind, cards, j & extra, levels)
        check withExtra >= baseScore

  quickcheck "same inputs give same score (determinism)":
    let cards = fiveCards(seed)
    let j = jokers(seed + 1)
    let levels = handLevels(seed + 2)
    for kind in PokerHandKind:
      let a = computeScore(kind, cards, j, levels)
      let b = computeScore(kind, cards, j, levels)
      check a == b

suite "property: hand detection":
  quickcheck "detectPokerHand yields valid kind; base chips and mult are positive":
    let cards = fiveCards(seed)
    let kind = detectPokerHand(cards)
    let (chips, mult) = baseChipsAndMult(kind)
    check chips > 0
    check mult > 0

  quickcheck "same 5 cards (any order) give same hand kind":
    var cards = fiveCards(seed)
    let k1 = detectPokerHand(cards)
    var r = initRand(seed + 999)
    shuffle(r, cards)
    let k2 = detectPokerHand(cards)
    check k1 == k2

suite "property: round":
  quickcheckAi "playHand after AI (high target) consumes one hand or game over":
    var d = newDeck()
    d.shuffle(seed)
    var rs = startRound(4, 2, 999_999, d, @[], none(PokerHandKind), default(array[PokerHandKind, int]), seed)
    let playIndices = aiDiscardAndPlay(rs, params, seed)
    if playIndices.len == 5:
      let handsBefore = rs.handsLeft
      let res = rs.playHand(playIndices)
      if res == HandConsumed:
        check rs.handsLeft == handsBefore - 1
      elif res == GameOver:
        check rs.handsLeft <= 0 or rs.hand.len < 5

  quickcheckAi "playHand after AI with target 0 returns RoundWon":
    var d = newDeck()
    d.shuffle(seed)
    var rs = startRound(4, 2, 0, d, @[], none(PokerHandKind), default(array[PokerHandKind, int]), seed)
    let playIndices = aiDiscardAndPlay(rs, params, seed)
    if playIndices.len == 5:
      let res = rs.playHand(playIndices)
      check res == RoundWon

  quickcheckAi "for any AI params, playHand outcome is valid and state consistent":
    var d = newDeck()
    d.shuffle(seed)
    var rs = startRound(4, 2, 50000, d, jokers(seed + 2), none(PokerHandKind), handLevels(seed + 3), seed)
    let playIndices = aiDiscardAndPlay(rs, params, seed)
    if playIndices.len == 5:
      let handsBefore = rs.handsLeft
      let handSizeBefore = rs.hand.len
      let res = rs.playHand(playIndices)
      check res in {RoundWon, HandConsumed, GameOver}
      if res == HandConsumed:
        check rs.handsLeft == handsBefore - 1
        check rs.hand.len == handSizeBefore

  quickcheck "discardCards with valid indices decreases discardsLeft by 1":
    var d = newDeck()
    d.shuffle(seed)
    var rs = startRound(4, 2, 300, d, @[], none(PokerHandKind), default(array[PokerHandKind, int]), seed)
    let discardsBefore = rs.discardsLeft
    if rs.hand.len >= 1 and discardsBefore >= 1:
      let ok = discardCards(rs, @[0])
      if ok:
        check rs.discardsLeft == discardsBefore - 1

  quickcheckAi "AI discard-and-play leaves consistent state after each discard":
    var d = newDeck()
    d.shuffle(seed)
    var rs = startRound(4, 2, 300, d, @[], none(PokerHandKind), default(array[PokerHandKind, int]), seed)
    let playIndices = aiDiscardAndPlay(rs, params, seed)
    if playIndices.len == 5:
      let res = rs.playHand(playIndices)
      check res in {RoundWon, HandConsumed, GameOver}

suite "property: shop":
  test "cashForBlind is positive and increases with blind index":
    for idx in 0 .. 10:
      let c = cashForBlind(idx)
      check c >= 10
      if idx >= 1:
        check cashForBlind(idx) >= cashForBlind(idx - 1)

  quickcheck "for any shop offerings and choice of which/how many to buy, purchase state is consistent":
    let shop = shopOfferings(seed, 4)
    let order = shopPurchaseOrder(seed + 1, shop.items.len)
    var money = 200
    var sh = shop
    var totalSpent = 0
    var purchases = 0
    for idx in order:
      if sh.items.len == 0: break
      if idx < 0 or idx >= sh.items.len: break
      let price = sh.items[idx].price
      let itemsBefore = sh.items.len
      let before = money
      let ok = purchase(sh, idx, money)
      if ok:
        totalSpent += price
        purchases += 1
        check money == before - price
        check sh.items.len == itemsBefore - 1
      else:
        check money == before
    check money == 200 - totalSpent
