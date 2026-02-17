## Parameterized toy AI for property tests: slightly biased toward reasonable play.
## Pure: (state, params, seed) → decisions. Dispersion at max → effectively uniform (AI off).

import std/[random, math]
import ../src/cards
import ../src/poker
import ../src/scoring
import ../src/round

const
  dispersionMax* = 3
  strategyMax* = 1
  riskMax* = 2
  discardsBeforePlayMax* = 2
  T_min* = 0.1
  T_max* = 1000.0

type
  AiParams* = object
    dispersion*: int   ## 0 = peaked on best, dispersionMax = uniform (AI off in limit)
    strategy*: int    ## 0 = greedy (score), 1 = card-counting hint
    risk*: int        ## 0 = averse, 1 = neutral, 2 = seeking
    discardsBeforePlay*: int

func binom(n, k: int): int =
  if k < 0 or k > n: return 0
  if k == 0 or k == n: return 1
  result = 1
  for i in 0 ..< k: result = result * (n - i) div (i + 1)

func unrankCombination(rank: int; n, k: int): seq[int] =
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

proc softmaxProbs*(values: seq[float]; temperature: float): seq[float] =
  if values.len == 0: return @[]
  let T = max(temperature, 1e-6)
  var mx = values[0]
  for v in values: mx = max(mx, v)
  result = newSeq[float](values.len)
  var sum = 0.0
  for i in 0 ..< values.len:
    result[i] = exp((values[i] - mx) / T)
    sum += result[i]
  for i in 0 ..< result.len: result[i] /= sum

proc sampleFromProbs*(probs: seq[float]; rng: var Rand): int =
  let u = rng.rand(1.0)
  var cum = 0.0
  for i in 0 ..< probs.len:
    cum += probs[i]
    if u < cum: return i
  result = probs.len - 1

proc scorePlay(hand: seq[Card]; indices: seq[int]; jokers: seq[Joker];
    handLevels: array[PokerHandKind, int]; target: int; strategy, risk: int): float =
  if indices.len != 5: return 0.0
  var five: seq[Card]
  for i in indices:
    if i >= 0 and i < hand.len: five.add hand[i]
  if five.len != 5: return 0.0
  let kind = detectPokerHand(five)
  let score = computeScore(kind, five, jokers, handLevels).float
  let kindBonus = float(ord(kind))
  if strategy == 0:
    result = score
  else:
    result = score + 0.1 * kindBonus
  if risk == 0 and target > 0:
    if score >= target.float: result += 500.0
  elif risk == 2:
    result += 2.0 * kindBonus

proc scoreDiscard(hand: seq[Card]; discardIndices: seq[int]; strategy, risk: int): float =
  if discardIndices.len == 0: return 0.0
  for i in discardIndices:
    if i < 0 or i >= hand.len: return -1e9
  var sumRank = 0
  for i in discardIndices:
    sumRank += rankValue(hand[i].rank)
  result = -float(sumRank)

proc temperatureFromDispersion(dispersion: int): float =
  let d = max(0, min(dispersion, dispersionMax))
  T_min + (T_max - T_min) * float(d) / float(dispersionMax)

proc allPlayActions(handLen: int): seq[seq[int]] =
  let n = binom(handLen, 5)
  for r in 0 ..< n:
    result.add unrankCombination(r, handLen, 5)

proc allDiscardActions(handLen: int): seq[seq[int]] =
  result.add @[]
  for k in 1 .. min(3, handLen - 5):
    let n = binom(handLen, k)
    for r in 0 ..< n:
      result.add unrankCombination(r, handLen, k)

proc aiChoosePlay*(rs: RoundState; params: AiParams; seed: int): seq[int] =
  let handLen = rs.hand.len
  if handLen < 5: return @[]
  let actions = allPlayActions(handLen)
  if actions.len == 0: return @[]
  var values = newSeq[float](actions.len)
  for i in 0 ..< actions.len:
    values[i] = scorePlay(rs.hand, actions[i], rs.jokers, rs.handLevels,
        rs.targetChips, params.strategy, params.risk)
  let T = temperatureFromDispersion(params.dispersion)
  let probs = softmaxProbs(values, T)
  var rng = initRand(seed)
  let idx = sampleFromProbs(probs, rng)
  result = actions[idx]

proc aiChooseDiscard*(rs: RoundState; params: AiParams; seed: int): seq[int] =
  if rs.discardsLeft <= 0: return @[]
  let handLen = rs.hand.len
  let actions = allDiscardActions(handLen)
  if actions.len == 0: return @[]
  var values = newSeq[float](actions.len)
  for i in 0 ..< actions.len:
    values[i] = scoreDiscard(rs.hand, actions[i], params.strategy, params.risk)
  let T = temperatureFromDispersion(params.dispersion)
  let probs = softmaxProbs(values, T)
  var rng = initRand(seed)
  let idx = sampleFromProbs(probs, rng)
  result = actions[idx]

proc aiDiscardAndPlay*(rs: var RoundState; params: AiParams; seed: int): seq[int] =
  var s = seed
  for _ in 0 ..< params.discardsBeforePlay:
    if rs.discardsLeft <= 0 or rs.hand.len < 5: break
    let toDiscard = aiChooseDiscard(rs, params, s)
    s += 1
    if toDiscard.len > 0:
      discard discardCards(rs, toDiscard)
  result = aiChoosePlay(rs, params, s)
