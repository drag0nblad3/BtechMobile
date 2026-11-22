extends TestCase
## Standard Missions (book pp. 212-218), complications, the conditions table
## and deployment zones.


func _builder(mission: String) -> ForceBuilder:
	var fb := ForceBuilder.new(designs(), 8000)
	for id in ["hunchback_hbk4g", "griffin_grf1n", "jenner_jr7d"]:
		fb.add(0, id)
		fb.add(1, id)
	fb.mission_id = mission
	return fb


func _map() -> BattleMap:
	return MapLoader.load_file("res://data/maps/rolling_hills.json", terrain())


func test_conditions_table_is_always_legal() -> void:
	for seed_value in 60:
		var c := ConditionsTable.roll(Dice.new(seed_value))
		check(c.problems().is_empty(), "seed %d: %s" % [seed_value, c.names()])
		check(not c.is_clear(), "always at least one condition")


func test_complications_are_supported_ones() -> void:
	for seed_value in 40:
		for table in ["master", "restricted", "annihilation"]:
			for c in Complications.roll(Dice.new(seed_value), table, true):
				check(Complications.SUPPORTED.has(c) and c != "random_duration", c)


func test_every_mission_deploys_legally() -> void:
	for id in StandardMissions.available_ids():
		for seed_value in [1, 2, 3]:
			var fb := _builder(id)
			var s := fb.build(_map(), Dice.new(seed_value))
			check(s.mission.def != null, id)
			var seen := {}
			for u in s.units:
				check(s.map.has(u.coord), "%s: unit on the map" % id)
				check(not seen.has(u.coord), "%s: no stacking" % id)
				seen[u.coord] = true
			for o in s.mission.def.objectives:
				check(s.map.has(o.coord), "%s: objective on the map" % id)


func test_ambush_flanks_and_initiative() -> void:
	var fb := _builder("ambush")
	var s := fb.build(_map(), Dice.new(5))
	var att := s.mission.def.initiative_side
	check(att >= 0, "an attacker")
	for u in s.units_of_side(att):
		check(MapEdges.distance(s.map, u.coord, "west|east") <= 1, "attacker on a flank")
	var gc := GameController.new(s, 9)
	gc.start_turn()
	check_eq(s.initiative_order[-1], att, "attacker wins initiative on turn 1")


func test_focal_point_scores_three() -> void:
	var fb := _builder("focal_point")
	var s := fb.build(_map(), Dice.new(4))
	var o := s.mission.def.objectives[0]
	check_eq(o.radius, 2)
	s.units[0].coord = o.coord
	for u in s.units_of_side(1):
		u.coord = Hex.from_offset(Vector2i(0, 0)) if u == s.units_of_side(1)[0] else u.coord
	check_eq(ObjectiveControl.score(s, s.units[0].side), 3)


func test_bots_play_each_mission() -> void:
	# A few turns each, one 'Mech a side: the computer copes with every
	# mission's setup and goals. Games ending on time are tested in
	# test_missions; Urban Sweep, Objective Raid and Steel Rain get whole games
	# in their own tests.
	for id in StandardMissions.available_ids():
		if id in ["urban_sweep", "objective_raid", "steel_rain"]:
			continue
		var fb := ForceBuilder.new(designs(), 8000)
		fb.add(0, "griffin_grf1n")
		fb.add(1, "griffin_grf1n")
		fb.mission_id = id
		var s := fb.build(_map(), Dice.new(11))
		var gc := GameController.new(s, 3)
		gc.start_turn()
		var guard := 0
		while not s.game_over and s.turn <= 3 and guard < 1000:
			guard += 1
			if not Bot.act(gc, s.active_side()):
				break
		check(s.game_over or s.turn > 3, "%s kept going (turn %d)" % [id, s.turn])
