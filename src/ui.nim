## Browser UI: DOM/Canvas, render hand (SVG cards), score, target, shop.
## JS-only; compiles to no-op under C for tests.

import card_svg
import game

when defined(js):
  import std/dom
  import std/sequtils

  proc renderCard*(card: cards.Card): string =
    card_svg.cardToSvg(card)

  proc getGameElement(): Element =
    document.getElementById("game")

  proc setGameHtml(html: string) =
    let el = getGameElement()
    if not el.isNil:
      el.innerHTML = html

  proc renderHand*(hand: seq[cards.Card]; selected: seq[int]): string =
    var s = "<div style=\"display:flex;gap:8px;flex-wrap:wrap;\">"
    for i, c in hand:
      let border = if selected.contains(i): "border:2px solid gold;" else: ""
      s &= "<div style=\"" & border & "\" data-index=\"" & $i & "\">" & cardToSvg(c) & "</div>"
    s &= "</div>"
    s

  proc renderGame*(hand: seq[cards.Card]; selected: seq[int]; score: int; target: int; handsLeft: int) =
    var html = "<p>Target: " & $target & " | Score: " & $score & " | Hands left: " & $handsLeft & "</p>"
    html &= "<p>Click 5 cards to play.</p>"
    html &= renderHand(hand, selected)
    if selected.len == 5:
      html &= "<p><button data-play=\"1\">Play hand</button></p>"
    setGameHtml(html)

  proc renderShop*(items: seq[shop.ShopItem]; money: int) =
    var html = "<p>Shop | Money: $" & $money & "</p>"
    for i, it in items:
      html &= "<button data-buy=\"" & $i & "\">" & it.joker.name & " ($" & $it.price & ")</button> "
    html &= "<button data-skip>Skip</button> "
    html &= "<button data-next>Next round</button>"
    setGameHtml(html)

  proc renderWin*() =
    setGameHtml("<p>You won!</p>")

  proc renderLose*() =
    setGameHtml("<p>Game over.</p>")
else:
  discard
