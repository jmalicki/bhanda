## Score calculation: base Chips/Mult from hand type plus Joker effects.
## Jokers add flat Chips, flat Mult, or multiply Mult.

import cards
import poker

type
  JokerEffectKind* = enum
    AddChips, AddMult, MultMult

  Joker* = object
    name*: string
    effect*: JokerEffectKind
    value*: int

proc computeScore*(handKind: PokerHandKind; cards: seq[Card]; jokers: seq[Joker]): int =
  ## Final score = (baseChips + chip bonuses) * (baseMult * mult multiplier).
  ## Jokers are applied in order: AddChips adds to chips, AddMult adds to mult, MultMult multiplies mult.
  var (chips, mult) = baseChipsAndMult(handKind)
  for j in jokers:
    case j.effect
    of AddChips: chips += j.value
    of AddMult:  mult += j.value
    of MultMult: mult *= j.value
  result = chips * mult
