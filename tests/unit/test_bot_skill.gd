extends TestCase
## Computer skill levels: what each level does differently.


func _hot_shot(level: int) -> int:
	BotSkill.use(level)
	var s := GameState.new(open_map(10, 4))
	var r := mech("rifleman_rfl3n", 0, hex_at(1, 2), 2, 1)
	s.add_unit(r)
	s.add_unit(mech("atlas_as7d", 1, hex_at(5, 2), 5, 2))
	var heat := 0
	for sh in BotFire.plan(s, r)["shots"]:
		heat += r.weapons[sh["weapon"]].def.heat
	BotSkill.use(BotSkill.Level.VETERAN)
	return heat


func test_novice_overheats_veteran_doesnt() -> void:
	check(_hot_shot(BotSkill.Level.NOVICE) > _hot_shot(BotSkill.Level.VETERAN), "novice fires hotter")


func test_novice_shoots_only_the_nearest_enemy() -> void:
	var s := GameState.new(open_map(10, 6))
	var a := mech("griffin_grf1n", 0, hex_at(1, 2), 2, 1)
	var near := mech("atlas_as7d", 1, hex_at(3, 2), 5, 2)   # tough, close
	var far := mech("locust_lct1v", 1, hex_at(6, 2), 5, 3)  # fragile, farther
	for x in [a, near, far]:
		s.add_unit(x)
	for loc in Location.COUNT:
		far.armor[loc] = 0
	BotSkill.use(BotSkill.Level.NOVICE)
	var plan := BotFire.plan(s, a)
	BotSkill.use(BotSkill.Level.VETERAN)
	for sh in plan["shots"]:
		check_eq(sh["target_id"], near.id, "novice picks the nearest")


func test_jitter_is_deterministic_and_off_for_veterans() -> void:
	var u := mech("griffin_grf1n", 0, Vector2i(0, 0))
	BotSkill.use(BotSkill.Level.NOVICE)
	var j1 := BotSkill.jitter(u, 2, Vector3i(1, 2, 3))
	check_eq(BotSkill.jitter(u, 2, Vector3i(1, 2, 3)), j1, "same input, same jitter")
	check(absf(j1) <= 3.0, "bounded")
	BotSkill.use(BotSkill.Level.VETERAN)
	check_eq(BotSkill.jitter(u, 2, Vector3i(1, 2, 3)), 0.0)


func test_only_elite_values_rear_shots() -> void:
	BotSkill.use(BotSkill.Level.ELITE)
	check(BotSkill.rear_bonus() > 0.0, "elite")
	BotSkill.use(BotSkill.Level.REGULAR)
	check_eq(BotSkill.rear_bonus(), 0.0)
	check(BotSkill.basic_tricks() and not BotSkill.advanced_tricks(), "regular: basic tricks only")
	BotSkill.use(BotSkill.Level.VETERAN)
	var s := GameState.new(open_map(8, 8))
	var e := mech("griffin_grf1n", 1, hex_at(3, 3), 0, 2)  # facing north
	var behind := mech("jenner_jr7d", 0, hex_at(3, 6), 0, 1)
	s.add_unit(e)
	s.add_unit(behind)
	check_eq(BotMove._rear_of(s, behind), 1, "south of a north-facing 'Mech is its rear")


func test_every_level_plays_a_game() -> void:
	for level in BotSkill.NAMES.size():
		var s := ScenarioLoader.load_file("res://data/scenarios/test_skirmish.json", terrain(), designs())
		var gc := GameController.new(s, 40 + level)
		gc.start_turn()
		var guard := 0
		while not s.game_over and s.turn <= 2 and guard < 2000:
			guard += 1
			if not Bot.act(gc, s.active_side(), level):
				break
		check(s.turn > 2, "%s played past turn 2" % BotSkill.name_of(level))
	BotSkill.use(BotSkill.Level.VETERAN)
