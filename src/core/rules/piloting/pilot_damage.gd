class_name PilotDamage
extends RefCounted
## MechWarrior wounds and consciousness (book p. 117). Six hits kill.
## A hit owes a consciousness roll, made once after the phase's damage,
## PSRs and falls are resolved, against the warrior's current hit total.
## An unconscious warrior tries to wake in each later End Phase.
## TODO(rules): in the Movement Phase the roll should come at once, not at
## the end of the phase.


static func wound(_dice: Dice, emit: Callable, u: Unit, hits: int, why: String) -> void:
	if u.pilot.is_dead() or hits <= 0:
		return
	u.pilot.hits = mini(Pilot.MAX_HITS, u.pilot.hits + hits)
	emit.call(GameEvent.PILOT_HIT, {"unit_id": u.id, "hits": u.pilot.hits, "why": why})
	if u.pilot.is_dead():
		u.pilot.conscious = false
		Damage.destroy_unit(u, "MechWarrior killed")
		Damage.announce(emit, u)
		return
	if u.pilot.conscious:
		u.pilot.roll_owed = true


## Makes the owed consciousness rolls (end of a phase).
static func resolve_owed(state: GameState, dice: Dice, emit: Callable) -> void:
	for u in state.units:
		if u.pilot.roll_owed and not u.destroyed and u.pilot.conscious:
			if not consciousness_roll(dice, emit, u):
				u.pilot.out_since_turn = state.turn
		u.pilot.roll_owed = false


## Roll to stay (or wake up) conscious. Returns the new state.
static func consciousness_roll(dice: Dice, emit: Callable, u: Unit) -> bool:
	var need := u.pilot.consciousness_target()
	var roll := dice.roll_2d6()
	var ok := roll >= need
	var was := u.pilot.conscious
	u.pilot.conscious = ok
	emit.call(GameEvent.CONSCIOUSNESS, {"unit_id": u.id, "roll": roll, "need": need,
			"conscious": ok, "was_conscious": was})
	return ok
