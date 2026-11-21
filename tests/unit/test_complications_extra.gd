extends TestCase
## ECM Interference and Waves complications (book pp. 229, 233).

var events: Array = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append([t, d])


func test_ecm_interference_jams_artemis_until_a_sensor_check() -> void:
	var s := GameState.new(open_map(6, 8))
	s.mission.def = Mission.from_dict({"victory": "last_standing"})
	s.mission.def.ecm_interference = true
	var a := mech("hunchback_hbk4g", 0, hex_at(2, 6), 0, 1)
	var t := mech("hunchback_hbk4g", 1, hex_at(2, 2), 3, 2)
	s.add_unit(a)
	s.add_unit(t)
	var th := ToHit.new()
	check(Ecm.artemis_blocked(s, a, t, th) != "", "jammed")
	s.ecm_clear[a.id] = true
	check_eq(Ecm.artemis_blocked(s, a, t, th), "", "a passed sensor check clears it")
	a.weapons[0].artemis = true
	EcmInterference.sensor_checks(s, LoadedDice.new([1, 1]), _emit)
	check(not s.ecm_clear.has(a.id), "a fresh check each turn; 2 fails")
	check_eq(events.size(), 1, "only 'Mechs with Artemis roll")


func test_waves_hold_back_half_and_arrive() -> void:
	var s := GameState.new(open_map(6, 12))
	s.mission.def = Mission.from_dict({"victory": "last_standing"})
	for i in 3:
		s.add_unit(mech("hunchback_hbk4g", 0, hex_at(i, 11), 0, i + 1))
		s.add_unit(mech("hunchback_hbk4g", 1, hex_at(i, 0), 3, i + 11))
	Waves.hold_back(s)
	check_eq(s.waiting.size(), 2, "one of three per side")
	check_eq(s.sides_alive(), [0, 1])
	s.turn = 1
	Waves.start_turn(s, LoadedDice.new([6, 6]), _emit)
	check_eq(s.waiting.size(), 2, "nothing on turn 1")
	s.turn = 2
	Waves.start_turn(s, LoadedDice.new([3, 2]), _emit)
	check_eq(s.waiting.size(), 1, "3+ arrives, 2 doesn't")
	var came: Unit = s.units[s.units.size() - 1]
	check(Hex.to_offset(came.coord).y == 10 or Hex.to_offset(came.coord).y == 11, "in along its home edge")
	s.turn = 4
	Waves.start_turn(s, LoadedDice.new(), _emit)
	check(s.waiting.is_empty(), "surely by the third roll")


func test_complication_names_cover_the_new_results() -> void:
	for c in ["ecm", "fog_of_war", "thicker_fog", "waves"]:
		check(Complications.SUPPORTED.has(c) and Complications.NAMES.has(c), c)
	check(not Complications.SUPPORTED.has("edge"), "Edge still rerolled")


func test_bots_play_with_waves() -> void:
	var b := ForceBuilder.new(UnitDb.load_dir())
	b.rosters = [["hunchback_hbk4g", "jenner_jr7d"], ["wolverine_wvr6r", "hunchback_hbk4g"]]
	b.mission_id = "general_melee"
	var map := MapLoader.load_file("res://data/maps/test_valley.json", terrain())
	var s := b.build(map, Dice.new(6))
	s.mission.def.waves = true
	Waves.hold_back(s)
	var gc := GameController.new(s, 19)
	gc.start_turn()
	var guard := 0
	while not s.game_over and guard < 4000:
		guard += 1
		if not Bot.act(gc, gc.deciding_side()):
			break
	check(s.game_over, "finished (turn %d)" % s.turn)
	check(s.waiting.is_empty() or s.game_over, "waves arrived")
