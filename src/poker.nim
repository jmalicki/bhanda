## Poker hand detection and base scoring.
## Given 5 cards, classifies the hand (e.g. Flush, FullHouse) and provides base Chips/Mult.

import std/algorithm
import cards

type
  PokerHandKind* = enum
    ## Best-to-worst hand classification for exactly 5 cards.
    HighCard, Pair, TwoPair, ThreeKind, Straight, Flush, FullHouse, FourKind, StraightFlush

  ChipsMult* = tuple[chips: int, mult: int]
    ## Base chips and mult for a hand type; final score = chips * mult (before Jokers).

proc rankValue(r: Rank): int =
  ## Numeric value for straight comparison. Ace high = 14; ace low (wheel) = 1.
  if r == Ace: 14 else: int(r)

proc isFlush(cards: seq[Card]): bool =
  ## True if all 5 cards share the same suit.
  let s = cards[0].suit
  for c in cards:
    if c.suit != s: return false
  true

proc cardRankOrder(cards: seq[Card]): seq[Card] =
  ## Return a copy of cards sorted by rank (low to high) for straight detection.
  result = @cards
  result.sort(proc(a, b: Card): int = cmp(rankValue(a.rank), rankValue(b.rank)))

proc isStraight(cards: seq[Card]): bool =
  ## Assumes cards sorted by rank. Handles wheel (A-2-3-4-5).
  if cards.len != 5: return false
  let v0 = rankValue(cards[0].rank)
  let v4 = rankValue(cards[4].rank)
  if v4 - v0 == 4: return true
  if v4 == 14 and cards[0].rank == R2 and cards[1].rank == R3 and cards[2].rank == R4 and cards[3].rank == R5: return true
  false

proc countRanks(cards: seq[Card]): array[2..14, int] =
  ## Count of each rank (index 2..14) in the hand; used for pairs, trips, etc.
  for r in 2..14: result[r] = 0
  for c in cards: result[int(c.rank)] += 1

proc detectPokerHand*(cards: seq[Card]): PokerHandKind =
  ## Classify the best poker hand from exactly 5 cards.
  if cards.len != 5: return HighCard
  let byRank = countRanks(cards)
  var counts: seq[int]
  for r in 2..14:
    if byRank[r] > 0: counts.add byRank[r]
  counts.sort(SortOrder.Descending)
  let flush = isFlush(cards)
  let sortedCards = cardRankOrder(cards)
  let straight = isStraight(sortedCards)
  if flush and straight: return StraightFlush
  if counts.len >= 1 and counts[0] == 4: return FourKind
  if counts.len >= 2 and counts[0] == 3 and counts[1] == 2: return FullHouse
  if flush: return Flush
  if straight: return Straight
  if counts.len >= 1 and counts[0] == 3: return ThreeKind
  if counts.len >= 2 and counts[0] == 2 and counts[1] == 2: return TwoPair
  if counts.len >= 1 and counts[0] == 2: return Pair
  HighCard

proc baseChipsAndMult*(kind: PokerHandKind): ChipsMult =
  ## Base chips and mult for each hand type.
  case kind
  of HighCard:     (10, 1)
  of Pair:         (20, 2)
  of TwoPair:      (40, 2)
  of ThreeKind:    (60, 3)
  of Straight:     (80, 4)
  of Flush:        (100, 4)
  of FullHouse:    (120, 4)
  of FourKind:     (160, 7)
  of StraightFlush:(200, 8)
