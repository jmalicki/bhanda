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
    ## Full run state: progress through blinds, money, deck, Jokers, and round limits.
    progress*: RunProgress
    money*: int
    deck*: Deck
    jokers*: seq[Joker]
    maxJokerSlots*: int
    handsPerRound*: int
    discardsPerRound*: int

proc initRunState*(): RunState =
  ## Default state for a new run: ante 1, 10 money, full deck, 5 Joker slots, 4 hands / 2 discards per round.
  result.progress = RunProgress(ante: 1, roundInAnte: 0)
  result.money = 10
  result.deck = newDeck()
  result.jokers = @[]
  result.maxJokerSlots = 5
  result.handsPerRound = 4
  result.discardsPerRound = 2
