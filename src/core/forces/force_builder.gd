class_name ForceBuilder
extends RefCounted
## Builds two forces under a Battle Value budget, then deploys them on a map:
## side 0 along the south edge facing north, side 1 along the north edge.

const MAX_UNITS := 4
## An all-Clan side may field a Star of five (book p. 219 suggests lances
## of 4 and Stars of 5 but doesn't require either).
const STAR := 5
## Battlefield Support Assets (vehicles, infantry) per side, on top of the
## lance, bought with BV at 20 per BSP (Battle Value Integration, p. 157).
const MAX_ASSETS := 4
const FORMATION_TIP := "Inner Sphere 'Mechs fight in lances of four; the Clans fight in Stars of five, so an all-Clan side may take a fifth 'Mech."
const BUDGETS := [2000, 3000, 4500, 6000, 8000]
## Battlefield condition choices on the start screen (Conditions.from_dict).
const CONDITION_PRESETS := [{}, {"night": true}, {"cold": 1}, {"cold": 3}, {"heat": 1},
		{"heat": 3}, {"gravity": 0.5}, {"gravity": 1.5}, {"wind": true}, {"low_visibility": true},
		{"rain": true}, {"snowfall": true}, {"cold": 2, "snowfall": true, "wind": true, "low_visibility": true}]

var units: UnitDb
var budget: int = 3000  ## Battle Value per side.
var rosters: Array = [[], []]  ## Per side: Array[String] of UnitDef ids.
var skills: Array[Vector2i] = [Vector2i(4, 5), Vector2i(4, 5)]  ## Per side: (gunnery, piloting).
var initiative_die := false  ## Use the optional Initiative Die rule.
var conditions := Conditions.new()  ## Battlefield conditions.
## "" = free battle (last side standing), "random" = roll on the Standard
## Mission Table, else a StandardMissions id.
var mission_id := ""
var forced_withdrawal := false
var hidden_side := -1  ## Side that starts hidden (HiddenUnits), -1 for none.
## Briefing lines from the last build (mission setup, complications).
var notes: Array = []


func _init(unit_db: UnitDb, bv_budget: int = 3000) -> void:
	units = unit_db
	budget = bv_budget


func tons(side: int) -> int:
	var n := 0
	for id: String in rosters[side]:
		n += units.get_def(id).tonnage
	return n


func bv(side: int, extra: String = "") -> int:
	var ids: Array = rosters[side] + ([extra] if extra != "" else [])
	var defs: Array = ids.map(func(id: String) -> UnitDef: return units.get_def(id))
	var net := C3.form(defs)
	var n := 0
	for i in defs.size():
		var b := unit_bv(side, defs[i])
		n += b + (roundi(b * C3.bv_percent(net.size()) / 100.0) if net.has(i) else 0)
	return n  # C3 networks raise each member's BV (p. 222)


## A design's BV with this side's MechWarrior skill (book p. 222).
func unit_bv(side: int, def: UnitDef) -> int:
	if def.asset != null:
		return def.bv  # an Asset's Skill is on its card, not the side's pilots
	if def.vehicle != null:
		return BvSkill.adjusted(def.bv, skills[side].x, skills[side].y)  # the sheet BV, crew skill
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
	if def.is_support():
		if asset_ids(side).size() >= MAX_ASSETS:
			return "At most %d vehicles or infantry per side" % MAX_ASSETS
		if bv(side, def_id) > budget:
			return "Over budget: %d of %d BV left" % [budget - bv(side), budget]
		return ""
	if mech_ids(side).size() >= max_units(side, def_id):
		if mech_ids(side).size() >= MAX_UNITS and not def.is_clan():
			return "A Clan Star can hold %d, but an Inner Sphere 'Mech makes it a lance of %d" % [STAR, MAX_UNITS]
		return "A %s is at most %d 'Mechs" % [formation(side).to_lower(), max_units(side, def_id)]
	if bv(side, def_id) > budget:
		return "Over budget: %d of %d BV left" % [budget - bv(side), budget]
	return ""


## 5 if every 'Mech on the side (and `adding`, if given) is Clan, else 4.
func max_units(side: int, adding: String = "") -> int:
	var ids: Array = mech_ids(side)
	if adding != "" and not units.get_def(adding).is_support():
		ids.append(adding)
	if ids.is_empty():
		return MAX_UNITS
	return STAR if ids.all(func(id: String) -> bool: return units.get_def(id).is_clan()) else MAX_UNITS


## "Star" for an all-Clan side, else "Lance".
func formation(side: int) -> String:
	return "Star" if not mech_ids(side).is_empty() and max_units(side) == STAR else "Lance"


## The side's 'Mech design ids (no Assets).
func mech_ids(side: int) -> Array:
	return rosters[side].filter(func(id: String) -> bool: return not units.get_def(id).is_support())


## The side's support design ids: Assets and combat vehicles.
func asset_ids(side: int) -> Array:
	return rosters[side].filter(func(id: String) -> bool: return units.get_def(id).is_support())


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


## Switches to the next battlefield condition preset.
func next_conditions() -> void:
	var cur := conditions.to_dict()
	var i := CONDITION_PRESETS.find(cur)
	conditions = Conditions.from_dict(CONDITION_PRESETS[(i + 1) % CONDITION_PRESETS.size()])


func ready_to_fight() -> bool:
	return not rosters[0].is_empty() and not rosters[1].is_empty()


func build(map: BattleMap, dice: Dice = null) -> GameState:
	var state := GameState.new(map)
	state.initiative_die_rule = initiative_die
	state.conditions = conditions
	notes = []
	var setup := {}
	if mission_id != "":
		if dice == null:
			dice = Dice.new(randi())
		var id := StandardMissions.roll(dice) if mission_id == "random" else mission_id
		setup = StandardMissions.setup(id, map, dice, forced_withdrawal)
		state.mission.def = setup["mission"]
		notes = setup["notes"]
		if setup["conditions"] != null and conditions.is_clear():
			state.conditions = setup["conditions"]
	elif forced_withdrawal:
		state.mission.def = Mission.from_dict({"name": "Battle", "forced_withdrawal": true,
				"summary": "Last side with a 'Mech still fighting wins."})
	var next_id := 1
	for side in 2:
		var placed: Array[Unit] = []
		for line in 2:  # 'Mechs in front, Assets one row behind
			var row := (map.height - 2 + line if side == 0 else 1 - line)
			row = clampi(row, 0, map.height - 1)
			var ids: Array = mech_ids(side) if line == 0 else asset_ids(side)
			for i in ids.size():
				var col := int(round((i + 1) * map.width / float(ids.size() + 1))) - 1
				var c := Hex.INVALID if not setup.is_empty() else _free_hex(state, Hex.from_offset(Vector2i(col, row)), units.get_def(ids[i]))
				var u := Unit.new(next_id, units.get_def(ids[i]), side, c, 0 if side == 0 else 3)
				if u.asset == null:
					u.pilot = Pilot.new(skills[side].x, skills[side].y)
				state.add_unit(u)
				placed.append(u)
				next_id += 1
		if not setup.is_empty():
			Deployment.place(state, placed, setup["zones"][side])
	if state.mission.def != null and state.mission.def.waves:
		Waves.hold_back(state)
	if int(setup.get("drop", -1)) >= 0:
		SteelRain.reserve_side(state, setup["drop"])
	if hidden_side >= 0:
		HiddenUnits.place_side(state, hidden_side)
	return state


## Cycles: free battle, random standard mission, then each standard mission.
func next_mission() -> void:
	var order: Array[String] = ["", "random"]
	order.append_array(StandardMissions.available_ids())
	mission_id = order[(order.find(mission_id) + 1) % order.size()]


func mission_name() -> String:
	if mission_id == "":
		return "Free battle (last side standing)"
	if mission_id == "random":
		return "Random standard mission"
	return StandardMissions.info(mission_id).get("name", mission_id)


## Nearest hex to `c` that is dry-ish (depth < 2) and empty; an Asset
## also needs a hex its movement type may be in.
func _free_hex(state: GameState, c: Vector2i, def: UnitDef = null) -> Vector2i:
	for radius in 6:
		for t: Vector2i in state.map.coords():
			if Hex.distance(t, c) != radius:
				continue
			var tile := state.map.get_tile(t)
			if tile.depth < 2 and state.unit_at(t) == null and (def == null or not def.is_support() \
					or (def.asset != null and AssetMoveCost.may_enter(def.asset, tile))
					or (def.vehicle != null and VehicleMoveCost.may_enter(def.vehicle.motive, tile))):
				return t
	return c
