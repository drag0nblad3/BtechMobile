class_name CriticalHits
extends RefCounted
## Critical hits. Filled in by the criticals module; until then, a no-op.


static func after_damage(_state: GameState, _dice: Dice, _emit: Callable, _u: Unit,
		_steps: Array[Dictionary], _tac: bool) -> void:
	pass
