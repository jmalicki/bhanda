## Tests for cards and deck operations.

import std/unittest
import std/random
import ../src/cards

suite "deck":
  test "new deck has 52 cards":
    let d = newDeck()
    check d.cards.len == 52

  test "draw reduces deck size and returns correct number":
    var d = newDeck()
    let drawn = d.draw(5)
    check drawn.len == 5
    check d.cards.len == 52 - 5

  test "shuffle with fixed seed is deterministic":
    var a = newDeck()
    var b = newDeck()
    a.shuffle(42)
    b.shuffle(42)
    check a.cards.len == 52
    check b.cards.len == 52
    for i in 0 ..< 52:
      check a.cards[i].suit == b.cards[i].suit
      check a.cards[i].rank == b.cards[i].rank

suite "card display":
  test "card to string":
    check $Card(suit: Hearts, rank: Ace) == "Ah"
    check $Card(suit: Clubs, rank: R10) == "10c"
