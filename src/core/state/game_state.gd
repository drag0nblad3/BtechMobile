class_name GameState
extends RefCounted
## Complete, serializable-in-principle state of one battle.
## Rules code reads and mutates this; views only read it.

var map: BattleMap
var units: Array[Unit] = []
var turn: int = 0
var phase: int = Phase.Kind.INITIATIVE
## Sides in the order they act this phase (initiative loser first).
var side_order: Array[int] = []
## Index into side_order of the side that acts next.
var order_index: int = 0
var initiative_rolls: Dictionary = {}  # side -> 2d6 total


func _init(battle_map: BattleMap) -> void:
	map = battle_map


func add_unit(u: Unit) -> void:
	units.append(u)


func unit_by_id(unit_id: int) -> Unit:
	for u in units:
		if u.id == unit_id:
			return u
	return null


func unit_at(c: Vector2i) -> Unit:
	for u in units:
		if u.coord == c:
			return u
	return null


func units_of_side(side: int) -> Array[Unit]:
	var out: Array[Unit] = []
	for u in units:
		if u.side == side:
			out.append(u)
	return out


func sides() -> Array[int]:
	var out: Array[int] = []
	for u in units:
		if not out.has(u.side):
			out.append(u.side)
	out.sort()
	return out


func active_side() -> int:
	if side_order.is_empty():
		return -1
	return side_order[order_index % side_order.size()]
