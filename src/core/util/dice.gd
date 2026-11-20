class_name Dice
extends RefCounted
## Seedable dice. All randomness in the rules goes through one Dice instance
## so games can be replayed from a seed and tests stay deterministic.

var _rng := RandomNumberGenerator.new()


func _init(seed_value: int = 0) -> void:
	if seed_value == 0:
		_rng.randomize()
	else:
		_rng.seed = seed_value


func d6() -> int:
	return _rng.randi_range(1, 6)


func roll_2d6() -> int:
	return d6() + d6()


## Chance (0..1) that 2d6 rolls `target` or higher.
static func chance_2d6(target: int) -> float:
	if target <= 2:
		return 1.0
	if target > 12:
		return 0.0
	var ways := 0
	for a in range(1, 7):
		for b in range(1, 7):
			if a + b >= target:
				ways += 1
	return ways / 36.0
