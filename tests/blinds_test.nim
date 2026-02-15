## Tests for blinds and antes.

import std/unittest
import ../src/blinds

suite "blinds":
  test "target chips increase by ante":
    check targetChipsForBlind(1, SmallBlind) == 300
    check targetChipsForBlind(2, SmallBlind) == 600
    check targetChipsForBlind(1, BossBlind) == 900

  test "advancing round and ante":
    var p = RunProgress(ante: 1, roundInAnte: 0)
    check p.currentBlind == SmallBlind
    advanceRound(p)
    check p.roundInAnte == 1
    check p.currentBlind == BigBlind
    advanceRound(p)
    advanceRound(p)
    check p.roundInAnte == 0
    check p.ante == 2

  test "win condition when ante 8 boss beaten":
    var p = RunProgress(ante: 8, roundInAnte: 2)
    check not hasWonRun(p)
    advanceRound(p)
    check p.ante == 9
    check hasWonRun(p)
