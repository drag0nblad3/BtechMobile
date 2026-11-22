extends TestCase
## VTOL flight levels (book pp. 142-144).


func _state(rows: Array, units: Array) -> GameState:
	var s := GameState.new(make_map(rows))
	for u: Unit in units:
		s.add_unit(u)
	return s


func test_min_levels() -> void:
	var m := make_map(["c0 H0 c2 w0d2"])
	check_eq(VtolFlight.min_level(m.get_tile(hex_at(0, 0))), 1, "clear ground: level 1")
	check_eq(VtolFlight.min_level(m.get_tile(hex_at(1, 0))), 3, "woods are two levels high")
	check_eq(VtolFlight.min_level(m.get_tile(hex_at(2, 0))), 3, "level 2 hill")
	check_eq(VtolFlight.min_level(m.get_tile(hex_at(3, 0))), 1, "over the water surface")


func test_climbing_costs_mp() -> void:
	var v := asset("test_vtol", 0, hex_at(0, 0), 3)
	var s := _state(["c0", "H0", "c0", "c1"], [v])
	var opts := MovePlanner.plan(s, v, MoveMode.Kind.RUN)
	check_eq(opts.cost.get(Vector3i(0, 1, 3), -1), 3, "1 for the hex + 2 to clear the woods")
	check_eq(opts.cost.get(Vector3i(0, 2, 3), -1), 6, "and 2 back down")
	check_eq(opts.cost.get(Vector3i(0, 3, 3), -1), 8, "up a level 1 hill: 1 + 1")


func test_level_after_move_sets_los() -> void:
	var v := asset("test_vtol", 0, hex_at(0, 0), 3)
	var s := _state(["c0", "H0", "c0"], [v])
	check_eq(LineOfSight.los_level(s.map, v), 2, "base level 1 + flight level 1")
	check(AssetMove.run(s, func(_t: StringName, _d: Dictionary) -> void: pass, v, Vector3i(0, 1, 3), MoveMode.Kind.RUN), "flies over the woods")
	check_eq(v.asset.altitude, 3, "above the treetops")
	check_eq(LineOfSight.los_level(s.map, v), 4, "sees from level 4")
