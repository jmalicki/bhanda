# Bhanda (game plan)

## Overview

Build Bhanda: a Balatro-style roguelike deck-builder in Nim: poker hands, escalating blinds, Jokers that modify score, and a shop between rounds. The game targets the **browser** (Nim compiles to JavaScript); source is 100% Nim, with **readable, well-documented code** and solid tests.

---

## Target: Browser (Nim compiles to JavaScript)

The game is a **browser-based game**: all source is written in Nim; the compiler’s **JavaScript backend** (`nim js`) produces a single `.js` file that runs in the browser. No terminal or native build required for play; one HTML file loads the JS and provides a canvas (or DOM) for rendering.

- **Build**: `nim js -o:balatro.js src/main.nim` (or a `nimble buildjs` task). Open an HTML file that includes `<script src="balatro.js"></script>` and a `<canvas>` (or div) for the game. Use a local static server (e.g. `python -m http.server` or `nimble run serve`) to avoid CORS when loading the JS.
- **Rendering**: In Nim (JS backend), use **DOM + SVG** (or Canvas) for cards so they stay sharp at any zoom. Draw cards as **SVG** (see Card presentation below). Use `std/dom` for document/canvas or SVG element and events. No SDL2 — that’s native-only.
- **Input**: Attach keyboard/click handlers with `addEventListener` (through `std/dom` or small `importc` wrappers). Same game logic; only the “view” and “input” layers are browser-specific.
- **JS backend limits**: No file system, no threads, no OS APIs. Save/load can use `localStorage` via a tiny JS interop wrapper (`importc`). Keep game logic in pure Nim so it can be tested with the **C backend** (see Testing).

---

## Project setup

- **Location**: Reuse the existing workspace (`/home/jmalicki/src/nim-snake-game`). Add the Balatro clone here.
- **Nimble**: Run `nimble init` (e.g. package name `balatro` or `balatro_clone`). Add a task (e.g. `buildjs`) that runs `nim js -d:release -o:balatro.js src/main.nim` and, if desired, a task to run a small static server for development.
- **Dependencies**: None required for the JS build. Use Nim’s **std/dom** (and optionally **std/jsffi**) for browser APIs. Optional: **karax** for a more reactive DOM approach, or keep it minimal with direct DOM/Canvas calls.

---

## Linters and tooling

- **Compiler check**: Use `nim check path/to/module.nim` or `nim c --noMain path/to/module.nim` to report errors and warnings without building an executable. Run against all source modules (e.g. `src/*.nim`) so the codebase stays compile-clean.
- **Formatter**: Use **nimpretty** (shipped with Nim, or `nimble install nimpretty`) to format code. Run on `src/` and `tests/` (e.g. `nimpretty src/*.nim tests/*.nim` or a script that formats all .nim files).
- **Nimble tasks**: Add a `lint` or `check` task that runs compiler check on all modules (and optionally runs nimpretty in check-only mode if supported). Add a `format` task that runs nimpretty to rewrite files. Optionally add `ci` that runs `nimble test` + `nimble lint` (and format check) for CI.
- **Pre-commit**: Set up in Stage 1: a git pre-commit hook (script or [pre-commit](https://pre-commit.com) framework) that runs `nimble lint` and `nimble test` so commits are blocked if lint or tests fail.
- **Per stage**: Before each commit, run the linter (and formatter if you use it) and fix any issues so the branch stays clean.

---

## What we're cloning (core loop)

Balatro is a **poker roguelike deck-builder**. Each run:

- You have a **52-card deck**, a limited number of **hands** and **discards** per round, and **Jokers** (passive modifiers).
- Each **round** is a **blind** with a **target chip score**. You play poker hands (select up to 5 cards); each hand scores **Chips × Mult**. Beat the target before you run out of hands/discards.
- **Antes**: each ante has 3 rounds — Small Blind, Big Blind, Boss Blind. Beat all three to advance to the next ante.
- Between rounds: **shop** — spend money on Jokers, booster packs, and vouchers (e.g. +1 hand, +1 discard).
- **Win**: complete Ante 8 (first Showdown). **Lose**: run out of hands or cards in hand before hitting the target in a round.

```
Round vs Blind → (target met) → Shop → next Round
Round vs Blind → (out of hands/cards) → Lose
Shop (after ante 8 done) → Win
```

---

## Data model (core types)

- **Card**: `Suit` (enum) + `Rank` (2..10, J, Q, K, A). Stored as two enums or ints; display as "Ah", "10c", etc.
- **Deck**: `seq[Card]` — draw pile. Shuffle at round start; draw 8 cards (or configurable) into "hand".
- **Hand (held cards)**: `seq[Card]` — the 8 (or 5) cards the player can choose from. Selecting 5 forms the "played hand".
- **Poker hand type**: Enum: HighCard, Pair, TwoPair, ThreeKind, Straight, Flush, FullHouse, FourKind, StraightFlush, etc. Each type has **base Chips** and **base Mult** (table or constant per type).
- **Joker**: Id/name + effect type. For MVP, effects can be: flat +Chips, flat +Mult, or "multiply Mult by 2". Store as `seq[Joker]`; max 5 slots (or start with 2–3).
- **Blind**: Name + target chip score (scales by ante). Boss blinds can have a simple effect (e.g. "no hearts" or "−1 hand"); MVP can skip or stub.
- **GameState**: Ante index, round index (0=Small, 1=Big, 2=Boss), hands remaining, discards remaining, dollars, deck, current hand (cards held), Jokers, and flags (round won/lost, run won/lost).

---

## Poker hand detection

- **Input**: 5 cards.
- **Output**: Best poker hand type (and for straights/flushes, the rank used).
- **Algorithm**: Check from best to worst (Straight Flush → Four Kind → … → High Card). Helpers: count ranks, check flush (same suit), check straight (consecutive ranks, A low/high).
- **Scoring (base)**: Map hand type → (chips, mult). Add chip contribution of each card (e.g. rank value: 2=2, …, A=11) for "level" effect; MVP can use a fixed table per hand type only.

---

## Score calculation

- **Base**: From poker hand type (+ card ranks if you add level).
- **Jokers**: In order, apply each Joker: add Chips, add Mult, or multiply Mult. Example: "Joker A: +50 Chips; Joker B: ×2 Mult" → `(baseChips + 50) * (baseMult * 2)`.
- **Final**: `totalChips * totalMult` (or Chips then Mult as in Balatro). Compare to blind target.

---

## Round loop (in-game)

1. **Start round**: Set hands/discards from run state; shuffle deck; draw initial hand (e.g. 8 cards).
2. **Loop**:
   - **Play hand**: Player selects 5 cards → detect poker hand → compute score. If score ≥ blind target → round won; go to shop.
   - Else: consume 1 "hand"; remove the 5 played cards from hand; draw 5 new cards (if deck empty, game over). If hands left = 0 or cards in hand < 5 → game over (round lost).
   - **Discard** (optional, before or after play): Player chooses up to 5 cards to discard; consume 1 "discard"; replace those with draws. Limit discards per round.
3. **Shop**: Add dollars for beating blind; show shop (e.g. 2–3 Jokers, 1 pack, 1 voucher). Player buys or skips; then advance to next round (or next ante).

---

## Blinds and antes

- **Ante 1–8**: Target chips = base × ante multiplier (e.g. 300, 600, 900, … for Small; higher for Big/Boss).
- **Round order**: Small Blind (round 0) → Big Blind (round 1) → Boss Blind (round 2) → next ante. Ante 8 Boss = "Showdown" (win condition).
- **Boss effects**: Optional for MVP: e.g. "Boss 1: −1 hand". Store per-boss effect and apply when round starts.

---

## Shop (simplified)

- **Jokers**: 2–3 random Jokers with prices; buy one (add to Joker slots). Pool of 5–10 simple Jokers for MVP (e.g. +30 Chips, +1 Mult, ×2 Mult).
- **Booster pack**: Optional; gives a random playing card (add to deck) or a Tarot. Can defer to post-MVP.
- **Vouchers**: Optional; e.g. "+1 hand per round", "+1 discard". Can defer.

---

## Card presentation (SVG)

Cards will be **SVG-based** so they scale cleanly in the browser. No custom illustrated art will be generated as part of this project (no hand-drawn card faces or joker artwork).

- **MVP — procedural SVG (Stage 8)**: The game **generates** card visuals in code. For each card, Nim (compiled to JS) builds an SVG string or DOM subtree: a rounded rectangle, rank and suit as text or Unicode symbols (♥ ♦ ♣ ♠), and optional simple shapes (e.g. corner pips). Same for Jokers: a rect + name and effect text. All logic lives in Nim; no image files required. This is “art” only in the sense of structured, readable SVG markup.
- **Stage 9 — SVG cards with actual face**: A dedicated phase extends card SVG so each card has a **proper face**: (1) **Number cards (2–10)**: center area shows the correct **pip layout** (e.g. two pips for 2, standard diamond/heart/club/spade arrangement for each count). (2) **Face cards (J, Q, K)**: center shows a **stylized face** — e.g. simple geometric or symbolic design (crown for King, distinct silhouette for Queen/Jack) so they are visually distinct. Card frame and corner indices remain. Implementation in `src/card_svg.nim`; testable by asserting generated SVG content (rank, suit, pips/face presence).
- **Optional later — asset SVG**: If you add your own card or joker art, the renderer can accept **external SVG assets** (e.g. `assets/cards/ah.svg`). You can then replace procedural faces with custom artwork; the code just places and scales them.
- **Where it lives**: Card SVG generation lives in the browser UI layer (`src/ui.nim` for wiring, `src/card_svg.nim` for per-card SVG). Logic in `card_svg.nim` can be compiled for tests (C backend) so tests can assert on SVG output without a browser.

---

## File layout

- `balatro.nimble` (or similar) — package + `buildjs` (and optional `serve`) tasks.
- `index.html` — loads `balatro.js`, contains a container (e.g. `<div id="game">` or `<canvas>`) for the game; card UI is SVG (see Card presentation).
- `src/`:
  - `game.nim` — types (Card, Deck, Joker, Blind, GameState), poker hand detection, score calculation, round start/end, "play hand" / "discard" state transitions.
  - `run.nim` (optional) — run lifecycle: init run, next round, next ante, shop, win/lose. Can live in `game.nim` initially.
  - `ui.nim` — browser I/O: DOM/Canvas setup, render state (hand, score, blind target, Jokers), handle card selection (click/key), render shop and purchase. Use `when defined(js)` so this module is JS-only; game logic stays backend-agnostic.
  - `main.nim` — entry (JS): init game state, main loop (round → play/discard until round end → shop or game over), call into `game.nim` for logic and `ui.nim` for display/input.
- `tests/` — test files (run with C backend; see Testing).

---

## Code readability and documentation

All code should be **well documented** as well as readable. Apply the following across the codebase.

- **Naming**: Use descriptive names (e.g. `detectPokerHand`, `totalChipsAfterJokers`, `drawCardsIntoHand`). Avoid abbreviations except common ones (e.g. `mult`, `chips`).
- **Small, focused procedures**: One clear responsibility per proc; extract helpers so call sites read like steps (e.g. `let handType = detectPokerHand(selected); let score = computeScore(handType, jokers)`).
- **Types over magic**: Use enums for `Suit`, `Rank`, `PokerHandKind`, `BlindKind`; distinct types or named tuples where it clarifies (e.g. `Chips`, `Mult`). Avoid raw ints for domain concepts.
- **Module documentation**: At the top of each module, add a short doc comment (Nim’s `##`) describing the module’s purpose and what it provides (types, main procs). This helps navigate the project.
- **Proc and type documentation**: Document public procs and important types with `##` doc comments: purpose, parameters, return value or side effects, and any non-obvious behaviour (e.g. “Ace is low in wheel straights”). Nim can generate docs from these with `nim doc`.
- **Inline comments**: Use comments for *why* rather than *what* (e.g. Balatro hand order, ace low/high in straights). Keep them short; prefer clear names over comments for the obvious.
- **File size**: Keep modules under a few hundred lines; split by domain (e.g. `poker.nim` for hand detection, `scoring.nim` for chips/mult/jokers) so the codebase is easy to navigate.

---

## Testing

- **Framework**: Use Nim’s standard **`unittest`** (e.g. `import std/unittest`) and run tests with `nim c -r tests/run_tests.nim` or `nimble test` (add a `test` task in the nimble file that compiles and runs the test runner). Run tests with the **C backend** (default) so all stdlib and file-based test fixtures work.
- **Test layout**: Dedicate a `tests/` directory. One (or more) test files that mirror source modules (e.g. `tests/poker_test.nim`, `tests/scoring_test.nim`) so tests stay easy to find and scope.
- **What to test**:
  - **Poker hand detection**: Example hands for each type (e.g. five cards that form a flush, a straight, full house). Edge cases: wheel straight (A-2-3-4-5), ace-high straight, duplicate ranks.
  - **Scoring**: Given a hand type and a fixed set of Jokers, assert exact Chips and Mult (and final score). Test with 0 Jokers and with 1–2 simple Jokers.
  - **Round logic**: Deck draw/refill (e.g. after playing 5 cards, hand size and deck size); “run out of hands” or “run out of cards” leads to game over. Prefer small, deterministic fixtures (fixed deck order or seeded RNG).
- **Testability**: Keep pure logic (hand detection, score calculation, round transitions) in procs that take data and return values; avoid global state or UI inside these. That allows tests to call them with no browser/Canvas. UI code (`ui.nim`) can be excluded from test builds or mocked.
- **CI**: Add a `nimble test` (or `nim c -r tests/run_tests.nim`) so “well tested” is enforced by a single command and can be wired into CI later.

---

## Stages (phased delivery, tests + commit per stage)

Each stage is a self-contained unit of work: implement, add tests, run tests, then commit. Check off items as you complete them. Code in every stage should follow the **Code readability and documentation** guidelines (module and proc doc comments, clear names, comments for non-obvious behaviour).

**Test runner**: Use a single `tests/run_tests.nim` that compiles with `nim c -r` and imports all test modules, or run via `nimble test`. Keep `nimble test` green before each commit.

**Lint/format**: Run linter and formatter before each commit (see Linters and tooling). Each stage includes a checkbox for this.

---

### Stage 1: Project skeleton & JS build

**Commit:** `chore: project skeleton and JS build`

- [ ] Init git repo in project directory (`git init`)
- [ ] Add `.gitignore` (e.g. `nimcache/`, `balatro.js`, `*.js`, editor/OS files) so the first commit stays clean
- [ ] Run `nimble init` and name the package (e.g. balatro_clone)
- [ ] Add `buildjs` task to .nimble (e.g. `nim js -o:balatro.js src/main.nim`)
- [ ] Add `test` task to .nimble (e.g. `nim c -r tests/run_tests.nim`)
- [ ] Create `index.html` that loads `balatro.js` and has a game container (div or canvas)
- [ ] Create minimal `src/main.nim` that compiles to JS (e.g. log to console or draw one rect)
- [ ] Create `tests/run_tests.nim` with one trivial test (e.g. check true)
- [ ] Run `nimble test` and confirm it passes
- [ ] Run `nimble buildjs` and confirm JS is generated
- [ ] Add `lint` task to .nimble (e.g. `nim check src/main.nim` or loop over `src/*.nim`; optionally run nimpretty)
- [ ] Add `format` task to .nimble (e.g. run `nimpretty` on `src/` and `tests/`)
- [ ] Set up pre-commit hook so every commit runs linters (and optionally tests): either a script in `.git/hooks/pre-commit` that runs `nimble lint` and `nimble test` (exit non-zero on failure to block commit), or the [pre-commit](https://pre-commit.com) framework with a local hook that runs those commands
- [ ] Run linter/formatter and fix any issues
- [ ] Commit with message above (pre-commit will run lint/test before this commit)

---

### Stage 2: Cards and deck

**Commit:** `feat: cards and deck with shuffle and draw`

- [ ] Add `src/cards.nim` with types: `Suit`, `Rank`, `Card`
- [ ] Add `Deck` (e.g. `seq[Card]`), `newDeck()`, `shuffle(deck, seed?)`, `draw(deck, n)`
- [ ] Add card display string (e.g. "Ah", "10c")
- [ ] Create `tests/cards_test.nim`
- [ ] Test: new deck has 52 cards
- [ ] Test: draw reduces deck size and returns correct number of cards
- [ ] Test: shuffle with fixed seed produces deterministic order
- [ ] Add `tests/cards_test.nim` to test runner (or `nimble test` invocation)
- [ ] Run `nimble test` and confirm all pass
- [ ] Run linter/formatter and fix any issues
- [ ] Commit with message above

---

### Stage 3: Poker hand detection

**Commit:** `feat: poker hand detection and base scoring`

- [ ] Add `src/poker.nim` with `PokerHandKind` enum (HighCard through StraightFlush)
- [ ] Implement `detectPokerHand(cards: seq[Card]): PokerHandKind`
- [ ] Add base Chips/Mult table: `baseChipsAndMult(handKind)` (or equivalent)
- [ ] Create `tests/poker_test.nim`
- [ ] Test: one test per hand type (pair, two pair, three kind, straight, flush, full house, four kind, straight flush)
- [ ] Test: wheel straight (A-2-3-4-5)
- [ ] Test: ace-high straight (10-J-Q-K-A)
- [ ] Add poker_test to test runner
- [ ] Run `nimble test` and confirm all pass
- [ ] Run linter/formatter and fix any issues
- [ ] Commit with message above

---

### Stage 4: Jokers and score

**Commit:** `feat: Jokers and score calculation`

- [ ] Add `src/scoring.nim` with `Joker` type and 2–3 effect kinds (e.g. +Chips, +Mult, ×2 Mult)
- [ ] Implement `computeScore(handKind, cards, jokers)` applying base + Joker effects
- [ ] Create `tests/scoring_test.nim`
- [ ] Test: score with no Jokers matches base Chips × base Mult
- [ ] Test: +Chips Joker adds to chips before multiply
- [ ] Test: +Mult and ×2 Mult Jokers produce expected final score
- [ ] Add scoring_test to test runner
- [ ] Run `nimble test` and confirm all pass
- [ ] Run linter/formatter and fix any issues
- [ ] Commit with message above

---

### Stage 5: Round state machine

**Commit:** `feat: round state machine and play-hand loop`

- [ ] Add `src/round.nim` (or extend `game.nim`) with `RoundState` (hands left, discards left, hand cards, deck, etc.)
- [ ] Implement `startRound()`: set hands/discards, shuffle deck, draw initial hand (e.g. 8 cards)
- [ ] Implement `playHand()`: select 5 cards → score → compare to target; consume one hand; remove 5, draw 5; detect game over (hands = 0 or hand size < 5)
- [ ] Create `tests/round_test.nim`
- [ ] Test: start round gives 8 cards in hand and deck size reduced
- [ ] Test: after play hand, one hand consumed and 5 new cards drawn
- [ ] Test: game over when hands exhausted or not enough cards to play
- [ ] Add round_test to test runner
- [ ] Run `nimble test` and confirm all pass
- [ ] Run linter/formatter and fix any issues
- [ ] Commit with message above

---

### Stage 6: Blinds and antes

**Commit:** `feat: blinds and antes progression`

- [ ] Add blind list per ante (Small, Big, Boss) with target chip values (scale by ante)
- [ ] Implement advancing round index (0→1→2) and ante on round win
- [ ] Win condition: ante 8 boss defeated
- [ ] Create `tests/blinds_test.nim`
- [ ] Test: target chips increase by ante (and/or by round)
- [ ] Test: advancing round and ante on win
- [ ] Test: win condition when ante 8 boss beaten
- [ ] Add blinds_test to test runner
- [ ] Run `nimble test` and confirm all pass
- [ ] Run linter/formatter and fix any issues
- [ ] Commit with message above

---

### Stage 7: Shop

**Commit:** `feat: shop and Joker purchase`

- [ ] Add shop state: offered Jokers + prices; award $ on round win
- [ ] Implement `purchase(jokerIndex)` (spend money, add Joker to run) and skip
- [ ] After shop, advance to next round (or next ante)
- [ ] Create `tests/shop_test.nim`
- [ ] Test: purchase subtracts money and adds Joker to run
- [ ] Test: skip leaves money and Jokers unchanged
- [ ] Test: shop offers 2–3 Jokers (or similar)
- [ ] Add shop_test to test runner
- [ ] Run `nimble test` and confirm all pass
- [ ] Run linter/formatter and fix any issues
- [ ] Commit with message above

---

### Stage 8: Browser UI

**Commit:** `feat: browser UI with SVG cards and shop`

- [ ] Add `src/ui.nim` (JS-only): get canvas or container from DOM
- [ ] Procedural SVG per card: rect + rank/suit text or symbols (♥ ♦ ♣ ♠)
- [ ] Render score and blind target on screen
- [ ] Card selection: click or number keys (1–5 or 1–8) to select cards for play
- [ ] Shop screen: show Jokers for sale with prices; buy or skip
- [ ] Jokers displayed as procedural SVG (rect + name)
- [ ] Wire `src/main.nim`: round loop and shop call into game logic; event handlers refresh DOM
- [ ] Run `nimble buildjs` and manually check in browser (play hand, open shop)
- [ ] Run linter/formatter and fix any issues
- [ ] Commit with message above

---

### Stage 9: SVG cards with actual face

**Commit:** `feat: SVG cards with proper face (frame, pips, face design)`

- [ ] Add (or extend) `src/card_svg.nim`: generate full SVG per card
- [ ] Card frame: rounded rect and border
- [ ] Corner indices: rank + suit on card corners
- [ ] Number cards (2–10): center pip layout (correct number of suit symbols in standard positions)
- [ ] Face cards (J, Q, K): center stylized face (e.g. crown for King, distinct shape for Queen/Jack)
- [ ] Create `tests/card_svg_test.nim`
- [ ] Test: each of 52 cards generates SVG containing rank and suit
- [ ] Test: face cards (J, Q, K) include a distinct center element
- [ ] Test: number cards include correct number of pips
- [ ] Add card_svg_test to test runner
- [ ] Run `nimble test` and confirm all pass
- [ ] Wire UI to use new card SVG (replace minimal card display)
- [ ] Run linter/formatter and fix any issues
- [ ] Commit with message above

---

### Stage 10: Polish

**Commit:** `feat: discard phase and polish`

- [ ] Implement discard phase: use one discard to replace N cards from hand (draw replacements)
- [ ] Optional: extra Jokers or boss effect stub
- [ ] Optional: `localStorage` save/load stub
- [ ] Extend `tests/round_test.nim` or `tests/shop_test.nim` for discard behavior (if applicable)
- [ ] Optional: test for save/load if implemented
- [ ] Run `nimble test` and confirm all pass
- [ ] Run linter/formatter and fix any issues
- [ ] Commit with message above

---

## Implementation order (reference)

1. Nimble + skeleton → 2. Cards and deck → 3. Poker detection → 4. Jokers and score → 5. Round state machine → 6. Blinds and antes → 7. Shop → 8. Browser UI → 9. SVG cards with actual face → 10. Polish.

---

## Scope summary

| Feature              | MVP | Later        |
|----------------------|-----|--------------|
| 52-card deck, draw 8 | Yes |              |
| Poker hands + scoring| Yes |              |
| 2–3 simple Jokers    | Yes | 10+          |
| Blinds × 8 antes     | Yes | Boss effects |
| Shop (Jokers only)   | Yes | Packs, vouchers |
| Browser (Nim → JS)   | Yes |              |
| Discard phase        | Yes |              |
| Save/load (localStorage) | No  | Optional  |

This gives a playable Balatro-like loop in Nim for the browser, written for readability and backed by focused unit tests.
