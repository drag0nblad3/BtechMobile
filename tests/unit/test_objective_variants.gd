extends TestCase
## Potential, fragile and mobile objectives (book pp. 232-233) and the
## Objective Raid mission.

var events: Array = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append([t, d])


func _state() -> GameState:
	events.clear()
	var s := GameState.new(open_map(6, 12))
	s.mission.def = Mission.from_dict({"victory": "vp", "scoring": "each", "scan": "potential"})
	return s


func _obj(s: GameState, c: Vector2i, mobile := true, fragile := false) -> Objective:
	var o := Objective.make(c, 0, -1, 1)
	o.mobile = mobile
	o.fragile = fragile
	s.mission.def.objectives.append(o)
	return o


func test_potential_objectives_score_only_once_confirmed() -> void:
	var s := _state()
	var o := _obj(s, hex_at(2, 5), false)
	o.potential = true
	var u := mech("hunchback_hbk4g", 0, o.coord, 0, 1)
	s.add_unit(u)
	check_eq(ObjectiveControl.score(s, 0), 0, "unconfirmed: worth nothing")
	Scanning.end_phase(s, LoadedDice.new([6, 6, 5]), _emit)
	check(not o.potential and not o.destroyed, "scan + 5: confirmed")
	check_eq(ObjectiveControl.score(s, 0), 1)
	var dud := _obj(s, hex_at(2, 6), false)
	dud.potential = true
	Scanning.end_phase(s, LoadedDice.new([6, 6, 2]), _emit)
	check(dud.destroyed, "scan + 2: a decoy")


func test_pick_up_carry_and_hold_anywhere() -> void:
	var s := _state()
	var o := _obj(s, hex_at(2, 5))
	var u := mech("hunchback_hbk4g", 0, o.coord, 0, 1)
	s.add_unit(u)
	MobileObjectives.after_move(s, _emit, u)
	check_eq(o.carrier_id, u.id, "picked up")
	check(u.carry_arm in [Location.LA, Location.RA])
	var e := mech("hunchback_hbk4g", 1, hex_at(3, 5), 3, 2)
	var e2 := mech("hunchback_hbk4g", 1, hex_at(1, 5), 3, 3)
	s.add_unit(e)
	s.add_unit(e2)
	check_eq(ObjectiveControl.controller(s, o), 0, "the carrier holds it however many enemies crowd in")
	u.coord = hex_at(4, 9)
	MobileObjectives.check(s, LoadedDice.new(), _emit)
	check_eq(o.coord, u.coord, "it travels with the carrier")
	for w in u.weapons:
		if w.loc == u.carry_arm:
			check(not ToHitCalc.weapon(s, u, w, e).possible(), "the carrying arm can't shoot")


func test_drops_when_carrier_falls_and_fragile_may_break() -> void:
	var s := _state()
	var o := _obj(s, hex_at(2, 5), true, true)
	var u := mech("hunchback_hbk4g", 0, o.coord, 0, 1)
	s.add_unit(u)
	MobileObjectives.after_move(s, _emit, u)
	u.prone = true
	MobileObjectives.check(s, LoadedDice.new([5]), _emit)
	check_eq(o.carrier_id, -1, "a fall drops it")
	check(not o.destroyed, "5 on the fragile roll: it survives")
	check_eq(u.carry_arm, -1, "arm free again")
	u.prone = false
	MobileObjectives.after_move(s, _emit, u)
	MobileObjectives.drop_prone(s, LoadedDice.new([1]), _emit, u)
	check(not o.destroyed, "lying down on purpose doesn't risk it")
	MobileObjectives.after_move(s, _emit, u)
	u.destroyed = true
	MobileObjectives.check(s, LoadedDice.new([2]), _emit)
	check(o.destroyed, "carrier destroyed, 2: broken")


func test_damaged_carrier_rolls_to_hang_on() -> void:
	var s := _state()
	var o := _obj(s, hex_at(2, 5))
	var u := mech("hunchback_hbk4g", 0, o.coord, 0, 1)
	s.add_unit(u)
	MobileObjectives.after_move(s, _emit, u)
	u.damage_this_phase = 5
	MobileObjectives.end_of_phase(s, LoadedDice.new([1, 1]), _emit)
	check_eq(o.carrier_id, -1, "failed the roll: dropped")
	check(not u.prone, "failing doesn't make it fall")


func test_one_counter_per_hex() -> void:
	var s := _state()
	var a := _obj(s, hex_at(2, 5))
	var b := _obj(s, hex_at(2, 7))
	var u := mech("hunchback_hbk4g", 0, b.coord, 0, 1)
	s.add_unit(u)
	MobileObjectives.after_move(s, _emit, u)
	u.coord = a.coord
	MobileObjectives.check(s, LoadedDice.new(), _emit)
	MobileObjectives.drop(s, LoadedDice.new(), _emit, b, "set down", false)
	check_eq(b.coord, hex_at(2, 5))
	check_eq(a.coord, Hex.neighbor(hex_at(2, 5), 0), "the old one is pushed along the dropper's facing")


func test_objective_raid_setup() -> void:
	var map := MapLoader.load_file("res://data/maps/test_valley.json", terrain())
	var out := StandardMissions.setup("objective_raid", map, Dice.new(3))
	var m: Mission = out["mission"]
	check(m.objectives.size() >= 7 and m.objectives.size() <= 12, "7-12 counters (%d)" % m.objectives.size())
	for i in m.objectives.size():
		var o := m.objectives[i]
		check(o.potential and (o.fragile or o.mobile))
		for j in range(i + 1, m.objectives.size()):
			check(Hex.distance(o.coord, m.objectives[j].coord) >= 3, "3 hexes apart")


func test_bots_play_objective_raid() -> void:
	var s := ScenarioLoader.load_file("res://data/scenarios/test_skirmish.json", terrain(), UnitDb.load_dir())
	var setup := StandardMissions.setup("objective_raid", s.map, Dice.new(8))
	s.mission.def = setup["mission"]
	s.mission.def.random_duration = false
	var gc := GameController.new(s, 21)
	gc.start_turn()
	var guard := 0
	while not s.game_over and guard < 4000:
		guard += 1
		if not Bot.act(gc, gc.deciding_side()):
			break
	check(s.game_over, "finished (turn %d)" % s.turn)
	check(gc.history.any(func(e: GameEvent) -> bool: return e.type == GameEvent.SCAN), "they scanned")
