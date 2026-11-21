extends TestCase
## Combat drops (book pp. 227-228) and the Steel Rain mission.


func _game(drop_turn := 1) -> Array:
	var s := GameState.new(open_map(8, 12))
	var a := mech("hunchback_hbk4g", 0, hex_at(3, 10), 0, 1)
	var d := mech("hunchback_hbk4g", 1, hex_at(3, 1), 3, 2)
	s.add_unit(a)
	s.add_unit(d)
	CombatDrop.reserve(s, d, drop_turn)
	return [s, a, d]


func _gc(s: GameState, rolls: Array) -> GameController:
	var gc := GameController.new(s, 1)
	gc.dice = LoadedDice.new(rolls)
	return gc


func test_reserves_wait_off_the_field() -> void:
	var g := _game(2)
	var s: GameState = g[0]
	var d: Unit = g[2]
	check(not s.units.has(d) and s.reserves.has(d))
	check_eq(s.sides_alive(), [0, 1], "still in the game")
	var gc := GameController.new(s, 1)
	gc.start_turn()
	s.order_index = 0
	check(not CombatDrop.ready(s, d), "not before its drop turn")


func test_good_landing() -> void:
	var g := _game()
	var s: GameState = g[0]
	var d: Unit = g[2]
	var gc := GameController.new(s, 1)
	gc.start_turn()
	gc.dice = LoadedDice.new([6, 6])
	var aim := hex_at(4, 6)
	while s.active_side() != 1:
		var a: Unit = gc.pending_units()[0]
		gc.submit_move(a, MoveOptions.key(a.coord, a.facing), MoveMode.Kind.WALK)
	check(gc.combat_drop(d, aim, 0), "dropped")
	check_eq(d.coord, aim)
	check(s.units.has(d) and d.landed and d.has_fired, "can't act the turn it lands")
	var th := ToHit.new()
	ToHitCalc.add_movement(th, g[1], d)
	check(th.mods.any(func(m: Dictionary) -> bool: return m["label"] == "just dropped" and m["value"] == 3), "+3 to hit it")


func test_failed_landing_scatters_and_falls() -> void:
	var g := _game()
	var s: GameState = g[0]
	var d: Unit = g[2]
	var events := []
	var emit := func(t: StringName, data: Dictionary) -> void: events.append(t)
	# need 5, roll 3: misses by 2; direction 3 (south-east... d6 4 = south), 1 x 2 hexes
	var dice := LoadedDice.new([1, 2, 4, 1, 6, 6, 6, 6, 6, 6])
	s.phase = Phase.Kind.MOVEMENT
	s.turn = 1
	check(CombatDrop.drop(s, dice, emit, d, hex_at(4, 4), 0))
	check(d.coord != hex_at(4, 4), "scattered")
	check(d.prone, "and fell")
	check(events.has(GameEvent.FALL))


func test_missing_by_four_is_fatal() -> void:
	var g := _game()
	var s: GameState = g[0]
	var d: Unit = g[2]
	s.phase = Phase.Kind.MOVEMENT
	s.turn = 1
	CombatDrop.drop(s, LoadedDice.new([1, 1, 1, 1]), func(_t, _d): pass, d, hex_at(4, 4), 0)
	check(d.destroyed, "need 5, rolled 2")


func test_steel_rain_setup_and_scoring() -> void:
	var map := MapLoader.load_file("res://data/maps/test_valley.json", terrain())
	var out := StandardMissions.setup("steel_rain", map, Dice.new(5))
	var m: Mission = out["mission"]
	check_eq(m.objectives.size(), 5)
	check_eq(out["drop"], 1 - m.attacker, "the defender drops")
	for o in m.objectives:
		check(o.mobile and o.radius == 0)
	var s := GameState.new(map)
	s.mission.def = m
	s.turn = 3
	check_eq(ObjectiveControl.score(s, 1 - m.attacker), 5, "defender: 1 VP per cache nobody holds")
	check_eq(ObjectiveControl.score(s, m.attacker), 0)
	var raider := mech("hunchback_hbk4g", m.attacker, m.objectives[0].coord, 0, 1)
	s.add_unit(raider)
	MobileObjectives.after_move(s, func(_t, _d): pass, raider)
	check_eq(ObjectiveControl.score(s, m.attacker), 1)
	s.turn = 8
	check_eq(ObjectiveControl.score(s, m.attacker), 2, "doubled on turn 8")
	s.turn = 5
	raider.coord = MissionLayouts._spot(map, m.home_edge(m.attacker), 0, 0.5)
	check_eq(MissionFlow.exit_kind(s, raider, raider.coord), "mission", "the raider may leave")
	MissionFlow.leave(s, func(_t, _d): pass, raider)
	check_eq(ObjectiveControl.controller(s, m.objectives[0]), m.attacker, "a cache carried off stays theirs")


func test_bots_play_steel_rain() -> void:
	var b := ForceBuilder.new(UnitDb.load_dir())
	b.rosters = [["hunchback_hbk4g", "jenner_jr7d"], ["wolverine_wvr6r", "hunchback_hbk4g"]]
	b.mission_id = "steel_rain"
	var s := b.build(MapLoader.load_file("res://data/maps/test_valley.json", terrain()), Dice.new(6))
	s.mission.def.random_duration = false
	check_eq(s.reserves.size(), 2, "the defenders wait to drop")
	var gc := GameController.new(s, 17)
	gc.start_turn()
	var guard := 0
	while not s.game_over and guard < 4000:
		guard += 1
		if not Bot.act(gc, gc.deciding_side()):
			break
	check(s.game_over, "finished (turn %d, guard %d)" % [s.turn, guard])
	check(s.reserves.is_empty(), "everyone dropped")
	check(gc.history.any(func(e: GameEvent) -> bool: return e.type == GameEvent.COMBAT_DROP))
