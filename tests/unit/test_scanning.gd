extends TestCase
## Scanning (book p. 233) and the Sensor Check and Urban Sweep missions.

var events: Array = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append([t, d])


func _state(mission: Dictionary) -> GameState:
	events.clear()
	var s := GameState.new(open_map(6, 12))
	s.mission.def = Mission.from_dict(mission)
	return s


func test_scan_target_number() -> void:
	var u := mech("hunchback_hbk4g", 0, hex_at(0, 0))
	check_eq(Scanning.target_number(u).target(), 5 + 3, "piloting 5 + 3")
	u.sensor_hits = 1
	check_eq(Scanning.target_number(u).target(), 5 + 2 + 3, "damaged sensors")


func test_sensor_check_counts_scans_and_pays_on_exit() -> void:
	var s := _state({"victory": "vp", "scan": "units", "exit": "home", "exit_from_turn": 5})
	var u := mech("hunchback_hbk4g", 0, hex_at(2, 6), 0, 1)
	var far := mech("hunchback_hbk4g", 1, hex_at(2, 1), 3, 2)
	s.add_unit(u)
	s.add_unit(far)
	check(Scanning.pick(s, u).is_empty(), "nothing within 2 hexes")
	far.coord = hex_at(2, 4)
	check_eq(Scanning.pick(s, u).get("unit"), far)
	Scanning.end_phase(s, LoadedDice.new([4, 4]), _emit)
	check_eq(s.mission.scans.get(u.id, 0), 1, "8 vs 8: a reading")
	Scanning.end_phase(s, LoadedDice.new([3, 4]), _emit)
	check_eq(s.mission.scans.get(u.id, 0), 1, "7 misses")
	s.turn = 5
	u.coord = hex_at(2, 11)
	check_eq(MissionFlow.exit_kind(s, u, u.coord), "mission", "with readings it may leave")
	s.mission.scans.erase(far.id)  # it scanned back with the leftover dice
	check_eq(MissionFlow.exit_kind(s, far, hex_at(2, 0)), "", "without readings it may not")
	MissionFlow.leave(s, _emit, u)
	check_eq(VictoryPoints.total(s, 0), 1, "1 VP per scan")


func test_urban_sweep_intel() -> void:
	var s := _state({"victory": "vp", "scan": "intel"})
	UrbanSweep.place(s.mission.def, s.map)
	var objs := s.mission.def.objectives
	check_eq(objs.size(), 6, "six counters")
	for o in objs:
		check(s.map.get_tile(o.coord).building != null, "each in a building")
		var row := Hex.to_offset(o.coord).y
		check(row >= 4 and row <= 7, "4+ hexes from both edges")
	var o := objs[0]
	var red := mech("hunchback_hbk4g", 0, Hex.neighbor(o.coord, 3), 0, 1)
	var blue := mech("hunchback_hbk4g", 1, Hex.neighbor(o.coord, 0), 3, 2)
	s.add_unit(red)
	s.add_unit(blue)
	# red: scan 6+6, intel 5; blue: scan 6+6, intel 4
	Scanning.end_phase(s, LoadedDice.new([6, 6, 5, 6, 6, 4]), _emit)
	check_eq(s.mission.vp.get(0, 0), 2, "red found intel")
	check_eq(s.mission.vp.get(1, 0), 2, "both sides may claim the same counter once")
	check(o.found and o.claimed.has(0) and o.claimed.has(1))
	check(Scanning.pick(s, red).get("objective") != o, "a side can't claim it twice")
	Scanning.start_turn(s)
	check(not s.mission.def.objectives.has(o), "found intel leaves play")
	var o2 := s.mission.def.objectives[0]
	s.map.get_tile(o2.coord).building = null
	Scanning.start_turn(s)
	check(not s.mission.def.objectives.has(o2), "a collapsed building takes its counter with it")


func test_standard_missions_set_up() -> void:
	var map := MapLoader.load_file("res://data/maps/test_valley.json", terrain())
	var sc := StandardMissions.setup("sensor_check", map, Dice.new(1))
	check_eq(sc["mission"].scan, "units")
	var us := StandardMissions.setup("urban_sweep", map, Dice.new(2))
	check_eq(us["mission"].objectives.size(), 6)


func test_bots_play_urban_sweep() -> void:
	var s := ScenarioLoader.load_file("res://data/scenarios/test_skirmish.json", terrain(), UnitDb.load_dir())
	var setup := StandardMissions.setup("urban_sweep", s.map, Dice.new(4))
	s.mission.def = setup["mission"]
	s.mission.def.random_duration = false
	var gc := GameController.new(s, 13)
	gc.start_turn()
	var guard := 0
	while not s.game_over and guard < 4000:
		guard += 1
		if not Bot.act(gc, gc.deciding_side()):
			break
	check(s.game_over, "finished (turn %d)" % s.turn)
	check(gc.history.any(func(e: GameEvent) -> bool: return e.type == GameEvent.SCAN), "they scanned")
