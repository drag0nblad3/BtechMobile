class_name Psr
extends RefCounted
## Piloting skill rolls and falls. Filled in by the piloting module.


static func fall_from_shutdown(_dice: Dice, _emit: Callable, u: Unit) -> void:
	u.prone = true


## Rolls owed at the end of a phase (20+ damage, leg damage, ...).
static func end_of_phase(state: GameState, _dice: Dice, _emit: Callable) -> void:
	for u in state.units:
		u.damage_this_phase = 0
