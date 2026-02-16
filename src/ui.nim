## UI layout only: Karax buildHtml for the game screen.
## Reads state and callbacks from app; no game logic here.

when defined(js):
  include karax/prelude
  import app
  import game
  import card_svg

  proc sidebarLeft*(): VNode =
    result = buildHtml(tdiv(class = "sidebar sidebar-left")):
      tdiv(class = "instructions"):
        h3: text "How to play"
        ul:
          li: text "Select 5 cards to play a hand, or select 1–8 cards and use Discard to draw new ones (limited per round)."
          li:
            text "The "
            strong: text "Score"
            text " shown is your projected score for that selection (0 until you pick 5 cards). "
            strong: text "Target"
            text " is what you need to reach to beat the blind."
          li:
            text "Hit "
            strong: text "Play hand"
            text " — if your score meets the target, you beat the blind and earn $."
          li:
            text "Shop: "
            strong: text "Jokers"
            text " are score items you collect — they boost every hand; you have a limited number of slots and can sell them. "
            strong: text "Vouchers"
            text " are one-time upgrades that change the run's rules (more hands, discards, or joker slots); you don't hold them, they just modify the numbers in the status panel."

  proc sidebarRight*(): VNode =
    result = buildHtml(tdiv(class = "sidebar sidebar-right")):
      tdiv(class = "run-rules"):
        h3: text "Run rules"
        p(class = "run-rules-desc"): text "Limits for this run (vouchers can increase these):"
        ul(class = "run-rules-list"):
          li: text $gRunState.handsPerRound & " hands per round"
          li: text $gRunState.discardsPerRound & " discards per round"
          li: text $gRunState.maxJokerSlots & " Joker slots (how many Jokers you can hold)"
        if gRunState.boughtExtraHand or gRunState.boughtExtraDiscard or gRunState.boughtExtraJokerSlot:
          p(class = "run-rules-vouchers"): text "Active vouchers:"
          ul(class = "run-rules-vouchers-list"):
            if gRunState.boughtExtraHand: li: text "+1 Hand per round"
            if gRunState.boughtExtraDiscard: li: text "+1 Discard per round"
            if gRunState.boughtExtraJokerSlot: li: text "+1 Joker slot"
      tdiv(class = "your-jokers"):
        h3: text "Your Jokers (" & $gRunState.jokers.len & "/" & $gRunState.maxJokerSlots & ")"
        if gRunState.jokers.len == 0:
          p(class = "jokers-empty"): text "None yet. Beat a blind, then buy some in the shop."
        else:
          p(class = "jokers-how"): text "Applied automatically to every hand — no button to use."
          ul:
            for j in gRunState.jokers:
              li: text j.name
      if handLevelsText().len > 0:
        tdiv(class = "hand-levels"):
          h3: text "Hand levels"
          p: text handLevelsText()
      tdiv(class = "sidebar-reset"):
        p(class = "sidebar-reset-label"): text "Start over (clears saved progress)"
        button(class = "btn", `data-new` = "1", onclick = doNewRun): text "New run"

  proc createDom*(): VNode =
    checkLoseCondition()
    let (playHint, projectedScore) = handPreview()
    result = buildHtml(tdiv(class = "game-layout")):
      sidebarLeft()
      tdiv(class = "table-wrap"):
        tdiv(class = "table"):
          if gMode == ModeRound:
            tdiv(class = "table-blind"):
              span:
                if effectForBlind(gRunState.progress) == FlushOrBetter:
                  text blindDisplayName(gRunState.progress.currentBlind()) & ": Flush or better"
                else:
                  text blindDisplayName(gRunState.progress.currentBlind())
              span: text "Target"
              span(class = "value"): text $gRoundState.targetChips
              span: text "Score"
              span(class = "value"): text $projectedScore
              span: text "Hands left"
              span(class = "value"): text $gRoundState.handsLeft
              span: text "Discards left"
              span(class = "value"): text $gRoundState.discardsLeft
            tdiv(class = "table-play-zone"):
              if playHint.len > 0:
                span(class = "hint"): text playHint
              else:
                span(class = "hint"): text "Select 5 cards below to play"
            tdiv(class = "hand-area"):
              tdiv(class = "label"): text "Your hand"
              tdiv(class = "hand-cards"):
                for i in 0 ..< gRoundState.hand.len:
                  let c = gRoundState.hand[i]
                  let sel = gSelected.find(i) >= 0
                  if sel:
                    tdiv(class = "card selected", `data-index` = cstring($i), onclick = cardClick(i)):
                      verbatim(cardToSvg(c))
                  else:
                    tdiv(class = "card", `data-index` = cstring($i), onclick = cardClick(i)):
                      verbatim(cardToSvg(c))
              tdiv(class = "table-actions"):
                if gSelected.len == 5:
                  button(class = "btn", `data-play` = "1", onclick = onPlayHand): text "Play hand"
                if gRoundState.discardsLeft > 0:
                  if gSelected.len >= 1:
                    button(class = "btn btn-secondary", onclick = onDiscard):
                      text "Discard (" & $gSelected.len & ")"
                  else:
                    span(class = "discard-hint"): text "Discard: select 1–8 cards above, then click Discard"
          elif gMode == ModeShop:
            tdiv(class = "table-shop"):
              tdiv(class = "shop-title"): text "Shop"
              tdiv(class = "shop-money"): text "$" & $gRunState.money
              if gRunState.jokers.len >= gRunState.maxJokerSlots:
                p(class = "shop-slots-full"): text "Joker slots full (" & $gRunState.maxJokerSlots & "/" & $gRunState.maxJokerSlots & "). Sell one to buy more."
              tdiv(class = "shop-jokers-buy"):
                p(class = "shop-section-label"): text "Jokers (score boosters you hold; limited by slots):"
                tdiv(class = "shop-items"):
                  for i in 0 ..< gShopState.items.len:
                    let it = gShopState.items[i]
                    if gRunState.jokers.len >= gRunState.maxJokerSlots:
                      button(class = "btn btn-disabled", disabled = true):
                        text it.joker.name & " ($" & $it.price & ")"
                    else:
                      button(class = "btn", onclick = buyClick(i)):
                        text it.joker.name & " ($" & $it.price & ")"
              if gRunState.jokers.len > 0:
                tdiv(class = "shop-sell"):
                  p(class = "shop-section-label"): text "Sell a Joker ($" & $sellPrice & " each):"
                  for i in 0 ..< gRunState.jokers.len:
                    let j = gRunState.jokers[i]
                    button(class = "btn btn-secondary", onclick = sellClick(i)):
                      text j.name & " — Sell ($" & $sellPrice & ")"
              tdiv(class = "shop-vouchers"):
                p(class = "shop-section-label"): text "Vouchers (one-time upgrades that change run rules above; you don't hold them):"
                if not gRunState.boughtExtraHand:
                  button(class = "btn btn-voucher", onclick = onBuyVoucherHand):
                    text "+1 Hand per round — $" & $voucherPrice
                if not gRunState.boughtExtraDiscard:
                  button(class = "btn btn-voucher", onclick = onBuyVoucherDiscard):
                    text "+1 Discard per round — $" & $voucherPrice
                if not gRunState.boughtExtraJokerSlot:
                  button(class = "btn btn-voucher", onclick = onBuyVoucherJokerSlot):
                    text "+1 Joker slot (hold more Jokers) — $" & $voucherPrice
              tdiv(class = "table-actions"):
                if gRunState.money >= rerollCost:
                  button(class = "btn btn-secondary", onclick = onReroll): text "Reroll ($" & $rerollCost & ")"
                button(class = "btn", onclick = startNewRound): text "Skip"
                button(class = "btn", onclick = startNewRound): text "Next round"
          elif gMode == ModeWin:
            tdiv(class = "end-screen"):
              h2: text "You won!"
              p: text "Run complete."
          else:
            tdiv(class = "end-screen"):
              h2: text "Game over"
              p: text "Better luck next time."
      sidebarRight()
