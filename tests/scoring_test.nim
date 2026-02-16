## Tests for score calculation with Jokers.

import std/unittest
import ../src/cards
import ../src/poker
import ../src/scoring

proc level1Levels(): array[PokerHandKind, int] =
  for k in PokerHandKind: result[k] = 1

suite "computeScore":
  test "no jokers matches base chips * mult":
    let (c, m) = baseChipsAndMult(Pair)
    check computeScore(Pair, @[], @[], level1Levels()) == c * m

  test "AddChips joker adds to chips before multiply":
    let jokers = @[Joker(name: "Chip", effect: AddChips, value: 50)]
    let (c, m) = baseChipsAndMult(Pair)
    check computeScore(Pair, @[], jokers, level1Levels()) == (c + 50) * m

  test "AddMult joker adds to mult":
    let jokers = @[Joker(name: "Mult", effect: AddMult, value: 1)]
    let (c, m) = baseChipsAndMult(Pair)
    check computeScore(Pair, @[], jokers, level1Levels()) == c * (m + 1)

  test "MultMult joker multiplies mult":
    let jokers = @[Joker(name: "x2", effect: MultMult, value: 2)]
    let (c, m) = baseChipsAndMult(Pair)
    check computeScore(Pair, @[], jokers, level1Levels()) == c * (m * 2)

  test "multiple jokers combine correctly":
    let jokers = @[
      Joker(name: "Chip", effect: AddChips, value: 30),
      Joker(name: "x2", effect: MultMult, value: 2)
    ]
    let (c, m) = baseChipsAndMult(Flush)
    check computeScore(Flush, @[], jokers, level1Levels()) == (c + 30) * (m * 2)

  test "card rank (level) adds to chips (Balatro-style)":
    let hand = @[
      Card(suit: Hearts, rank: Ace), Card(suit: Diamonds, rank: Ace),
      Card(suit: Clubs, rank: R2), Card(suit: Spades, rank: R3), Card(suit: Hearts, rank: R4)
    ]
    let (baseC, baseM) = baseChipsAndMult(Pair)
    let level = 14 + 14 + 2 + 3 + 4
    check computeScore(Pair, hand, @[], level1Levels()) == (baseC + level) * baseM

  test "hand level adds +5 chips per level above 1":
    var levels = level1Levels()
    levels[Pair] = 3
    let (c, m) = baseChipsAndMult(Pair)
    check computeScore(Pair, @[], @[], levels) == (c + (3 - 1) * 5) * m
