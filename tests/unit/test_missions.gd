extends TestCase
## Missions (book pp. 225-233): objectives, Victory Points, crippling,
## Forced Withdrawal, leaving the battlefield, Random Duration.

var events: Array = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append([t, d])


func _state(mission: Dictionary) -> GameState:
	events.clear()
	var s := GameState.new(open_map(6, 8))
	s.mission.def = Mission.from_dict(mission)
	return s


func _kill_loc(u: Unit, loc: int) -> void:
	u.structure[loc] = 0
	u.armor[loc] = 0


func test_control_needs_more_standing_mechs() -> void:
	var s := _state({"victory": "vp", "scoring": "each", "objectives": [{"hex": "0304", "radius": 1, "vp": 3}]})
	var o := s.mission.def.objectives[0]
	var a := mech("hunchback_hbk4g", 0, o.coord, 0, 1)
	s.add_unit(a)
	check_eq(ObjectiveControl.controller(s, o), 0)
	var b := mech("hunchback_hbk4g", 1, Hex.neighbor(o.coord, 0), 3, 2)
	s.add_unit(b)
	check_eq(ObjectiveControl.controller(s, o), -1, "tie: nobody")
	b.prone = true
	check_eq(ObjectiveControl.controller(s, o), 0, "prone 'Mechs don't count")
	check_eq(ObjectiveControl.score(s, 0), 3)


func test_pairs_and_threshold_scoring() -> void:
	var s := _state({"victory": "vp", "scoring": "pairs", "objectives": [
			{"hex": "0102", "owner": 0}, {"hex": "0602", "owner": 0}, {"hex": "0107", "owner": 1}]})
	for o in s.mission.def.objectives:
		s.add_unit(mech("hunchback_hbk4g", 0, o.coord, 0, s.units.size() + 1))
	check_eq(ObjectiveControl.score(s, 0), 1, "two friendly + one enemy = one pair")
	s.mission.def.scoring = "threshold"
	check_eq(ObjectiveControl.score(s, 0), 2, "all three held")


func test_crippling_and_torso_roll() -> void:
	var s := _state({"victory": "last_standing", "forced_withdrawal": true})
	var u := mech("hunchback_hbk4g", 0, hex_at(2, 3), 0, 1)
	s.add_unit(u)
	u.engine_hits = 2
	check_eq(Crippled.reason(s, LoadedDice.new(), _emit, u), "two engine hits")
	u.engine_hits = 0
	_kill_loc(u, Location.LA)
	check_eq(Crippled.reason(s, LoadedDice.new(), _emit, u), "", "one arm isn't enough")
	_kill_loc(u, Location.RL)
	check(Crippled.reason(s, LoadedDice.new(), _emit, u) != "", "arm + leg")
	var v := mech("hunchback_hbk4g", 0, hex_at(3, 3), 0, 2)
	s.add_unit(v)
	_kill_loc(v, Location.RT)
	var dice := LoadedDice.new()
	dice.queue_2d6(9)  # passes: the torso is ignored
	check_eq(Crippled.reason(s, dice, _emit, v), "")
	check(s.mission.torso_saved[v.id], "remembered")
	_kill_loc(v, Location.LL)
	check(Crippled.reason(s, LoadedDice.new(), _emit, v) != "", "the saved torso still counts as a limb")


func test_forced_withdrawal_moves_and_leaving() -> void:
	var s := _state({"victory": "last_standing", "forced_withdrawal": true})
	var u := mech("hunchback_hbk4g", 0, hex_at(2, 5), 0, 1)
	var e := mech("hunchback_hbk4g", 1, hex_at(2, 0), 3, 2)
	s.add_unit(u)
	s.add_unit(e)
	u.engine_hits = 2
	var gc := GameController.new(s, 3)
	gc.start_turn()
	check(s.mission.crippled.has(u.id), "crippled as soon as it happens")
	var opts := MovePlanner.plan(s, u, MoveMode.Kind.WALK)
	var north := MoveOptions.key(hex_at(2, 4), 0)
	var south := MoveOptions.key(hex_at(2, 7), 3)
	check(ForcedWithdrawal.problem(s, u, opts, north, false) != "", "can't move away from home (south)")
	check_eq(ForcedWithdrawal.problem(s, u, opts, south, false), "")
	check_eq(MissionFlow.exit_kind(s, u, hex_at(2, 7)), "withdraw")
	check_eq(MissionFlow.move_problem(s, u, south, MoveMode.Kind.WALK, true), "", "2 MP there, 1 MP to leave")


func test_unit_vp_and_withdrawal_half() -> void:
	var s := _state({"victory": "vp", "unit_vp": true, "forced_withdrawal": true})
	var a := mech("hunchback_hbk4g", 0, hex_at(1, 1), 0, 1)
	var b := mech("hunchback_hbk4g", 1, hex_at(4, 4), 0, 2)
	s.add_unit(a)
	s.add_unit(b)
	var value := VictoryPoints.unit_value(b)
	check_eq(value, ceili(BattleValue.of(b.def) / 100.0), "BV / 100 rounded up")
	s.mission.crippled[b.id] = "test"
	check_eq(VictoryPoints.unit_vp(s, 0), value, "crippled counts as destroyed")
	s.mission.exited[b.id] = "withdraw"
	check_eq(VictoryPoints.unit_vp(s, 1), ceili(value / 2.0), "saved: half back")
	check_eq(VictoryPoints.unit_vp(s, 0), value, "the enemy still scores it")


func test_vp_mission_ends_on_time_with_tiebreak() -> void:
	var s := _state({"victory": "vp", "turns": 2})
	s.add_unit(mech("atlas_as7d", 0, hex_at(1, 1), 0, 1))
	s.add_unit(mech("locust_lct1v", 1, hex_at(4, 6), 0, 2))
	s.turn = 2
	var r := MissionFlow.outcome(s, true)
	check_eq(r["winner"], 1, "tied at 0 VP: the cheaper force wins")
	s.turn = 1
	check(MissionFlow.outcome(s, true).is_empty(), "not over yet")


func test_random_duration_table() -> void:
	check_eq(RandomDuration.ends_on(6), 0)
	check_eq(RandomDuration.ends_on(7), 1)
	check_eq(RandomDuration.ends_on(9), 2)
	check_eq(RandomDuration.ends_on(12), 4)


func test_no_mission_keeps_last_side_standing() -> void:
	var s := GameState.new(open_map(4, 4))
	s.add_unit(mech("hunchback_hbk4g", 0, hex_at(1, 1), 0, 1))
	var b := mech("hunchback_hbk4g", 1, hex_at(2, 2), 0, 2)
	s.add_unit(b)
	check(MissionFlow.outcome(s, false).is_empty())
	b.destroyed = true
	check_eq(MissionFlow.outcome(s, false)["winner"], 0)


func test_bots_play_a_vp_mission_with_withdrawal() -> void:
	var s := ScenarioLoader.load_file("res://data/scenarios/test_skirmish.json", terrain(), designs())
	s.mission.def = Mission.from_dict({"victory": "vp", "turns": 6, "unit_vp": true, "forced_withdrawal": true,
			"scoring": "each", "objectives": [{"hex": "0809", "radius": 2, "vp": 3}]})
	var gc := GameController.new(s, 7)
	gc.start_turn()
	var guard := 0
	while not s.game_over and guard < 3000:
		guard += 1
		if not Bot.act(gc, s.active_side()):
			break
	check(s.game_over, "finished (turn %d, guard %d)" % [s.turn, guard])
	check(s.turn <= 6, "within the time limit")
	var over := gc.history.filter(func(e: GameEvent) -> bool: return e.type == GameEvent.GAME_OVER)
	check(over.size() == 1 and over[0].data.has("scores"), "scored")
