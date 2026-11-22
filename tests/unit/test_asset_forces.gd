extends TestCase
## Assets in the force builder and in whole games played by the computer.


func _db() -> UnitDb:
	var db := UnitDb.load_dir()
	db.add_assets(ASSET_FIXTURES)
	return db


func test_assets_kept_out_of_mech_catalog() -> void:
	var db := UnitDb.load_dir()
	check(db.get_def("savior_repair_vehicle") != null, "found by id")
	check(not db.by_id.has("savior_repair_vehicle"), "not in the 'Mech list")
	check(db.sorted_assets().size() >= 1, "listed separately")


func test_force_builder_buys_assets_with_bv() -> void:
	var fb := ForceBuilder.new(_db(), 8000)
	check(fb.add(0, "atlas_as7d"), "a 'Mech")
	var before := fb.bv(0)
	check(fb.add(0, "savior_repair_vehicle"), "an Asset")
	check_eq(fb.bv(0) - before, 260, "20 BV per BSP, no pilot skill change")
	for i in 3:
		check(fb.add(0, "test_foot"), "more support")
	check(fb.cant_add(0, "test_foot") != "", "at most four Assets")
	check_eq(fb.formation(0), "Lance", "Assets don't change the lance")
	check(fb.cant_add(0, "griffin_grf1n") == "", "'Mech slots still open")


func test_built_assets_keep_card_skill() -> void:
	var fb := ForceBuilder.new(_db(), 8000)
	fb.add(0, "atlas_as7d")
	fb.add(0, "test_tank")
	fb.add(1, "griffin_grf1n")
	var map := MapLoader.load_file("res://data/maps/river_crossing.json", terrain())
	var s := fb.build(map)
	var tank: Unit = s.units.filter(func(u: Unit) -> bool: return u.asset != null)[0]
	check_eq(tank.pilot.gunnery, 5, "Skill from the card")
	check(AssetMoveCost.may_enter(tank.asset.card, s.map.get_tile(tank.coord)), "deployed somewhere it can be")


func test_bots_play_with_assets() -> void:
	var db := _db()
	var map := MapLoader.load_file("res://data/maps/river_crossing.json", terrain())
	for seed_value in [3, 4]:
		var fb := ForceBuilder.new(db, 8000)
		fb.add(0, "griffin_grf1n")
		for id in ["test_tank", "test_foot", "test_hover"]:
			fb.add(0, id)
		fb.add(1, "hunchback_hbk4g")
		for id in ["test_wheeled", "test_jump", "savior_repair_vehicle"]:
			fb.add(1, id)
		var gc := GameController.new(fb.build(map), seed_value)
		var turns := 0
		while not gc.state.game_over and gc.state.turn < 12:
			if gc.state.turn == 0 or not Bot.act(gc, gc.state.active_side(), BotSkill.Level.VETERAN):
				if gc.state.turn == 0:
					gc.start_turn()
				else:
					break
			turns += 1
			if turns > 2000:
				break
		check(gc.state.turn >= 2, "computer played turns with Assets (turn %d)" % gc.state.turn)
		var moved := gc.history.any(func(e: GameEvent) -> bool:
				return e.type == GameEvent.UNIT_MOVED and e.data.get("asset", false) and e.data["hexes"] > 0)
		check(moved, "an Asset moved")
