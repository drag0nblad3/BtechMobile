class_name Initiative
extends RefCounted
## Initiative: each side rolls 2d6, rerolling ties. The loser acts first in
## every action phase, so the winner sees enemy moves before committing.


## Returns {rolls: {side: total}, order: [sides, loser first]}.
static func roll(dice: Dice, sides: Array[int]) -> Dictionary:
	var rolls := {}
	var unique := false
	while not unique:
		var seen := {}
		unique = true
		for s in sides:
			rolls[s] = dice.roll_2d6()
			if seen.has(rolls[s]):
				unique = false
			seen[rolls[s]] = true
	var order := sides.duplicate()
	order.sort_custom(func(a, b): return rolls[a] < rolls[b])
	return {"rolls": rolls, "order": order}


## Unit-by-unit alternation, loser first; sides with nothing left are skipped.
## TODO(rules): proper unequal-numbers batching.
static func alternating_order(state: GameState, sides: Array) -> Array[int]:
	var out: Array[int] = []
	var most := 0
	for s: int in sides:
		most = maxi(most, state.units_of_side(s).size())
	for i in most:
		for s: int in sides:
			out.append(s)
	return out
