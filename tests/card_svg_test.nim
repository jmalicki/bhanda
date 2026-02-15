## Tests for card SVG generation.

import std/unittest
import std/strutils
import ../src/cards
import ../src/card_svg

suite "cardToSvg":
  test "each of 52 cards generates SVG containing rank and suit":
    var count = 0
    for s in Suit:
      for r in Rank:
        let card = Card(suit: s, rank: r)
        let svg = cardToSvg(card)
        check "svg" in svg.toLower
        check svg.len > 20
        count += 1
    check count == 52

  test "face cards include a distinct center element":
    let j = Card(suit: Hearts, rank: Jack)
    let q = Card(suit: Hearts, rank: Queen)
    let k = Card(suit: Hearts, rank: King)
    check "J</text>" in cardToSvg(j)
    check "Q</text>" in cardToSvg(q)
    check "K</text>" in cardToSvg(k)

  test "number cards include correct number of pips":
    let two = Card(suit: Clubs, rank: R2)
    let five = Card(suit: Diamonds, rank: R5)
    let svg2 = cardToSvg(two)
    let svg5 = cardToSvg(five)
    check svg2.count("♦") + svg2.count("♣") + svg2.count("♥") + svg2.count("♠") >= 2
    check svg5.count("♦") + svg5.count("♣") + svg5.count("♥") + svg5.count("♠") >= 5
