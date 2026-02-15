## Tests for score calculation with Jokers.

import std/unittest
import ../src/cards
import ../src/poker
import ../src/scoring

suite "computeScore":
  test "no jokers matches base chips * mult":
    let (c, m) = baseChipsAndMult(Pair)
    check computeScore(Pair, @[], @[]) == c * m

  test "AddChips joker adds to chips before multiply":
    let jokers = @[Joker(name: "Chip", effect: AddChips, value: 50)]
    let (c, m) = baseChipsAndMult(Pair)
    check computeScore(Pair, @[], jokers) == (c + 50) * m

  test "AddMult joker adds to mult":
    let jokers = @[Joker(name: "Mult", effect: AddMult, value: 1)]
    let (c, m) = baseChipsAndMult(Pair)
    check computeScore(Pair, @[], jokers) == c * (m + 1)

  test "MultMult joker multiplies mult":
    let jokers = @[Joker(name: "x2", effect: MultMult, value: 2)]
    let (c, m) = baseChipsAndMult(Pair)
    check computeScore(Pair, @[], jokers) == c * (m * 2)

  test "multiple jokers combine correctly":
    let jokers = @[
      Joker(name: "Chip", effect: AddChips, value: 30),
      Joker(name: "x2", effect: MultMult, value: 2)
    ]
    let (c, m) = baseChipsAndMult(Flush)
    check computeScore(Flush, @[], jokers) == (c + 30) * (m * 2)
