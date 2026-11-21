class_name BotMasc
extends RefCounted
## Bot MASC and supercharger use: plan the move as if the boost worked, and
## engage it only when the faster move scores better by enough to cover the
## risk, and the roll is still easy (3+ fails 1 time in 36, 5+ 1 in 6). A
## failed roll falls back to a normal move. A supercharger failure wrecks the
## engine's top slots, so it wants a bigger gain.

const MIN_GAIN := {3: 0.5, 5: 2.0}  ## Score gain wanted, by the number to roll.
const SC_EXTRA := 1.0


## The move to make, engaging MASC and/or the supercharger first if worth it.
static func plan(gc: GameController, u: Unit, normal: Dictionary) -> Dictionary:
	var m := _try(gc, u, normal, false)
	return _try(gc, u, m, true)


static func _try(gc: GameController, u: Unit, normal: Dictionary, sc: bool) -> Dictionary:
	var s := gc.state
	var problem := Supercharger.problem(u) if sc else Masc.problem(u)
	var need := Supercharger.need(u) if sc else Masc.need(u)
	if problem != "" or not MIN_GAIN.has(need) or ForcedWithdrawal.withdrawing(s, u):
		return normal
	_boost(u, sc, true)
	var fast := BotMove.plan(s, u)
	_boost(u, sc, false)
	if fast["mode"] != MoveMode.Kind.RUN or fast["score"] < normal["score"] + float(MIN_GAIN[need]) + (SC_EXTRA if sc else 0.0):
		return normal
	var what := "its supercharger" if sc else "MASC"
	if gc.engage_supercharger(u) if sc else gc.engage_masc(u):
		fast = BotMove.plan(s, u)
		fast["reason"] = "engages %s (%d+ to work) to reach further: %s" % [what, need, fast["reason"]]
		return fast
	var fallback := BotMove.plan(s, u)
	fallback["reason"] = "%s failed, so it moves at normal speed: %s" % [what[0].to_upper() + what.substr(1), fallback["reason"]]
	return fallback


static func _boost(u: Unit, sc: bool, on: bool) -> void:
	if sc:
		u.sc_active = on
	else:
		u.masc_active = on
