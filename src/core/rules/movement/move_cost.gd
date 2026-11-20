class_name MoveCost
extends RefCounted
## MP cost for a 'Mech to enter one hex (Total Warfare, Ground Movement).
## Returns PROHIBITED when the move is illegal.

const PROHIBITED := -1
const MAX_LEVEL_CHANGE := 2


static func enter_cost(map: BattleMap, from: Vector2i, to: Vector2i, mode: int) -> int:
	var src := map.get_tile(from)
	var dst := map.get_tile(to)
	if src == null or dst == null:
		return PROHIBITED
	# Level changes compare hex levels (water hexes use their surface level).
	# TODO(rules): verify water/level interaction against TW p.48-50.
	var change := absi(dst.level - src.level)
	if change > MAX_LEVEL_CHANGE:
		return PROHIBITED
	var cost := 1 + dst.terrain.move_cost + change
	if dst.building != null:
		cost += dst.building.type.move_cost
	if dst.is_water():
		# Running MP may not be used to enter Depth 1+ water.
		if mode == MoveMode.Kind.RUN:
			return PROHIBITED
		cost += 1 if dst.depth == 1 else 3
	return cost
