class_name VoluntaryShutdown
extends RefCounted
## Shutting down on purpose (book p. 105, errata p. 104): a player may
## shut a 'Mech down in any Heat Phase and restart it in a later one. The
## restart follows the normal procedure: automatic below 14 heat, else a
## conscious MechWarrior rolls the shutdown avoid number, never at 30+.
## A 'Mech shut down by choice stays down until its player restarts it.
## TODO(rules): the request is made any time before the Heat Phase.

const OFF := "off"
const ON := "on"


## Why this request can't be made now ("" = it can). "" as `want` cancels.
static func problem(u: Unit, want: String) -> String:
	if u.destroyed:
		return "destroyed"
	match want:
		OFF:
			return "already shut down" if u.shutdown else ""
		ON:
			return "" if u.shutdown and u.voluntary_shutdown else "only a 'Mech shut down by choice can be restarted this way"
		"":
			return ""
	return "unknown request"


## Heat Phase, after heat is added: carries out a pending request.
static func apply(dice: Dice, emit: Callable, u: Unit) -> void:
	var want := u.power_request
	u.power_request = ""
	if want == OFF and not u.shutdown:
		u.shutdown = true
		u.voluntary_shutdown = true
		emit.call(GameEvent.SHUTDOWN, {"unit_id": u.id, "shutdown": true, "voluntary": true})
	elif want == ON and u.shutdown and u.voluntary_shutdown:
		var need := HeatScale.shutdown_avoid(u.heat)
		var ok := need == 0
		if not ok and need < 99 and u.heat < HeatPhase.NO_RESTART_HEAT and u.pilot.conscious:
			var roll := dice.roll_2d6()
			ok = roll >= need
			emit.call(GameEvent.HEAT_ROLL, {"unit_id": u.id, "kind": "restart", "roll": roll, "need": need, "ok": ok})
		if ok:
			u.shutdown = false
			u.voluntary_shutdown = false
			emit.call(GameEvent.SHUTDOWN, {"unit_id": u.id, "shutdown": false, "voluntary": true})
