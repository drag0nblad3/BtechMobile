extends TestCase
## Procedural battlefields (MapGenerator): sizes, repeatable seeds, terrain
## shares per theme, and maps that play (walkable steps, safe deployment).


func _theme(id: String) -> MapTheme:
	return MapTheme.find(id)


func test_sizes_are_whole_mapsheets() -> void:
	var t := _theme("grassland")
	for sheets in MapGenerator.SIZES:
		var m := MapGenerator.build(t, sheets, 5, terrain())
		check_eq(Vector2i(m.width, m.height), Vector2i(15 * sheets.x, 17 * sheets.y), str(sheets))
		check_eq(m.tiles.size(), m.width * m.height)


func test_same_seed_same_map() -> void:
	var t := _theme("river_valley")
	var a := MapGenerator.generate(t, Vector2i(2, 1), 42)
	var b := MapGenerator.generate(t, Vector2i(2, 1), 42)
	var c := MapGenerator.generate(t, Vector2i(2, 1), 43)
	check_eq(a, b, "same seed")
	check(a["rows"] != c["rows"], "another seed gives another map")


func test_every_theme_builds_a_playable_map() -> void:
	for t in MapTheme.load_all():
		for s in [1, 2, 3]:
			var m := MapGenerator.build(t, Vector2i(2, 1), s, terrain())
			var why := _problem(m)
			check(why == "", "%s seed %d: %s" % [t.id, s, why])


func test_shares_follow_the_theme() -> void:
	for t in MapTheme.load_all():
		var st := MapStats.new(MapGenerator.build(t, Vector2i(2, 1), 11, terrain()))
		check(absf(st.woods_share() - t.woods) < 0.03, "%s woods %.2f" % [t.id, st.woods_share()])
		check(absf(st.share("rough") - t.rough) < 0.03, "%s rough %.2f" % [t.id, st.share("rough")])
		check(st.share("water") >= t.water - 0.01, "%s water %.2f" % [t.id, st.share("water")])


func test_themes_differ() -> void:
	var city := MapStats.new(MapGenerator.build(_theme("urban"), Vector2i(2, 1), 3, terrain()))
	var hills := MapStats.new(MapGenerator.build(_theme("hills"), Vector2i(2, 1), 3, terrain()))
	var bad := MapStats.new(MapGenerator.build(_theme("badlands"), Vector2i(2, 1), 3, terrain()))
	var valley := MapStats.new(MapGenerator.build(_theme("river_valley"), Vector2i(2, 1), 3, terrain()))
	check(city.buildings > 100, "a city has blocks of buildings (%d)" % city.buildings)
	check(city.share("pavement") > 0.2, "and streets")
	check(hills.top_level >= 4 and hills.raised > city.raised * 2, "hills are hilly")
	check(bad.share("rough") > bad.woods_share() * 4, "badlands are rough, not wooded")
	check(valley.share("water") > 0.04, "a river valley has a river")


func test_forces_deploy_on_a_generated_map() -> void:
	var fb := ForceBuilder.new(designs())
	fb.budget = 100000
	for side in 2:
		for k in 4:
			fb.add(side, "atlas_as7d" if k % 2 == 0 else "locust_lct1v")
	var m := MapGenerator.build(_theme("lakes"), Vector2i(2, 1), 9, terrain())
	var state := fb.build(m)
	check_eq(state.units.size(), 8)
	for u: Unit in state.units:
		var tile := m.get_tile(u.coord)
		check(tile.depth < 2 and tile.building == null, "unit %d on %s" % [u.id, Hex.label(u.coord)])


func test_generated_map_round_trips_as_json() -> void:
	var d := MapGenerator.generate(_theme("urban"), Vector2i(1, 1), 8)
	var copy: Variant = JSON.parse_string(JSON.stringify(d))
	var m := MapLoader.from_dict(copy, terrain())
	check_eq(MapStats.new(m).buildings, d["buildings"].size())


func test_roads_cross_rivers_on_bridges() -> void:
	var found := 0
	for s in [1, 2, 3, 4, 5]:
		var m := MapGenerator.build(_theme("river_valley"), Vector2i(2, 1), s, terrain())
		for t: MapTile in m.tiles.values():
			if t.bridge == null:
				continue
			found += 1
			check(t.terrain.is_water and t.bridge.level >= t.level, "bridge over water at %s" % Hex.label(t.coord))
			for f in 6:
				var n := m.get_tile(Hex.neighbor(t.coord, f))
				if n != null and n.terrain.id == "pavement":
					check(MoveCost.enter_cost(m, n.coord, t.coord, MoveMode.Kind.WALK) == 1 + maxi(0, absi(t.bridge.level - n.level) - 1),
							"road onto the deck at %s" % Hex.label(t.coord))
		var paved_water := m.tiles.values().filter(func(t: MapTile) -> bool:
			return t.terrain.id == "pavement" and t.depth > 0)
		check(paved_water.is_empty(), "no more paved fords")
	check(found >= 5, "river valleys get bridges (%d)" % found)


## "" if the map is fine, else what is wrong with it.
func _problem(m: BattleMap) -> String:
	for c: Vector2i in m.coords():
		var t := m.get_tile(c)
		if t.building != null:
			if t.terrain.is_water:
				return "building in water at %s" % Hex.label(c)
			var row := Hex.to_offset(c).y
			if row < 2 or row >= m.height - 2:
				return "building on a home edge at %s" % Hex.label(c)
		if t.terrain.is_water:
			continue
		for f in 6:
			var n := m.get_tile(Hex.neighbor(c, f))
			if n != null and not n.terrain.is_water and t.level - n.level > GenElevation.MAX_STEP:
				return "cliff at %s" % Hex.label(c)
	return ""
