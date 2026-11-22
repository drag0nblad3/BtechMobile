extends TestCase
## Whole games between crude bots: every rule path runs without errors and
## games end.


func test_skirmish_games_finish() -> void:
	var finished := 0
	for seed_value in [11, 22, 33, 44, 55]:
		var s := ScenarioLoader.load_file("res://data/scenarios/test_skirmish.json",
				terrain(), designs())
		var gc := GameController.new(s, seed_value)
		SimBot.play(gc)
		if s.game_over:
			finished += 1
		for u in s.units:
			check(u.heat >= 0, "heat never negative")
			for loc in Location.COUNT:
				check(u.structure[loc] >= 0 and u.armor[loc] >= 0, "no negative damage")
	check(finished >= 3, "most games end within 40 turns (%d/5)" % finished)


func test_every_design_fights() -> void:
	var db := designs()
	var ids: Array = db.by_id.keys()
	ids.sort()
	var map := MapLoader.load_file("res://data/maps/river_crossing.json", terrain())
	for i in range(0, ids.size(), 4):
		var fb := ForceBuilder.new(db, 8000)
		for k in range(i, mini(i + 4, ids.size())):
			fb.add(k % 2, ids[k])
		if not fb.ready_to_fight():
			fb.add(1, "atlas_as7d")
		var gc := GameController.new(fb.build(map), 100 + i)
		SimBot.play(gc, 25)
		check(gc.state.turn >= 1, "played")
