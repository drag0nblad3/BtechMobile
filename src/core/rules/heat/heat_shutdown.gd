class_name HeatShutdown
extends RefCounted
## Shutting down and restarting from heat (book pp. 104-105).
## At 14+ heat a conscious MechWarrior rolls to override the shutdown; at
## 30+ (or unconscious) it can't be avoided. Shutting down doesn't make the
## 'Mech fall, but it is immobile and fails any piloting roll. A shut-down
## 'Mech restarts by itself below 14 heat; otherwise a conscious warrior
## rolls the same number, and never at 30+. Extreme temperatures shift the
## number (ExtremeTemp).


static func check(dice: Dice, emit: Callable, u: Unit, c: Conditions = null) -> void:
	var need := HeatScale.shutdown_avoid(u.heat)
	if c != null:
		need = ExtremeTemp.avoid(need, c)
	if u.shutdown:
		_restart(dice, emit, u, need)
		return
	need = HotDog.need(u, need)
	if need == 0:
		return
	var down := need >= 99 or not u.pilot.conscious
	if not down:
		var roll := dice.roll_2d6()
		down = roll < need
		emit.call(GameEvent.HEAT_ROLL, {"unit_id": u.id, "kind": "shutdown", "roll": roll,
				"need": need, "ok": not down})
	if down:
		u.shutdown = true
		emit.call(GameEvent.SHUTDOWN, {"unit_id": u.id, "shutdown": true})


static func _restart(dice: Dice, emit: Callable, u: Unit, need: int) -> void:
	var ok := need == 0
	if not ok and need < 99 and u.heat < HeatPhase.NO_RESTART_HEAT and u.pilot.conscious:
		var roll := dice.roll_2d6()
		ok = roll >= need
		emit.call(GameEvent.HEAT_ROLL, {"unit_id": u.id, "kind": "restart", "roll": roll,
				"need": need, "ok": ok})
	if ok:
		u.shutdown = false
		emit.call(GameEvent.SHUTDOWN, {"unit_id": u.id, "shutdown": false})
