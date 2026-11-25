extends TestCase


func test_empty_volley_is_read_only() -> void:
	var state := GameState.new(open_map(8, 8))
	var u := mech("atlas_as7d", 0, hex_at(3, 4))
	state.add_unit(u)
	var before := BattleCodec.pack(state)
	var f := VolleyForecast.estimate(state, u, [])
	check_eq(f["damage"], 0.0)
	check_eq(f["any_hit"], 0.0)
	check_eq(f["ammo"], 0)
	check_eq(BattleCodec.pack(state), before, "forecast does not mutate state")


func test_overlay_leaves_position_unchanged() -> void:
	var state := GameState.new(open_map(8, 8))
	var u := mech("wolverine_wvr6r", 0, hex_at(3, 4))
	state.add_unit(u)
	var opts := MovePlanner.plan(state, u, MoveMode.Kind.WALK)
	var before := BattleCodec.pack(state)
	for mode in range(1, TacticalIntel.MODES.size()):
		check_eq(TacticalIntel.colors(state, u, opts, MoveMode.Kind.WALK, mode).size(), opts.reachable_hexes().size())
	check_eq(BattleCodec.pack(state), before, "overlay does not persist mutations")
