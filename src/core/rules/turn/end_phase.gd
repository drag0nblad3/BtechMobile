class_name EndPhase
extends RefCounted
## End Phase: unconscious MechWarriors try to wake up.


static func run(state: GameState, dice: Dice, emit: Callable) -> void:
	for u in state.units:
		if not u.destroyed and not u.pilot.conscious and not u.pilot.is_dead():
			PilotDamage.consciousness_roll(dice, emit, u)
