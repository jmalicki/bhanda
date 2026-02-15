## Tests for poker hand detection and base scoring.

import std/unittest
import std/sequtils
import ../src/cards
import ../src/poker

proc makeCard(s: string): Card =
  let rankChar = s[0]
  let suitChar = s[1]
  let suit = case suitChar
    of 's': Spades
    of 'h': Hearts
    of 'd': Diamonds
    of 'c': Clubs
    else: Spades
  let rank = case rankChar
    of '2': R2
    of '3': R3
    of '4': R4
    of '5': R5
    of '6': R6
    of '7': R7
    of '8': R8
    of '9': R9
    of 'T': R10
    of 'J': Jack
    of 'Q': Queen
    of 'K': King
    of 'A': Ace
    else: R2
  Card(suit: suit, rank: rank)

suite "detectPokerHand":
  test "pair":
    let hand = @["Ah", "Ad", "2c", "3s", "4h"].map(makeCard)
    check detectPokerHand(hand) == Pair

  test "two pair":
    let hand = @["Ah", "Ad", "2c", "2s", "4h"].map(makeCard)
    check detectPokerHand(hand) == TwoPair

  test "three of a kind":
    let hand = @["Ah", "Ad", "Ac", "2s", "4h"].map(makeCard)
    check detectPokerHand(hand) == ThreeKind

  test "straight":
    let hand = @["2h", "3d", "4c", "5s", "6h"].map(makeCard)
    check detectPokerHand(hand) == Straight

  test "flush":
    let hand = @["Ah", "2h", "5h", "9h", "Kh"].map(makeCard)
    check detectPokerHand(hand) == Flush

  test "full house":
    let hand = @["Ah", "Ad", "Ac", "2s", "2h"].map(makeCard)
    check detectPokerHand(hand) == FullHouse

  test "four of a kind":
    let hand = @["Ah", "Ad", "Ac", "As", "2h"].map(makeCard)
    check detectPokerHand(hand) == FourKind

  test "straight flush":
    let hand = @["2h", "3h", "4h", "5h", "6h"].map(makeCard)
    check detectPokerHand(hand) == StraightFlush

  test "wheel straight (A-2-3-4-5)":
    let hand = @["Ah", "2d", "3c", "4s", "5h"].map(makeCard)
    check detectPokerHand(hand) == Straight

  test "ace-high straight (10-J-Q-K-A)":
    let hand = @["Th", "Jd", "Qc", "Ks", "Ah"].map(makeCard)
    check detectPokerHand(hand) == Straight

  test "high card":
    let hand = @["Ah", "3d", "5c", "7s", "9h"].map(makeCard)
    check detectPokerHand(hand) == HighCard

suite "baseChipsAndMult":
  test "pair base":
    let (chips, mult) = baseChipsAndMult(Pair)
    check chips == 20 and mult == 2

  test "straight flush base":
    let (chips, mult) = baseChipsAndMult(StraightFlush)
    check chips == 200 and mult == 8
