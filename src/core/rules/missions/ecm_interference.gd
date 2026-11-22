class_name EcmInterference
extends RefCounted
## ECM Interference complication (book p. 229): the whole battlefield counts
## as inside hostile ECM. Of the systems in this game that only touches
## Artemis IV (Ecm). Before firing, a 'Mech with Artemis makes a sensor check
## (p. 113); success ignores the interference for the rest of the turn.
## TODO(rules): the check is made at the start of the Weapon Attack Phase for
## every 'Mech with Artemis, rather than when it chooses to fire one.


static func active(state: GameState) -> bool:
	return state.mission.def != null and state.mission.def.ecm_interference


## Is `u` jammed by the interference this turn?
static func jams(state: GameState, u: Unit) -> bool:
	return active(state) and not state.ecm_clear.has(u.id)


## Start of the Weapon Attack Phase.
static func sensor_checks(state: GameState, dice: Dice, emit: Callable) -> void:
	state.ecm_clear.clear()
	if not active(state):
		return
	for u in state.units:
		if u.destroyed or u.shutdown or not u.pilot.conscious or not _has_artemis(u):
			continue
		var th := LowVisibility.sensor_check_target(u)
		if th.impossible != "":
			continue
		var r := dice.roll_2d6()
		var ok := r >= th.target()
		if ok:
			state.ecm_clear[u.id] = true
		emit.call(GameEvent.SENSOR_CHECK, {"unit_id": u.id, "roll": r, "need": th.target(), "ok": ok,
				"why": "battlefield ECM interference", "mods": th.mods})


static func _has_artemis(u: Unit) -> bool:
	for w in u.weapons:
		if w.artemis and u.can_fire(w):
			return true
	return false
