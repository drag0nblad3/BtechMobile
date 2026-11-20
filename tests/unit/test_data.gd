extends TestCase
## Sanity checks on shipped data files.


func test_terrain_loads() -> void:
	var db := terrain()
	check(db.by_token.has("c"), "clear")
	check(db.by_token.has("w"), "water")


func test_units_load() -> void:
	var db := UnitDb.load_dir()
	check(db.by_id.size() >= 4, "unit count")
	check_eq(db.get_def("atlas_as7d").walk_mp, 3)


func test_scenario_loads() -> void:
	var s := ScenarioLoader.load_file("res://data/scenarios/test_skirmish.json",
			terrain(), UnitDb.load_dir())
	check_eq(s.map.width, 15)
	check_eq(s.map.height, 17)
	check_eq(s.units.size(), 4)
	for u in s.units:
		check(s.map.has(u.coord), "unit %d on map" % u.id)


func test_water_token() -> void:
	var t := MapLoader.parse_token("w0d2", Vector2i.ZERO, terrain())
	check_eq(t.depth, 2)
	check_eq(t.floor_level(), -2)
	check(t.is_water())
