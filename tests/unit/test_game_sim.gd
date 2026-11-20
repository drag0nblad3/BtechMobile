extends TestCase
## Whole games between crude bots: every rule path runs without errors and
## games end.


func test_skirmish_games_finish() -> void:
	var finished := 0
	for seed_value in [11, 22, 33, 44, 55]:
		var s := ScenarioLoader.load_file("res://data/scenarios/test_skirmish.json",
				terrain(), UnitDb.load_dir())
		var gc := GameController.new(s, seed_value)
		SimBot.play(gc)
		if s.game_over:
			finished += 1
		for u in s.units:
			check(u.heat >= 0, "heat never negative")
			for loc in Location.COUNT:
				check(u.structure[loc] >= 0 and u.armor[loc] >= 0, "no negative damage")
	check(finished >= 3, "most games end within 40 turns (%d/5)" % finished)
