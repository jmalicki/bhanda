## Blinds and antes: target chips per round, advance round/ante, win condition.

type
  BlindKind* = enum
    SmallBlind, BigBlind, BossBlind

  RunProgress* = object
    ante*: int
    roundInAnte*: int

proc targetChipsForBlind*(ante: int; blind: BlindKind): int =
  ## Target chips to beat this blind. Scales up with ante.
  let base = case blind
  of SmallBlind: 300
  of BigBlind: 600
  of BossBlind: 900
  result = base * ante

proc currentBlind*(progress: RunProgress): BlindKind =
  ## Which blind we're facing in this round.
  case progress.roundInAnte
  of 0: SmallBlind
  of 1: BigBlind
  of 2: BossBlind
  else: BossBlind

proc advanceRound*(progress: var RunProgress) =
  ## After winning a round: next round in ante, or next ante if we beat the boss.
  progress.roundInAnte += 1
  if progress.roundInAnte >= 3:
    progress.roundInAnte = 0
    progress.ante += 1

proc hasWonRun*(progress: RunProgress): bool =
  ## True after defeating the ante 8 boss (Showdown).
  progress.ante >= 9

proc targetChips*(progress: RunProgress): int =
  ## Target chips for the current round.
  targetChipsForBlind(progress.ante, progress.currentBlind)
