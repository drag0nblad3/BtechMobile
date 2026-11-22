extends TestCase
## Combat vehicles in play: movement costs, firing arcs, no falls or heat.


func _state(rows: Array, units: Array) -> GameState:
	var s := GameState.new(make_map(rows))
	for u: Unit in units:
		s.add_unit(u)
	return s


func test_terrain_by_motive() -> void:
	var s := _state(["c0 L0 r0 w0d1 c1 c3"], [])
	var tank := vehicle("manticore_heavy_tank", 0, hex_at(0, 0))
	var truck := vehicle("hetzer_wheeled_assault_gun", 0, hex_at(0, 0))
	var hover := vehicle("pegasus_scout_hover_tank", 0, hex_at(0, 0))
	check_eq(VehicleMoveCost.enter_cost(s.map, tank, hex_at(0, 0), hex_at(1, 0)), 2, "tracked into light woods: 2")
	check_eq(VehicleMoveCost.enter_cost(s.map, truck, hex_at(0, 0), hex_at(1, 0)), MoveCost.PROHIBITED, "wheels can't")
	check_eq(VehicleMoveCost.enter_cost(s.map, truck, hex_at(1, 0), hex_at(2, 0)), 3, "rough: +2 on wheels")
	check_eq(VehicleMoveCost.enter_cost(s.map, tank, hex_at(2, 0), hex_at(3, 0)), MoveCost.PROHIBITED, "no wading for tanks")
	check_eq(VehicleMoveCost.enter_cost(s.map, hover, hex_at(2, 0), hex_at(3, 0)), 1, "hover skims water")
	check_eq(VehicleMoveCost.enter_cost(s.map, tank, hex_at(3, 0), hex_at(4, 0)), MoveCost.PROHIBITED, "from the riverbed up 2: no")
	check_eq(VehicleMoveCost.enter_cost(s.map, hover, hex_at(3, 0), hex_at(4, 0)), 2, "from the surface up a level: 2")
	check_eq(VehicleMoveCost.enter_cost(s.map, tank, hex_at(4, 0), hex_at(5, 0)), MoveCost.PROHIBITED, "two levels up: too steep")


func test_cruise_and_flank() -> void:
	var tank := vehicle("manticore_heavy_tank", 0, hex_at(0, 0), 3)
	var s := _state(["c0", "c0", "c0", "c0", "c0", "c0", "c0", "c0"], [tank])
	var walk := MovePlanner.plan(s, tank, MoveMode.Kind.WALK)
	var run := MovePlanner.plan(s, tank, MoveMode.Kind.RUN)
	check(walk.reachable_hexes().has(hex_at(0, 4)) and not walk.reachable_hexes().has(hex_at(0, 5)), "cruise 4")
	check(run.reachable_hexes().has(hex_at(0, 6)) and not run.reachable_hexes().has(hex_at(0, 7)), "flank 6")
	check(MovePlanner.plan(s, tank, MoveMode.Kind.JUMP).reachable_hexes().size() <= 1, "no jumping")


func test_firing_arcs() -> void:
	var m := vehicle("manticore_heavy_tank", 0, hex_at(2, 2), 0, 1)
	var behind := mech("griffin_grf1n", 1, hex_at(2, 4), 0, 2)
	var s := _state(["c0 c0 c0 c0 c0", "c0 c0 c0 c0 c0", "c0 c0 c0 c0 c0", "c0 c0 c0 c0 c0", "c0 c0 c0 c0 c0"], [m, behind])
	var laser := gun(m, "medium_laser")
	check(not ToHitCalc.weapon(s, m, laser, behind).possible(), "front laser can't fire behind")
	check(ToHitCalc.weapon(s, m, gun(m, "ppc"), behind).possible(), "turret PPC turns round")
	m.vehicle.turret_locked = true
	check(not ToHitCalc.weapon(s, m, gun(m, "ppc"), behind).possible(), "locked turret: forward only")
	m.vehicle.sensor_hits = 1
	var front := mech("griffin_grf1n", 1, hex_at(2, 0), 3, 3)
	s.add_unit(front)
	var th := ToHitCalc.weapon(s, m, laser, front)
	check(th.mods.any(func(d: Dictionary) -> bool: return d["label"] == "sensor damage"), "sensor hit +1")


func test_no_falls_heat_or_charges() -> void:
	var m := vehicle("manticore_heavy_tank", 0, hex_at(0, 0), 3, 1)
	var e := mech("griffin_grf1n", 1, hex_at(0, 1), 0, 2)
	var s := _state(["c0", "c0"], [m, e])
	check(Psr.roll(LoadedDice.new(), func(_t: StringName, _d: Dictionary) -> void: pass, m, "test", 0), "vehicles don't fall")
	m.heat_generated = 30
	HeatPhase.run(s, LoadedDice.new(), func(_t: StringName, _d: Dictionary) -> void: pass)
	check_eq(m.heat, 0, "no heat scale")
	check(PhysicalOptions.for_target(s, m, e).is_empty(), "vehicles make no physical attacks")
	check(not Charge.option(s, e, m, "charge")["to_hit"].possible(), "no charges yet")
	check(not ToHitCalc.is_immobile(m), "a working vehicle isn't immobile")
	m.vehicle.immobile = true
	check(ToHitCalc.is_immobile(m), "a stuck one is")


func test_computer_plays_vehicles() -> void:
	var map := MapLoader.load_file("res://data/maps/river_crossing.json", terrain())
	var s := GameState.new(map)
	var units := [vehicle("manticore_heavy_tank", 0, Vector2i(2, 2), 3, 1),
			vehicle("pegasus_scout_hover_tank", 0, Vector2i(4, 2), 3, 2),
			mech("griffin_grf1n", 0, Vector2i(6, 2), 3, 3),
			vehicle("demolisher_heavy_tank_clan", 1, Vector2i(2, 14), 0, 4),
			vehicle("hetzer_wheeled_assault_gun", 1, Vector2i(4, 14), 0, 5),
			mech("hunchback_hbk4g", 1, Vector2i(6, 14), 0, 6)]
	for u: Unit in units:
		if map.get_tile(u.coord) == null or not VehicleMoveCost.may_enter(u.def.vehicle.motive if u.vehicle else "t", map.get_tile(u.coord)):
			u.coord = _clear_near(map, u.coord)
		s.add_unit(u)
	var gc := GameController.new(s, 7)
	gc.start_turn()
	var steps := 0
	while not s.game_over and s.turn < 8 and steps < 3000:
		if not Bot.act(gc, s.active_side(), BotSkill.Level.VETERAN):
			break
		steps += 1
	check(s.turn >= 3, "played several turns (turn %d)" % s.turn)
	check(gc.history.any(func(e: GameEvent) -> bool: return e.type == GameEvent.UNIT_MOVED and s.unit_by_id(e.data["unit_id"]).vehicle != null and e.data.get("hexes", 0) > 0), "a vehicle moved")


func _clear_near(map: BattleMap, c: Vector2i) -> Vector2i:
	var best := c
	var bd := 99
	for dq in range(-5, 6):
		for dr in range(-5, 6):
			var h := c + Vector2i(dq, dr)
			var t := map.get_tile(h)
			if t != null and t.terrain.id == "clear" and not t.is_water() and Hex.distance(c, h) < bd:
				best = h
				bd = Hex.distance(c, h)
	return best
