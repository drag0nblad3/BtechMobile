extends TestCase
## Force building and deployment.


func test_budget_and_lance_size() -> void:
	var db := UnitDb.load_dir()
	var fb := ForceBuilder.new(db, 3000)
	check(fb.add(0, "atlas_as7d"), "Atlas fits")
	check(fb.add(0, "hunchback_hbk4g"), "plus a Hunchback fits")
	check(not fb.add(0, "griffin_grf1n"), "a Griffin is over 3000 BV")
	check(fb.cant_add(0, "griffin_grf1n").begins_with("Over budget"), "explains why")
	check_eq(fb.bv(0), BattleValue.of(db.get_def("atlas_as7d")) + BattleValue.of(db.get_def("hunchback_hbk4g")))
	check_eq(fb.tons(0), 150)
	fb.remove(0, 0)
	check_eq(fb.tons(0), 50)
	check(not fb.ready_to_fight(), "needs both sides")


func test_battle_value_ordering() -> void:
	var db := UnitDb.load_dir()
	var atlas := BattleValue.breakdown(db.get_def("atlas_as7d"))
	# Published BV 2 values are about 1897 (Atlas) and 432 (Locust); ours is simplified.
	check(absi(int(atlas["total"]) - 1897) < 60, "Atlas near its published BV: %d" % atlas["total"])
	check(absi(BattleValue.of(db.get_def("locust_lct1v")) - 432) < 30, "Locust near its published BV")
	check(BattleValue.of(db.get_def("jenner_jr7d")) > BattleValue.of(db.get_def("commando_com2d")),
			"fast hard-hitting Jenner beats the Commando")
	var whm := BattleValue.breakdown(db.get_def("warhammer_whm6r"))
	check(not (whm["halved"] as Array).is_empty(), "Warhammer can't fire everything cool")
	check(BvText.line(db.get_def("warhammer_whm6r"), ExplainLevel.FULL).contains("half"), "explained")
	check_eq(BvText.line(db.get_def("warhammer_whm6r"), ExplainLevel.OFF), "")


func test_balance_text() -> void:
	var fb := ForceBuilder.new(UnitDb.load_dir(), 8000)
	check_eq(fb.balance_text(), "")
	fb.add(0, "griffin_grf1n")
	fb.add(1, "griffin_grf1n")
	check(fb.balance_text().begins_with("Even fight"), fb.balance_text())
	fb.add(1, "atlas_as7d")
	check(fb.balance_text().contains("much stronger"), fb.balance_text())


func test_build_deploys_both_edges() -> void:
	var fb := ForceBuilder.new(UnitDb.load_dir(), 6000)
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
