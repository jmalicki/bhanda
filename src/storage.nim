## Persist game state to the browser's Web Storage (localStorage).
## JS-only; no-op under C. Key: "bhanda_save".

when defined(js):
  import std/dom
  import std/json
  import std/options
  import cards
  import game
  import round
  import scoring

  const storageKey* = "bhanda_save"

  proc cardToJson(c: Card): JsonNode =
    result = newJObject()
    result["s"] = %int(c.suit)
    result["r"] = %int(c.rank)

  proc cardFromJson(j: JsonNode): Card =
    result.suit = Suit(j["s"].getInt(0))
    result.rank = Rank(j["r"].getInt(2))

  proc deckToJson(d: Deck): JsonNode =
    result = newJObject()
    result["cards"] = newJArray()
    for c in d.cards:
      result["cards"].add cardToJson(c)

  proc deckFromJson(j: JsonNode): Deck =
    result.cards = @[]
    for item in j["cards"]:
      result.cards.add cardFromJson(item)

  proc jokerToJson(joker: Joker): JsonNode =
    result = newJObject()
    result["name"] = %joker.name
    result["e"] = %int(joker.effect)
    result["v"] = %joker.value

  proc jokerFromJson(j: JsonNode): Joker =
    result.name = j["name"].getStr("")
    result.effect = JokerEffectKind(j["e"].getInt(0))
    result.value = j["v"].getInt(0)

  proc saveState*(runState: RunState; roundState: RoundState; mode: string) =
    ## Write run + round + mode to localStorage (Web Storage).
    var j = newJObject()
    j["progress"] = newJObject()
    j["progress"]["ante"] = %runState.progress.ante
    j["progress"]["roundInAnte"] = %runState.progress.roundInAnte
    j["money"] = %runState.money
    j["deck"] = deckToJson(runState.deck)
    j["jokers"] = newJArray()
    for joker in runState.jokers:
      j["jokers"].add jokerToJson(joker)
    j["maxJokerSlots"] = %runState.maxJokerSlots
    j["handsPerRound"] = %runState.handsPerRound
    j["discardsPerRound"] = %runState.discardsPerRound
    j["handsLeft"] = %roundState.handsLeft
    j["discardsLeft"] = %roundState.discardsLeft
    j["hand"] = newJArray()
    for c in roundState.hand:
      j["hand"].add cardToJson(c)
    j["targetChips"] = %roundState.targetChips
    j["mode"] = %mode
    let s = $j
    window.localStorage.setItem(storageKey, cstring(s))

  type
    LoadedState* = object
      runState*: RunState
      roundState*: RoundState
      mode*: string

  proc loadState*(): Option[LoadedState] =
    ## Read from localStorage; return none if missing or invalid.
    let s = window.localStorage.getItem(storageKey)
    if s == nil or s == "":
      return none(LoadedState)
    try:
      let j = parseJson($s)
      var run: RunState
      run.progress.ante = j["progress"]["ante"].getInt(1)
      run.progress.roundInAnte = j["progress"]["roundInAnte"].getInt(0)
      run.money = j["money"].getInt(10)
      run.deck = deckFromJson(j["deck"])
      run.jokers = @[]
      for item in j["jokers"]:
        run.jokers.add jokerFromJson(item)
      run.maxJokerSlots = j["maxJokerSlots"].getInt(5)
      run.handsPerRound = j["handsPerRound"].getInt(4)
      run.discardsPerRound = j["discardsPerRound"].getInt(2)
      var roundSt: RoundState
      roundSt.handsLeft = j["handsLeft"].getInt(4)
      roundSt.discardsLeft = j["discardsLeft"].getInt(2)
      roundSt.hand = @[]
      for item in j["hand"]:
        roundSt.hand.add cardFromJson(item)
      roundSt.deck = run.deck
      roundSt.targetChips = j["targetChips"].getInt(300)
      roundSt.jokers = run.jokers
      result = some(LoadedState(runState: run, roundState: roundSt, mode: j["mode"].getStr("round")))
    except:
      result = none(LoadedState)

  proc clearState*() =
    ## Remove saved state from localStorage.
    window.localStorage.removeItem(storageKey)

else:
  import std/options
  import game
  const storageKey* = "bhanda_save"
  type LoadedState* = object
    runState*: RunState
    roundState*: RoundState
    mode*: string
  proc saveState*(runState: RunState; roundState: RoundState; mode: string) = discard
  proc loadState*(): Option[LoadedState] = none(LoadedState)
  proc clearState*() = discard
