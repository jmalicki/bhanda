# Bhanda

A poker roguelike deck-builder in Nim (in the style of Balatro). Play poker hands to beat blind targets, buy Jokers in the shop, and win by defeating the ante 8 boss. The game compiles to JavaScript and runs in the browser.

## Play

**[Play Bhanda](docs/index.html)** — the in-repo game. CI builds and publishes it to **GitHub Pages** on every push to `main`. In the repo **Settings → Pages → Source**, choose **GitHub Actions**; the site will be at `https://<user>.github.io/bhanda/`.

## Requirements

- [Nim](https://nim-lang.org/) (2.0 or later). Install via:
  - **Linux**: `sudo apt install nim` (or use [choosenim](https://github.com/dom96/choosenim))
  - **macOS**: `brew install nim` or choosenim
  - **Windows**: [installer](https://nim-lang.org/install.html) or choosenim

## Build and run

```bash
# Install dependencies (none required for JS build)
nimble install

# Run tests (C backend)
nimble test

# Lint
nimble lint

# Format code
nimble format

# Build JavaScript for the browser (output: bhanda.js)
nimble buildjs
```

Then open `index.html` in a browser. Use a local HTTP server to avoid CORS (e.g. `python -m http.server 8000` or `nimble serve` if you add that task).

## Project layout

- `src/` — game logic and browser UI
  - `cards.nim`, `poker.nim`, `scoring.nim` — cards, hand detection, score
  - `round.nim`, `blinds.nim`, `shop.nim` — round flow, blinds, shop
  - `game.nim` — run state
  - `card_svg.nim` — SVG card generation (frame, pips, face)
  - `ui.nim` — DOM rendering (JS only)
  - `main.nim` — entry point (browser)
- `tests/` — unit tests (run with C backend)
- `PLAN.md` — full design and staged implementation plan

## How to play

1. You have a limited number of **hands** and **discards** per round.
2. Select 5 cards (click to toggle), then click **Play hand**.
3. Your hand is scored (Chips × Mult). Beat the **target** to win the round.
4. After winning, you get cash and can visit the **shop** (buy Jokers, then **Next round**).
5. Win by completing ante 8 (Showdown). Lose if you run out of hands or cards before beating the target.
