## Tests for round state machine.

import std/unittest
import ../src/cards
import ../src/poker
import ../src/scoring
import ../src/round

suite "startRound":
  test "gives 8 cards in hand and deck size reduced":
    var deck = newDeck()
    let rs = startRound(4, 2, 300, deck, @[], 123)
    check rs.hand.len == 8
    check rs.deck.cards.len == 52 - 8

suite "playHand":
  test "after play hand one hand consumed and 5 new cards drawn":
    var deck = newDeck()
    var rs = startRound(4, 2, 99999, deck, @[], 456)
    let initialHandLen = rs.hand.len
    let result = rs.playHand(@[0, 1, 2, 3, 4])
    check result == HandConsumed
    check rs.handsLeft == 3
    check rs.hand.len == initialHandLen - 5 + 5

  test "game over when hands exhausted":
    var deck = newDeck()
    var rs = startRound(1, 0, 99999, deck, @[], 789)
    discard rs.playHand(@[0, 1, 2, 3, 4])
    check rs.handsLeft == 0
    let result2 = rs.playHand(@[0, 1, 2, 3, 4])
    check result2 == GameOver

  test "round won when score meets target":
    var deck = newDeck()
    var rs = startRound(4, 2, 1, deck, @[], 111)
    let result = rs.playHand(@[0, 1, 2, 3, 4])
    check result == RoundWon
