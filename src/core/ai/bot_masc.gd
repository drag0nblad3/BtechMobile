class_name BotMasc
extends RefCounted
## Bot MASC use: plan the move as if MASC worked, and engage it only when
## the faster move scores better by enough to cover the risk, and the roll is
## still easy (3+ fails 1 time in 36, 5+ 1 in 6). A failed roll falls back
## to a normal move.

const MIN_GAIN := {3: 0.5, 5: 2.0}  ## Score gain wanted, by the number to roll.


## The move to make, engaging MASC first if it's worth it.
static func plan(gc: GameController, u: Unit, normal: Dictionary) -> Dictionary:
	var s := gc.state
	if Masc.problem(u) != "" or not MIN_GAIN.has(Masc.need(u)) or ForcedWithdrawal.withdrawing(s, u):
		return normal
	u.masc_active = true
	var fast := BotMove.plan(s, u)
	u.masc_active = false
	if fast["mode"] != MoveMode.Kind.RUN or fast["score"] < normal["score"] + float(MIN_GAIN[Masc.need(u)]):
		return normal
	var need := Masc.need(u)
	if gc.engage_masc(u):
		fast["reason"] = "engages MASC (%d+ to work) to reach further: %s" % [need, fast["reason"]]
		return fast
	var fallback := BotMove.plan(s, u)
	fallback["reason"] = "MASC failed, so it moves at normal speed: %s" % fallback["reason"]
	return fallback
