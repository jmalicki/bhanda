## Generate SVG for each playing card: frame, corners, pips (2–10), face (J,Q,K).

import cards

const
  CardW* = 80   ## Card SVG width in pixels.
  CardH* = 112  ## Card SVG height in pixels.

func suitSymbol(s: Suit): string =
  ## Unicode symbol for the suit (♠ ♥ ♦ ♣).
  case s
  of Spades: "♠"
  of Hearts: "♥"
  of Diamonds: "♦"
  of Clubs: "♣"

func suitColor(s: Suit): string =
  ## Fill color for the suit (red for hearts/diamonds, black for spades/clubs).
  case s
  of Hearts, Diamonds: "#c00"
  of Spades, Clubs: "#222"

func rankStr(r: Rank): string =
  ## Short string for rank (2–10, J, Q, K, A).
  const a: array[2..14, string] = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
  a[int(r)]

func pipSvg(suit: Suit; x, y: float): string =
  ## One suit symbol as SVG text at (x, y).
  let s = suitSymbol(suit)
  let fill = suitColor(suit)
  "<text x=\"" & $x & "\" y=\"" & $y & "\" text-anchor=\"middle\" font-size=\"14\" fill=\"" & fill & "\">" & s & "</text>"

func cardFrameSvg(): string =
  ## Rounded white rectangle with border (card outline).
  "<rect x=\"1\" y=\"1\" width=\"" & $CardW & "\" height=\"" & $CardH & "\" rx=\"4\" ry=\"4\" fill=\"white\" stroke=\"#333\" stroke-width=\"1\"/>"

func cornerSvg(rankStr: string; suitSym: string; x: float; y: float; fill: string): string =
  ## Rank and suit text for a card corner at (x, y).
  "<text x=\"" & $x & "\" y=\"" & $y & "\" font-size=\"12\" fill=\"" & fill & "\">" & rankStr & suitSym & "</text>"

func numberCardPips*(card: Card): string =
  ## SVG for center pips of a number card (2–10, Ace). One pip per rank count in standard layout.
  let n = int(card.rank)
  if n < 2 or (n > 10 and n != 14): return ""
  if n == 14: return pipSvg(card.suit, float(CardW) / 2, float(CardH) / 2)
  let cx = float(CardW) / 2
  let cy = float(CardH) / 2
  case n
  of 2: pipSvg(card.suit, cx, cy - 15) & pipSvg(card.suit, cx, cy + 15)
  of 3: pipSvg(card.suit, cx, cy - 20) & pipSvg(card.suit, cx, cy) & pipSvg(card.suit, cx, cy + 20)
  of 4: pipSvg(card.suit, cx - 15, cy - 15) & pipSvg(card.suit, cx + 15, cy - 15) & pipSvg(card.suit, cx - 15, cy + 15) & pipSvg(card.suit, cx + 15, cy + 15)
  of 5: numberCardPips(Card(suit: card.suit, rank: R4)) & pipSvg(card.suit, cx, cy)
  of 6: numberCardPips(Card(suit: card.suit, rank: R4)) & pipSvg(card.suit, cx - 15, cy) & pipSvg(card.suit, cx + 15, cy)
  of 7: numberCardPips(Card(suit: card.suit, rank: R6)) & pipSvg(card.suit, cx, cy - 10)
  of 8: numberCardPips(Card(suit: card.suit, rank: R6)) & pipSvg(card.suit, cx - 15, cy - 10) & pipSvg(card.suit, cx + 15, cy - 10)
  of 9: numberCardPips(Card(suit: card.suit, rank: R6)) & pipSvg(card.suit, cx - 15, cy - 10) & pipSvg(card.suit, cx + 15, cy - 10) & pipSvg(card.suit, cx, cy + 10)
  of 10: numberCardPips(Card(suit: card.suit, rank: R9)) & pipSvg(card.suit, cx, cy - 20)
  else: ""

func faceCardCenter*(card: Card): string =
  ## SVG for center of face card (J, Q, K): single letter (J/Q/K) as placeholder.
  let cx = float(CardW) / 2
  let cy = float(CardH) / 2
  let fill = suitColor(card.suit)
  case card.rank
  of Jack: "<text x=\"" & $cx & "\" y=\"" & $cy & "\" text-anchor=\"middle\" font-size=\"24\" fill=\"" & fill & "\">J</text>"
  of Queen: "<text x=\"" & $cx & "\" y=\"" & $cy & "\" text-anchor=\"middle\" font-size=\"24\" fill=\"" & fill & "\">Q</text>"
  of King: "<text x=\"" & $cx & "\" y=\"" & $cy & "\" text-anchor=\"middle\" font-size=\"24\" fill=\"" & fill & "\">K</text>"
  else: ""

func cardToSvg*(card: Card): string =
  ## Full SVG for one card: frame, corner indices, and center (pips or face).
  ## pointer-events: none so clicks hit the parent div (data-index) for selection.
  result = "<svg width=\"" & $CardW & "\" height=\"" & $CardH & "\" style=\"pointer-events:none\">"
  result &= cardFrameSvg()
  let rs = rankStr(card.rank)
  let ss = suitSymbol(card.suit)
  let fill = suitColor(card.suit)
  result &= cornerSvg(rs, ss, 6.0, 14.0, fill)
  result &= cornerSvg(rs, ss, float(CardW) - 6.0, float(CardH) - 4.0, fill)
  if int(card.rank) >= 2 and int(card.rank) <= 10 or card.rank == Ace:
    result &= numberCardPips(card)
  else:
    result &= faceCardCenter(card)
  result &= "</svg>"
