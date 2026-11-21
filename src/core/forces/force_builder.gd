class_name ForceBuilder
extends RefCounted
## Builds two forces under a Battle Value budget, then deploys them on a map:
## side 0 along the south edge facing north, side 1 along the north edge.

const MAX_UNITS := 4
## An all-Clan side may field a Star of five (book p. 219 suggests lances
## of 4 and Stars of 5 but doesn't require either).
const STAR := 5
const FORMATION_TIP := "Inner Sphere 'Mechs fight in lances of four; the Clans fight in Stars of five, so an all-Clan side may take a fifth 'Mech."
const BUDGETS := [2000, 3000, 4500, 6000, 8000]

var units: UnitDb
var budget: int = 3000  ## Battle Value per side.
var rosters: Array = [[], []]  ## Per side: Array[String] of UnitDef ids.
var skills: Array[Vector2i] = [Vector2i(4, 5), Vector2i(4, 5)]  ## Per side: (gunnery, piloting).
var initiative_die := false  ## Use the optional Initiative Die rule.


func _init(unit_db: UnitDb, bv_budget: int = 3000) -> void:
	units = unit_db
	budget = bv_budget


func tons(side: int) -> int:
	var n := 0
	for id: String in rosters[side]:
		n += units.get_def(id).tonnage
	return n


func bv(side: int) -> int:
	var n := 0
	for id: String in rosters[side]:
		n += unit_bv(side, units.get_def(id))
	return n


## A design's BV with this side's MechWarrior skill (book p. 222).
func unit_bv(side: int, def: UnitDef) -> int:
	return BvSkill.adjusted(BattleValue.of(def), skills[side].x, skills[side].y)


## Switches a side to the next skill preset. Returns false (and keeps the
## old skill) if the roster would go over budget.
func next_skill(side: int) -> bool:
	var i := 0
	for j in BvSkill.PRESETS.size():
		if BvSkill.PRESETS[j][1] == skills[side].x and BvSkill.PRESETS[j][2] == skills[side].y:
			i = j
	var p: Array = BvSkill.PRESETS[(i + 1) % BvSkill.PRESETS.size()]
	var old := skills[side]
	skills[side] = Vector2i(p[1], p[2])
	if bv(side) > budget:
		skills[side] = old
		return false
	return true


## Why a design can't be added, or "" if it can.
func cant_add(side: int, def_id: String) -> String:
	var def := units.get_def(def_id)
	if def == null:
		return "Unknown design"
	if rosters[side].size() >= max_units(side, def_id):
		if rosters[side].size() >= MAX_UNITS and not def.is_clan():
			return "A Clan Star can hold %d, but an Inner Sphere 'Mech makes it a lance of %d" % [STAR, MAX_UNITS]
		return "A %s is at most %d 'Mechs" % [formation(side).to_lower(), max_units(side, def_id)]
	if bv(side) + unit_bv(side, def) > budget:
		return "Over budget: %d of %d BV left" % [budget - bv(side), budget]
	return ""


## 5 if every 'Mech on the side (and `adding`, if given) is Clan, else 4.
func max_units(side: int, adding: String = "") -> int:
	var ids: Array = rosters[side].duplicate()
	if adding != "":
		ids.append(adding)
	if ids.is_empty():
		return MAX_UNITS
	return STAR if ids.all(func(id: String) -> bool: return units.get_def(id).is_clan()) else MAX_UNITS


## "Star" for an all-Clan side, else "Lance".
func formation(side: int) -> String:
	return "Star" if not rosters[side].is_empty() and max_units(side) == STAR else "Lance"


func add(side: int, def_id: String) -> bool:
	if cant_add(side, def_id) != "":
		return false
	rosters[side].append(def_id)
	return true


func remove(side: int, index: int) -> void:
	if index >= 0 and index < rosters[side].size():
		rosters[side].remove_at(index)


## How even the two forces are, in plain words ("" until both have units).
func balance_text() -> String:
	var a := bv(0)
	var b := bv(1)
	if a == 0 or b == 0:
		return ""
	var diff := absf(a - b) / float(maxi(a, b))
	var stronger := Names.side(0 if a > b else 1)
	if diff < 0.05:
		return "Even fight (%d vs %d BV)." % [a, b]
	if diff < 0.15:
		return "%s is a little stronger (%d vs %d BV)." % [stronger, a, b]
	return "%s is much stronger (%d vs %d BV): expect a lopsided fight." % [stronger, a, b]


func ready_to_fight() -> bool:
	return not rosters[0].is_empty() and not rosters[1].is_empty()


func build(map: BattleMap) -> GameState:
	var state := GameState.new(map)
	state.initiative_die_rule = initiative_die
	var next_id := 1
	for side in 2:
		var row := map.height - 2 if side == 0 else 1
		var ids: Array = rosters[side]
		for i in ids.size():
			var col := int(round((i + 1) * map.width / float(ids.size() + 1))) - 1
			var c := _free_hex(state, Hex.from_offset(Vector2i(col, row)))
			var u := Unit.new(next_id, units.get_def(ids[i]), side, c, 0 if side == 0 else 3)
			u.pilot = Pilot.new(skills[side].x, skills[side].y)
			state.add_unit(u)
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
