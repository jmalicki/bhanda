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
  GameMode* = enum
    ## Current phase of the run: playing a round, in shop, or end screen.
    ModeRound, ModeShop, ModeWin, ModeLose

  RunState* = object
    ## Full run state: progress through blinds, money, deck, Jokers, and round limits.
    progress*: RunProgress
    money*: int
    deck*: Deck
    jokers*: seq[Joker]
    maxJokerSlots*: int
    handLevels*: array[PokerHandKind, int]
    handsPerRound*: int
    discardsPerRound*: int
    boughtExtraHand*: bool
    boughtExtraDiscard*: bool
    boughtExtraJokerSlot*: bool

proc initRunState*(): RunState =
  ## Default state for a new run: ante 1, 10 money, full deck, 5 Joker slots, 4 hands / 2 discards per round.
  result.progress = RunProgress(ante: 1, roundInAnte: 0)
  result.money = 10
  result.deck = newDeck()
  result.jokers = @[]
  result.maxJokerSlots = 5
  for k in PokerHandKind: result.handLevels[k] = 1
  result.handsPerRound = 4
  result.discardsPerRound = 2
  result.boughtExtraHand = false
  result.boughtExtraDiscard = false
  result.boughtExtraJokerSlot = false

func modeToStorageKey*(m: GameMode): string =
  ## String used when persisting mode to localStorage (stable across versions).
  case m
  of ModeRound: "round"
  of ModeShop: "shop"
  of ModeWin: "win"
  of ModeLose: "lose"

func parseGameMode*(s: string): GameMode =
  ## Parse stored mode string; defaults to ModeRound if unknown.
  case s
  of "shop": ModeShop
  of "win": ModeWin
  of "lose": ModeLose
  else: ModeRound
