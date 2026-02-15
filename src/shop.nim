## Shop: offered Jokers with prices, purchase and skip.

import scoring

type
  ShopItem* = object
    joker*: Joker
    price*: int

  ShopState* = object
    items*: seq[ShopItem]

proc cashForBlind*(blindIndex: int): int =
  ## Cash awarded for beating a blind (small reward that scales).
  result = 10 + blindIndex * 5

proc purchase*(shop: var ShopState; index: int; money: var int): bool =
  ## Buy the Joker at index. Returns true if purchase succeeded (enough money).
  if index < 0 or index >= shop.items.len: return false
  let item = shop.items[index]
  if money < item.price: return false
  money -= item.price
  shop.items.delete(index)
  true

proc skip*(shop: ShopState) =
  ## Skip the shop (no-op on state; caller advances round).
  discard
