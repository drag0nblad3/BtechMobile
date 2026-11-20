extends TestCase
## Force building and deployment.


func test_budget_and_lance_size() -> void:
	var fb := ForceBuilder.new(UnitDb.load_dir(), 150)
	check(fb.add(0, "atlas_as7d"), "100 t fits")
	check(fb.add(0, "hunchback_hbk4g"), "150 t fits")
	check(not fb.add(0, "jenner_jr7d"), "185 t doesn't")
	check(fb.cant_add(0, "jenner_jr7d").begins_with("Over budget"), "explains why")
	check_eq(fb.tons(0), 150)
	fb.remove(0, 0)
	check_eq(fb.tons(0), 50)
	check(not fb.ready_to_fight(), "needs both sides")


func test_build_deploys_both_edges() -> void:
	var fb := ForceBuilder.new(UnitDb.load_dir(), 200)
	fb.add(0, "jenner_jr7d")
	fb.add(0, "catapult_cplt_c1")
	fb.add(1, "atlas_as7d")
	var map := MapLoader.load_file("res://data/maps/test_valley.json", terrain())
	var s := fb.build(map)
	check_eq(s.units.size(), 3)
	check_eq(s.units_of_side(0).size(), 2)
	for u in s.units:
		var row := Hex.to_offset(u.coord).y
		check(row >= map.height - 4 if u.side == 0 else row <= 3, "deployed on own edge")
		check(s.map.get_tile(u.coord).depth < 2, "not in deep water")
	check(s.units[0].coord != s.units[1].coord, "no stacking")


func test_every_map_loads() -> void:
	for path in JsonFile.list_dir("res://data/maps"):
		var m := MapLoader.load_file(path, terrain())
		check(m.width >= 10 and m.height >= 10, path)
