extends TestCase
## Force building and deployment.


func test_budget_and_lance_size() -> void:
	var db := designs()
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
	var db := designs()
	check_eq(BattleValue.of(db.get_def("atlas_as7d")), 1897, "the official sheet's BV")
	var atlas := BattleValue.breakdown(db.get_def("atlas_as7d"))
	# Our simplified estimate, for designs without a sheet, lands near it.
	check(absi(int(atlas["total"]) - 1897) < 60, "Atlas estimate near its official BV: %d" % atlas["total"])
	check(absi(BattleValue.of(db.get_def("locust_lct1v")) - 432) < 30, "Locust near its published BV")
	check(BattleValue.of(db.get_def("jenner_jr7d")) > BattleValue.of(db.get_def("commando_com2d")),
			"fast hard-hitting Jenner beats the Commando")
	var whm := BattleValue.breakdown(db.get_def("warhammer_whm6r"))
	check(not (whm["halved"] as Array).is_empty(), "Warhammer can't fire everything cool")
	check(BvText.line(db.get_def("warhammer_whm6r"), ExplainLevel.FULL).contains("overheating"), "explained")
	check(BvText.line(db.get_def("warhammer_whm6r"), ExplainLevel.FULL).contains("official record sheet"), "names the source")
	check_eq(BvText.line(db.get_def("warhammer_whm6r"), ExplainLevel.OFF), "")


func test_build_deploys_both_edges() -> void:
	var fb := ForceBuilder.new(designs(), 6000)
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


func test_skill_changes_bv_and_pilots() -> void:
	check_eq(BvSkill.multiplier(4, 5), 1.0, "regular 4/5 is the base")
	check_eq(BvSkill.multiplier(5, 3), 1.08, "the book's example")
	check_eq(BvSkill.adjusted(1000, 3, 4), 1320)
	var fb := ForceBuilder.new(designs(), 8000)
	fb.add(0, "hunchback_hbk4g")
	var base := fb.bv(0)
	check(fb.next_skill(0), "veteran fits the budget")
	check_eq(fb.skills[0], Vector2i(3, 4))
	check_eq(fb.bv(0), roundi(base * 1.32))
	fb.add(1, "locust_lct1v")
	var s := fb.build(open_map(8, 8))
	check_eq(s.units_of_side(0)[0].pilot.gunnery, 3, "deployed with the chosen skill")
	check_eq(s.units_of_side(1)[0].pilot.piloting, 5)
	fb.budget = base
	check(not fb.next_skill(0), "elite would go over a tight budget")
	check_eq(fb.skills[0], Vector2i(3, 4), "skill unchanged")


func test_clan_star_of_five() -> void:
	var fb := ForceBuilder.new(designs(), 8000)
	check_eq(fb.formation(0), "Lance")
	for i in 4:
		check(fb.add(0, "kit_fox_prime"), "Clan 'Mech %d" % (i + 1))
	check_eq(fb.formation(0), "Star")
	check_eq(fb.max_units(0), ForceBuilder.STAR)
	check(fb.cant_add(0, "locust_lct1v").contains("lance of 4"), "an Inner Sphere 'Mech can't be the fifth")
	check(fb.add(0, "adder_prime"), "a fifth Clan 'Mech")
	check_eq(fb.cant_add(0, "adder_prime"), "A star is at most 5 'Mechs")
	fb.add(1, "locust_lct1v")
	check_eq(fb.max_units(1, "kit_fox_prime"), ForceBuilder.MAX_UNITS, "mixed side: lance")
	var s := fb.build(MapLoader.load_file("res://data/maps/river_crossing.json", terrain()))
	check_eq(s.units.filter(func(u: Unit) -> bool: return u.side == 0).size(), 5, "all five deploy")
	var coords := {}
	for u in s.units:
		check(not coords.has(u.coord), "one 'Mech per hex")
		coords[u.coord] = true
