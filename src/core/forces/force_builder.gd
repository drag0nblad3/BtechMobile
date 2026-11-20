class_name ForceBuilder
extends RefCounted
## Builds two forces under a tonnage budget, then deploys them on a map:
## side 0 along the south edge facing north, side 1 along the north edge.
## TODO(rules): Battle Value balancing instead of plain tonnage.

const MAX_UNITS := 4
const BUDGETS := [100, 150, 200, 300, 400]

var units: UnitDb
var budget: int = 150
var rosters: Array = [[], []]  ## Per side: Array[String] of UnitDef ids.


func _init(unit_db: UnitDb, tons: int = 150) -> void:
	units = unit_db
	budget = tons


func tons(side: int) -> int:
	var n := 0
	for id: String in rosters[side]:
		n += units.get_def(id).tonnage
	return n


## Why a design can't be added, or "" if it can.
func cant_add(side: int, def_id: String) -> String:
	var def := units.get_def(def_id)
	if def == null:
		return "Unknown design"
	if rosters[side].size() >= MAX_UNITS:
		return "A lance is at most %d 'Mechs" % MAX_UNITS
	if tons(side) + def.tonnage > budget:
		return "Over budget: %d of %d tons left" % [budget - tons(side), budget]
	return ""


func add(side: int, def_id: String) -> bool:
	if cant_add(side, def_id) != "":
		return false
	rosters[side].append(def_id)
	return true


func remove(side: int, index: int) -> void:
	if index >= 0 and index < rosters[side].size():
		rosters[side].remove_at(index)


func ready_to_fight() -> bool:
	return not rosters[0].is_empty() and not rosters[1].is_empty()


func build(map: BattleMap) -> GameState:
	var state := GameState.new(map)
	var next_id := 1
	for side in 2:
		var row := map.height - 2 if side == 0 else 1
		var ids: Array = rosters[side]
		for i in ids.size():
			var col := int(round((i + 1) * map.width / float(ids.size() + 1))) - 1
			var c := _free_hex(state, Hex.from_offset(Vector2i(col, row)))
			state.add_unit(Unit.new(next_id, units.get_def(ids[i]), side, c, 0 if side == 0 else 3))
			next_id += 1
	return state


## Nearest hex to `c` that is dry-ish (depth < 2) and empty.
func _free_hex(state: GameState, c: Vector2i) -> Vector2i:
	for radius in 6:
		for t: Vector2i in state.map.coords():
			if Hex.distance(t, c) != radius:
				continue
			var tile := state.map.get_tile(t)
			if tile.depth < 2 and state.unit_at(t) == null:
				return t
	return c
