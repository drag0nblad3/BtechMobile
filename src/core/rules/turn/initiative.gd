class_name Initiative
extends RefCounted
## Initiative: each side rolls 2d6, rerolling ties. The loser acts first in
## every action phase, so the winner sees enemy moves before committing.
## `bonus` (side -> int, e.g. the Initiative Die) is added to every roll,
## tiebreakers included; totals may go below 2 or above 12.


## Returns {rolls: {side: total}, order: [sides, loser first], bonus}.
static func roll(dice: Dice, sides: Array[int], bonus: Dictionary = {}) -> Dictionary:
	var rolls := {}
	var unique := false
	while not unique:
		var seen := {}
		unique = true
		for s in sides:
			rolls[s] = dice.roll_2d6() + int(bonus.get(s, 0))
			if seen.has(rolls[s]):
				unique = false
			seen[rolls[s]] = true
	var order := sides.duplicate()
	order.sort_custom(func(a, b): return rolls[a] < rolls[b])
	return {"rolls": rolls, "order": order, "bonus": bonus}

