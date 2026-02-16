## Shop: offered Jokers with prices, purchase and skip.

import std/random
import scoring

type
  ShopItem* = object
    ## One Joker for sale and its price.
    joker*: Joker
    price*: int

  ShopState* = object
    ## Current shop offerings; purchase removes the item and deducts money.
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

const
  shopCatalog* = [
    ShopItem(joker: Joker(name: "+50 Chips", effect: AddChips, value: 50), price: 4),
    ShopItem(joker: Joker(name: "+30 Chips", effect: AddChips, value: 30), price: 3),
    ShopItem(joker: Joker(name: "+1 Mult", effect: AddMult, value: 1), price: 4),
    ShopItem(joker: Joker(name: "+2 Mult", effect: AddMult, value: 2), price: 6),
    ShopItem(joker: Joker(name: "×2 Mult", effect: MultMult, value: 2), price: 5),
    ShopItem(joker: Joker(name: "+15 Chips", effect: AddChips, value: 15), price: 2),
  ]

proc generateOfferings*(count: int = 4): ShopState =
  ## Return a random subset of the catalog (no duplicates). count is capped by catalog size.
  var indices: seq[int]
  for i in 0 ..< shopCatalog.len:
    indices.add i
  shuffle(indices)
  let n = min(count, indices.len)
  for i in 0 ..< n:
    result.items.add shopCatalog[indices[i]]
