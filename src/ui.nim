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

  const sidebarHtml = """
    <div class="instructions">
      <h3>How to play</h3>
      <ul>
        <li>Click 5 cards to select your hand.</li>
        <li>Hit <strong>Play hand</strong> — score must meet the target.</li>
        <li>Beat the blind to earn $ and advance.</li>
        <li>Spend money in the shop on Jokers, then start the next round.</li>
      </ul>
    </div>
    <button class="btn btn-secondary" data-new="1">Reset</button>"""

  proc wrapTableWithLayout(tableContent: string): string =
    "<div class=\"game-layout\"><div class=\"table-wrap\"><div class=\"table\">" &
    tableContent &
    "</div></div><div class=\"sidebar\">" & sidebarHtml & "</div></div>"

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
    ## Draw the round view: table with blind strip, play zone, hand area, actions. Reset is in sidebar.
    var tableContent = "<div class=\"table-blind\"><span>Target</span><span class=\"value\">" & $target & "</span><span>Score</span><span class=\"value\">" & $score & "</span><span>Hands left</span><span class=\"value\">" & $handsLeft & "</span></div>"
    tableContent &= "<div class=\"table-play-zone\"><span class=\"hint\">Select 5 cards below to play</span></div>"
    tableContent &= "<div class=\"hand-area\"><div class=\"label\">Your hand</div>" & renderHand(hand, selected) & "</div>"
    tableContent &= "<div class=\"table-actions\">"
    if selected.len == 5:
      tableContent &= "<button class=\"btn\" data-play=\"1\">Play hand</button>"
    tableContent &= "</div>"
    setGameHtml(wrapTableWithLayout(tableContent))

  proc renderShop*(items: seq[shop.ShopItem]; money: int) =
    ## Draw the shop on the table. Reset is in sidebar.
    var tableContent = "<div class=\"table-shop\">"
    tableContent &= "<div class=\"shop-title\">Shop</div>"
    tableContent &= "<div class=\"shop-money\">$" & $money & "</div>"
    tableContent &= "<div class=\"shop-items\">"
    for i, it in items:
      tableContent &= "<button class=\"btn\" data-buy=\"" & $i & "\">" & it.joker.name & " ($" & $it.price & ")</button>"
    tableContent &= "</div><div class=\"table-actions\">"
    tableContent &= "<button class=\"btn\" data-skip>Skip</button>"
    tableContent &= "<button class=\"btn\" data-next>Next round</button>"
    tableContent &= "</div></div>"
    setGameHtml(wrapTableWithLayout(tableContent))

  proc renderWin*() =
    ## Show the run-won message on the table. Reset is in sidebar.
    setGameHtml(wrapTableWithLayout("<div class=\"end-screen\"><h2>You won!</h2><p>Run complete.</p></div>"))

  proc renderLose*() =
    ## Show the game-over message on the table. Reset is in sidebar.
    setGameHtml(wrapTableWithLayout("<div class=\"end-screen\"><h2>Game over</h2><p>Better luck next time.</p></div>"))
else:
  discard
