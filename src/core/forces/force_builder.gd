class_name ForceBuilder
extends RefCounted
## Builds two forces under a Battle Value budget, then deploys them on a map:
## side 0 along the south edge facing north, side 1 along the north edge.

const MAX_UNITS := 4
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
	if rosters[side].size() >= MAX_UNITS:
		return "A lance is at most %d 'Mechs" % MAX_UNITS
	if bv(side) + unit_bv(side, def) > budget:
		return "Over budget: %d of %d BV left" % [budget - bv(side), budget]
	return ""


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
		var row := map.height - 2 if side == 0 else 1
		var ids: Array = rosters[side]
		var placed: Array[Unit] = []
		for i in ids.size():
			var col := int(round((i + 1) * map.width / float(ids.size() + 1))) - 1
			var c := Hex.INVALID if not setup.is_empty() else _free_hex(state, Hex.from_offset(Vector2i(col, row)))
			var u := Unit.new(next_id, units.get_def(ids[i]), side, c, 0 if side == 0 else 3)
			u.pilot = Pilot.new(skills[side].x, skills[side].y)
			state.add_unit(u)
			placed.append(u)
			next_id += 1
		if not setup.is_empty():
			Deployment.place(state, placed, setup["zones"][side])
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
