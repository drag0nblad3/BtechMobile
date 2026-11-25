class_name FormationLuck
extends RefCounted
## A Battle Lance's shared luck (Campaign Operations p. 61): 6 Lucky rerolls
## any of its units may take, one per failed roll, while the formation holds.
## A unit takes at most 4 rerolls in a battle, its own Lucky included.

const UNIT_MAX := 4


static func available(state: GameState, u: Unit) -> bool:
	if state == null or u.luck_used >= UNIT_MAX:
		return false
	return int(Formation.of(state, u).get("luck", 0)) > 0


static func take(state: GameState, u: Unit) -> void:
	var f := Formation.of(state, u)
	f["luck"] = int(f["luck"]) - 1
