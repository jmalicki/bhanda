## Playing card types and deck operations.
## Provides Card (suit + rank), Deck as seq[Card], newDeck, shuffle, and draw.

import std/random

type
  Suit* = enum
    Spades, Hearts, Diamonds, Clubs

  Rank* = enum
    R2 = 2, R3, R4, R5, R6, R7, R8, R9, R10, Jack, Queen, King, Ace

  Card* = object
    suit*: Suit
    rank*: Rank

  Deck* = object
    cards*: seq[Card]

proc newDeck*(): Deck =
  ## Build a standard 52-card deck (one of each suit/rank combination).
  result.cards = newSeq[Card](0)
  for s in Suit:
    for r in Rank:
      result.cards.add Card(suit: s, rank: r)

proc shuffle*(d: var Deck; seed: int = 0) =
  ## Shuffle the deck in place. Optional seed for deterministic order (e.g. in tests).
  if seed != 0:
    random.randomize(seed)
  random.shuffle(d.cards)

proc draw*(d: var Deck; n: int): seq[Card] =
  ## Remove and return the top n cards. Fewer than n if deck has fewer cards.
  result = newSeq[Card](0)
  let take = min(n, d.cards.len)
  for i in 0 ..< take:
    result.add d.cards.pop

proc `$`*(c: Card): string =
  ## Display string for a card, e.g. "Ah", "10c".
  const rankStr: array[2..14, string] = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
  const suitStr = ["s", "h", "d", "c"]
  rankStr[int(c.rank)] & suitStr[int(c.suit)]
