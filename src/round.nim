## Round state machine: start round, play hand, refill, game over.
## Tracks hands left, discards left, current hand cards, and deck.

import std/sets
import cards
import poker
import scoring

type
  RoundState* = object
    ## State for one round: hand cards, deck, target, and Jokers for scoring.
    handsLeft*: int
    discardsLeft*: int
    hand*: seq[Card]
    deck*: Deck
    targetChips*: int
    jokers*: seq[Joker]

  PlayResult* = enum
    ## Outcome of playing a hand: win round, use a hand and continue, or game over.
    RoundWon, HandConsumed, GameOver

proc startRound*(handsPerRound: int; discardsPerRound: int; targetChips: int;
    deck: Deck; jokers: seq[Joker]; seed: int = 0): RoundState =
  ## Initialize a new round: shuffle deck, draw initial hand (8 cards), set hands/discards.
  var d = deck
  d.shuffle(seed)
  let initialDraw = d.draw(8)
  result.handsLeft = handsPerRound
  result.discardsLeft = discardsPerRound
  result.hand = @initialDraw
  result.deck = d
  result.targetChips = targetChips
  result.jokers = jokers

proc playHand*(rs: var RoundState; selectedIndices: seq[int]): PlayResult =
  ## Play 5 selected cards (by index in rs.hand). If score >= targetChips, RoundWon.
  ## Else consume one hand, remove the 5, draw 5; return HandConsumed or GameOver.
  if selectedIndices.len != 5: return GameOver
  if rs.handsLeft <= 0: return GameOver
  var selected: seq[Card]
  for i in selectedIndices:
    if i < 0 or i >= rs.hand.len: return GameOver
    selected.add rs.hand[i]
  let kind = detectPokerHand(selected)
  let score = computeScore(kind, selected, rs.jokers)
  if score >= rs.targetChips:
    return RoundWon
  rs.handsLeft -= 1
  var newHand: seq[Card]
  let chosen = toHashSet(selectedIndices)
  for i in 0 ..< rs.hand.len:
    if i notin chosen: newHand.add rs.hand[i]
  let drawn = rs.deck.draw(5)
  for c in drawn: newHand.add c
  rs.hand = newHand
  if rs.handsLeft <= 0 or rs.hand.len < 5: return GameOver
  HandConsumed

proc discardCards*(rs: var RoundState; indices: seq[int]): bool =
  ## Discard the selected cards and draw that many from the deck. Uses one discard. Returns false if invalid.
  if rs.discardsLeft <= 0: return false
  if indices.len <= 0 or indices.len > rs.hand.len: return false
  var chosen = toHashSet(indices)
  for i in indices:
    if i < 0 or i >= rs.hand.len: return false
  var newHand: seq[Card]
  for i in 0 ..< rs.hand.len:
    if i notin chosen: newHand.add rs.hand[i]
  let drawn = rs.deck.draw(indices.len)
  for c in drawn: newHand.add c
  rs.hand = newHand
  rs.discardsLeft -= 1
  true
