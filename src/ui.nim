## Browser UI: DOM/Canvas, render hand (SVG cards), score, target, shop.
## JS-only; compiles to no-op under C for tests.

import card_svg
import game

when defined(js):
  import std/dom
  import std/sequtils

  proc renderCard*(card: cards.Card): string =
    ## Return the SVG string for a single card.
    card_svg.cardToSvg(card)

  proc getGameElement(): Element =
    ## DOM element with id "game" (container for the app).
    document.getElementById("game")

  const instructionsHtml = """
    <div class="instructions">
      <h3>How to play</h3>
      <ul>
        <li>Click 5 cards to select your hand.</li>
        <li>Hit <strong>Play hand</strong> — score must meet the target.</li>
        <li>Beat the blind to earn $ and advance.</li>
        <li>Spend money in the shop on Jokers, then start the next round.</li>
      </ul>
    </div>"""

  proc setGameHtml(html: string) =
    ## Replace the inner HTML of the game container.
    let el = getGameElement()
    if not el.isNil:
      el.innerHTML = html

  proc renderHand*(hand: seq[cards.Card]; selected: seq[int]): string =
    ## HTML for the current hand: each card in a div with data-index; selected cards get .selected class.
    var s = "<div class=\"hand-cards\">"
    for i, c in hand:
      let cls = if selected.contains(i): " selected" else: ""
      s &= "<div class=\"card" & cls & "\" data-index=\"" & $i & "\">" & cardToSvg(c) & "</div>"
    s &= "</div>"
    s

  proc renderGame*(hand: seq[cards.Card]; selected: seq[int]; score: int; target: int; handsLeft: int) =
    ## Draw the round view: table with blind strip, play zone, hand area, actions.
    var html = "<div class=\"table-wrap\"><div class=\"table\">"
    html &= "<div class=\"table-blind\"><span>Target</span><span class=\"value\">" & $target & "</span><span>Score</span><span class=\"value\">" & $score & "</span><span>Hands left</span><span class=\"value\">" & $handsLeft & "</span></div>"
    html &= "<div class=\"table-play-zone\"><span class=\"hint\">Select 5 cards below to play</span></div>"
    html &= "<div class=\"hand-area\"><div class=\"label\">Your hand</div>" & renderHand(hand, selected) & "</div>"
    html &= "<div class=\"table-actions\">"
    if selected.len == 5:
      html &= "<button class=\"btn\" data-play=\"1\">Play hand</button>"
    html &= "<button class=\"btn btn-secondary\" data-new=\"1\">Reset</button></div></div>"
    html &= instructionsHtml & "</div>"
    setGameHtml(html)

  proc renderShop*(items: seq[shop.ShopItem]; money: int) =
    ## Draw the shop on the table: money, items, Skip, Next round.
    var html = "<div class=\"table-wrap\"><div class=\"table\"><div class=\"table-shop\">"
    html &= "<div class=\"shop-title\">Shop</div>"
    html &= "<div class=\"shop-money\">$" & $money & "</div>"
    html &= "<div class=\"shop-items\">"
    for i, it in items:
      html &= "<button class=\"btn\" data-buy=\"" & $i & "\">" & it.joker.name & " ($" & $it.price & ")</button>"
    html &= "</div><div class=\"table-actions\">"
    html &= "<button class=\"btn\" data-skip>Skip</button>"
    html &= "<button class=\"btn\" data-next>Next round</button>"
    html &= "<button class=\"btn btn-secondary\" data-new=\"1\">Reset</button></div></div></div>"
    html &= instructionsHtml & "</div>"
    setGameHtml(html)

  proc renderWin*() =
    ## Show the run-won message on the table.
    var html = "<div class=\"table-wrap\"><div class=\"table\"><div class=\"end-screen\">"
    html &= "<h2>You won!</h2><p>Run complete.</p><button class=\"btn\" data-new=\"1\">Reset</button></div></div>"
    html &= instructionsHtml & "</div>"
    setGameHtml(html)

  proc renderLose*() =
    ## Show the game-over message on the table.
    var html = "<div class=\"table-wrap\"><div class=\"table\"><div class=\"end-screen\">"
    html &= "<h2>Game over</h2><p>Better luck next time.</p><button class=\"btn\" data-new=\"1\">Reset</button></div></div>"
    html &= instructionsHtml & "</div>"
    setGameHtml(html)
else:
  discard
