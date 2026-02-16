## Tests for shop.

import std/unittest
import ../src/scoring
import ../src/shop

suite "shop":
  test "purchase subtracts money and removes item":
    var shop = ShopState(items: @[
      ShopItem(joker: Joker(name: "Chip", effect: AddChips, value: 30), price: 5)
    ])
    var money = 10
    check purchase(shop, 0, money) == true
    check money == 5
    check shop.items.len == 0

  test "purchase fails when not enough money":
    var shop = ShopState(items: @[
      ShopItem(joker: Joker(name: "Chip", effect: AddChips, value: 30), price: 10)
    ])
    var money = 5
    check purchase(shop, 0, money) == false
    check money == 5
    check shop.items.len == 1

  test "skip leaves state unchanged":
    let shop = ShopState(items: @[
      ShopItem(joker: Joker(name: "X", effect: AddMult, value: 1), price: 3)
    ])
    skip(shop)
    check shop.items.len == 1

  test "cash for blind":
    check cashForBlind(0) >= 10
    check cashForBlind(2) > cashForBlind(0)

  test "shopCatalog is non-empty":
    check shopCatalog.len >= 1
    for it in shopCatalog:
      check it.price > 0
      check it.joker.name.len > 0

  test "generateOfferings returns default count of 4":
    let shop = generateOfferings()
    check shop.items.len == 4

  test "generateOfferings count is capped at catalog size":
    let shop = generateOfferings(100)
    check shop.items.len == shopCatalog.len

  test "generateOfferings items are from catalog":
    let shop = generateOfferings()
    for it in shop.items:
      check it in shopCatalog

  test "generateOfferings has no duplicate items":
    let shop = generateOfferings()
    var seen: seq[ShopItem]
    for it in shop.items:
      check it notin seen
      seen.add it
