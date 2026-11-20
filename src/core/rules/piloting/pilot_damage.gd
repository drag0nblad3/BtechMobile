class_name PilotDamage
extends RefCounted
## MechWarrior wounds and consciousness rolls. Six hits kill the pilot.


static func wound(dice: Dice, emit: Callable, u: Unit, hits: int, why: String) -> void:
	if u.pilot.is_dead():
		return
	u.pilot.hits = mini(Pilot.MAX_HITS, u.pilot.hits + hits)
	emit.call(GameEvent.PILOT_HIT, {"unit_id": u.id, "hits": u.pilot.hits, "why": why})
	if u.pilot.is_dead():
		u.pilot.conscious = false
		if not u.destroyed:
			Damage.destroy_unit(u, "MechWarrior killed")
			emit.call(GameEvent.UNIT_DESTROYED, {"unit_id": u.id, "reason": u.destroyed_reason})
		return
	if u.pilot.conscious:
		consciousness_roll(dice, emit, u)


## Roll to stay (or wake up) conscious.
static func consciousness_roll(dice: Dice, emit: Callable, u: Unit) -> void:
	var need := u.pilot.consciousness_target()
	var roll := dice.roll_2d6()
	var ok := roll >= need
	var was := u.pilot.conscious
	u.pilot.conscious = ok
	emit.call(GameEvent.CONSCIOUSNESS, {"unit_id": u.id, "roll": roll, "need": need,
			"conscious": ok, "was_conscious": was})
