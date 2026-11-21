extends TestCase
## Training campaign: data, unlock order, results, lesson triggers.


func test_campaign_missions_load_and_teach() -> void:
	var c := TrainingCampaign.load_file()
	check(c.missions.size() >= 5, "several training games")
	var db := UnitDb.load_dir()
	for i in c.missions.size():
		var path := c.scenario_path(i)
		var s := ScenarioLoader.load_file(path, terrain(), db)
		check(s.units.size() >= 2, "%s has units" % path)
		for u in s.units:
			var t := s.map.get_tile(u.coord)
			check(t != null and t.building == null and t.depth == 0, "%s: %s starts on open ground" % [path, u.def.name])
		var tut := Tutorial.from_scenario(path)
		check(tut.lessons.size() >= 5, "%s has lessons" % path)
		check_eq(tut.lessons[0]["event"], "initiative", "%s opens with a scripted lesson" % path)
		check(String(c.missions[i].get("briefing", "")) != "", "briefing")


func test_missions_unlock_in_order() -> void:
	var c := TrainingCampaign.load_file()
	var p := {}
	check(c.unlocked(0, p), "first open")
	check(not c.unlocked(1, p), "second locked")
	check_eq(c.next_index(p), 0)
	p[c.missions[0]["id"]] = {"won": false, "kills": 0}
	check(c.unlocked(1, p), "a loss still moves on")
	check(not c.unlocked(2, p), "third locked")
	check_eq(c.next_index(p), 1)
	check(not c.finished(p), "not finished")


func test_result_and_debrief() -> void:
	var path := "res://data/scenarios/tutorial.json"
	var s := ScenarioLoader.load_file(path, terrain(), UnitDb.load_dir())
	s.units[1].destroyed = true
	var r := TrainingCampaign.result(s, 0, 0)
	check(r["won"], "won")
	check_eq(r["kills"], 1)
	var c := TrainingCampaign.load_file()
	var text := c.debrief(0, true, {c.missions[0]["id"]: r})
	check(text.contains("1 of %d missions won" % c.missions.size()), text)
	check(text.contains(c.missions[1]["title"]), "points at the next mission")


func test_each_mission_plays_and_shows_its_opening() -> void:
	var c := TrainingCampaign.load_file()
	for i in c.missions.size():
		var path := c.scenario_path(i)
		var s := ScenarioLoader.load_file(path, terrain(), UnitDb.load_dir())
		var tut := Tutorial.from_scenario(path)
		var gc := GameController.new(s, 3 + i)
		var titles: Array[String] = []
		gc.event.connect(func(e: GameEvent) -> void:
			for l in tut.on_event(e, gc.state):
				titles.append(l["title"]))
		SimBot.play(gc, 12)
		check(titles.size() >= 3, "%s lessons shown: %s" % [path, titles])
		check_eq(titles[0], tut.lessons[0]["title"], path)


func test_lesson_kind_and_min_turn_filters() -> void:
	var s := ScenarioLoader.load_file("res://data/scenarios/tutorial.json", terrain(), UnitDb.load_dir())
	var t := Tutorial.new()
	t.lessons = [{"event": "physical", "kind": "kick", "unit_side": 0, "title": "k"},
			{"event": "turn_started", "min_turn": 3, "title": "late"}]
	var punch := GameEvent.new(GameEvent.PHYSICAL, {"attacker_id": s.units[0].id, "kind": "punch"})
	check(t.on_event(punch, s).is_empty(), "wrong kind")
	var kick := GameEvent.new(GameEvent.PHYSICAL, {"attacker_id": s.units[0].id, "kind": "kick"})
	check_eq(t.on_event(kick, s).size(), 1, "kick by side 0 via attacker_id")
	s.turn = 2
	check(t.on_event(GameEvent.new(GameEvent.TURN_STARTED, {"turn": 2}), s).is_empty(), "too early")
	s.turn = 3
	check_eq(t.on_event(GameEvent.new(GameEvent.TURN_STARTED, {"turn": 3}), s).size(), 1)
