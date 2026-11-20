class_name PhysicalPhase
extends RefCounted
## Resolves declared physical attacks. Filled in by the physical module.


static func resolve(state: GameState, _dice: Dice, _emit: Callable) -> void:
	state.declared_physical.clear()
