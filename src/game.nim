## Game state and run lifecycle: ties together round, blinds, and shop.
## Re-exports main types for the UI.

import cards
import poker
import scoring
import round
import blinds
import shop

export cards, poker, scoring, round, blinds, shop

type
  RunState* = object
    progress*: RunProgress
    money*: int
    deck*: Deck
    jokers*: seq[Joker]
    handsPerRound*: int
    discardsPerRound*: int

proc initRunState*(): RunState =
  result.progress = RunProgress(ante: 1, roundInAnte: 0)
  result.money = 10
  result.deck = newDeck()
  result.jokers = @[]
  result.handsPerRound = 4
  result.discardsPerRound = 2
