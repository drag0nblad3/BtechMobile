extends TestCase


func test_clear_map_has_three_routes_both_ways() -> void:
	var m := open_map(15, 17)
	var report := MapTactics.assess(m)
	for key in ["north_south", "east_west"]:
		var a: Dictionary = report[key]
		check_eq(a["independent_bands"], 3)
		check_eq(a["shared"], 1.0)
		check(a["slow_cross_mp"] < MapMobility.UNREACHABLE)
	check_eq(MapTactics.penalty(report), 0.0)
	check_eq(report["sight"]["medium"]["visible"], 1.0)


func test_water_barrier_detects_single_safe_crossing() -> void:
	var m := open_map(15, 17)
	for x in m.width:
		var c := Hex.from_offset(Vector2i(x, 8))
		if x != 7:
			m.tiles[c] = MapTile.new(c, terrain().get_type("water"), 0, 3)
	var report := MapTactics.assess(m, false)
	check_eq(report["north_south"]["independent_bands"], 1)
	check(MapTactics.penalty(report) > 0)
	var c := Hex.from_offset(Vector2i(7, 8))
	m.tiles[c] = MapTile.new(c, terrain().get_type("water"), 0, 3)
	report = MapTactics.assess(m, false)
	check_eq(report["north_south"]["cross_mp"], MapMobility.UNREACHABLE)
	check_eq(report["north_south"]["independent_bands"], 0)


func test_slow_walker_cannot_enter_five_mp_hex() -> void:
	var m := open_map(3, 3)
	var a := Hex.from_offset(Vector2i(0, 1))
	var b := Hex.from_offset(Vector2i(1, 1))
	m.tiles[b] = MapTile.new(b, terrain().get_type("heavy_woods"), 1)
	var start: Array[Vector2i] = [a]
	check(MapMobility.costs(m, start, 4).has(b))
	check(not MapMobility.costs(m, start, 3).has(b))


func test_screening_never_worsens_mobility_penalty() -> void:
	var db := terrain()
	for t in MapTheme.load_all():
		for seed_value in [7, 29]:
			var raw := MapGenerator.generate_raw(t, Vector2i.ONE, seed_value)
			var chosen := MapGenerator.generate(t, Vector2i.ONE, seed_value, db)
			var before := MapTactics.penalty(MapTactics.assess(MapLoader.from_dict(raw, db), false))
			var after := MapTactics.penalty(MapTactics.assess(MapLoader.from_dict(chosen, db), false))
			check(after <= before, t.id)
			check_eq(chosen["seed"], seed_value)
			check(chosen.has("layout_seed"))
			if before == 0.0:
				check_eq(chosen["rows"], raw["rows"], "good seed unchanged")


func test_reference_parser_preserves_supported_terrain() -> void:
	var source := 'size 2 2\nhex 0101 1 "woods:2;foliage_elev:2" ""\nhex 0201 0 "water:2" ""\nhex 0102 0 "road:1" ""\nhex 0202 0 "building:2;bldg_elev:3;bldg_cf:40" ""\nend'
	var board := MapReferenceBoard.parse(source, "fixture")
	check(not board.is_empty())
	if board.is_empty():
		return
	var m := MapLoader.from_dict(board, terrain())
	check_eq(m.get_tile(Hex.from_label("0101")).terrain.id, "heavy_woods")
	check_eq(m.get_tile(Hex.from_label("0201")).depth, 2)
	check_eq(m.get_tile(Hex.from_label("0202")).building.height, 3)
	check(MapReferenceBoard.parse(source.replace("woods:2", "unknown:2"), "invalid").is_empty())
