## Score calculation: base Chips/Mult from hand type, card rank (level), and Joker effects.
## Balatro-style: Chips = base chips + sum of card rank values (level); then Jokers add/multiply.

import cards
import poker

type
  JokerEffectKind* = enum
    ## How a Joker modifies score: add to chips, add to mult, or multiply mult.
    AddChips, AddMult, MultMult

  Joker* = object
    ## Passive modifier; effect and value are applied in computeScore.
    name*: string
    effect*: JokerEffectKind
    value*: int

proc computeScore*(handKind: PokerHandKind; cards: seq[Card]; jokers: seq[Joker]): int =
  ## Balatro-style score: Chips = base chips + level (sum of card rank values) + Joker chip bonuses;
  ## Mult = base mult, then + Joker add mult, then × Joker mult; final = Chips × Mult.
  var (chips, mult) = baseChipsAndMult(handKind)
  for c in cards:
    chips += rankValue(c.rank)
  for j in jokers:
    case j.effect
    of AddChips: chips += j.value
    of AddMult:  mult += j.value
    of MultMult: mult *= j.value
  result = chips * mult
