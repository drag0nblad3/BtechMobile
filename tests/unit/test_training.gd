extends TestCase
## Training campaign: data, unlock order, results, lesson triggers.


func test_campaign_missions_load_and_teach() -> void:
	var c := TrainingCampaign.load_file()
	check(c.missions.size() >= 5, "several training games")
	var db := designs()
	var last_level := BotSkill.Level.NOVICE
	for i in c.missions.size():
		var path := c.scenario_path(i)
		var s := ScenarioLoader.load_file(path, terrain(), db)
		check(s.units.size() >= 2, "%s has units" % path)
		for u in s.units:
			var t := s.map.get_tile(u.coord)
			check(t != null and t.building == null and t.depth == 0, "%s: %s starts on open ground" % [path, u.def.name])
		var tut := Tutorial.from_scenario(path)
		check(tut.lessons.size() >= 5, "%s has lessons" % path)
		var seen_ids := {}
		var goals: Array = c.missions[i].get("practice", [])
		check(goals.size() >= 2, "%s has at least two practice checks" % path)
		for g: Dictionary in goals:
			check(not seen_ids.has(g.get("id", "")), "practice check IDs unique")
			seen_ids[g.get("id", "")] = true
			check(String(g.get("title", "")) != "" and String(g.get("event", "")) != "", "practice check has trigger and title")
		check_eq(tut.lessons[0]["event"], "initiative", "%s opens with a scripted lesson" % path)
		check(String(c.missions[i].get("briefing", "")) != "", "briefing")
		var lvl := int(JsonFile.read(path).get("bot_level", -1))
		check(lvl >= last_level, "%s: the computer never gets easier" % path)
		last_level = lvl


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
	var s := ScenarioLoader.load_file(path, terrain(), designs())
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
		var s := ScenarioLoader.load_file(path, terrain(), designs())
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
	var s := ScenarioLoader.load_file("res://data/scenarios/tutorial.json", terrain(), designs())
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


func test_notebook_collects_played_lessons() -> void:
	var c := TrainingCampaign.load_file()
	check(c.notebook({}).is_empty(), "nothing played yet")
	var notes := c.notebook({c.missions[0]["id"]: {"won": true, "kills": 1}})
	check(notes.size() >= 5, "first mission's lessons")
	for n in notes:
		check_eq(n["mission"], c.missions[0]["title"])
		check(n["title"] != "Lesson one complete", "no end-of-game card")



func test_training_practice_counts_only_real_player_actions() -> void:
	var c := TrainingCampaign.load_file()
	var s := ScenarioLoader.load_file(c.scenario_path(0), terrain(), designs())
	var p := TrainingPractice.from_mission(c.missions[0])
	var own := s.units[0].id
	var enemy := s.units[1].id
	p.observe(GameEvent.new(GameEvent.UNIT_MOVED, {"unit_id": enemy, "hexes": 4}), s, 0)
	p.observe(GameEvent.new(GameEvent.UNIT_MOVED, {"unit_id": own, "hexes": 0}), s, 0)
	check_eq(p.completed_count(), 0, "enemy and zero-length moves do not count")
	p.observe(GameEvent.new(GameEvent.UNIT_MOVED, {"unit_id": own, "hexes": 3}), s, 0)
	p.observe(GameEvent.new(GameEvent.FIRE_DECLARED, {"unit_id": own, "shots": []}), s, 0)
	check_eq(p.completed_count(), 1, "holding fire is not an attack")
	p.observe(GameEvent.new(GameEvent.FIRE_DECLARED, {"unit_id": own, "shots": [{"weapon": 0}]}), s, 0)
	p.observe(GameEvent.new(GameEvent.WEAPON_FIRED, {"attacker_id": own, "no_ammo": true}), s, 0)
	check_eq(p.completed_count(), 2, "an empty ammunition bin is not practice fire")
	p.observe(GameEvent.new(GameEvent.WEAPON_FIRED, {"attacker_id": own, "need": 7, "hit": false}), s, 0)
	check_eq(p.completed_count(), 3, "practice rewards taking a shot, even if it misses")
	check(p.summary().contains("3 of 3"), "practice summary includes completed checks")


func test_practice_tracks_distinct_units_and_heat_control() -> void:
	var c := TrainingCampaign.load_file()
	var s := ScenarioLoader.load_file(c.scenario_path(3), terrain(), designs())
	var p := TrainingPractice.from_mission(c.missions[3])
	var own := s.units[0].id
	var wingman := s.units[1].id
	p.observe(GameEvent.new(GameEvent.FIRE_DECLARED, {"unit_id": own, "shots": [{"weapon": 0}]}), s, 0)
	p.observe(GameEvent.new(GameEvent.FIRE_DECLARED, {"unit_id": own}), s, 0)
	check_eq(p.completed_count(), 0, "one unit cannot satisfy two-unit goal")
	p.observe(GameEvent.new(GameEvent.FIRE_DECLARED, {"unit_id": wingman, "shots": [{"weapon": 0}]}), s, 0)
	check_eq(p.completed_count(), 1, "both friendlies declared")
	var heat := TrainingPractice.from_mission(c.missions[2])
	var warm := ScenarioLoader.load_file(c.scenario_path(2), terrain(), designs())
	var hot_unit := warm.units[0].id
	warm.turn = 1
	heat.observe(GameEvent.new(GameEvent.HEAT, {"unit_id": hot_unit, "heat": 2}), warm, 0)
	check_eq(heat.completed_count(), 0, "cooling check is for a later turn")
	warm.turn = 2
	heat.observe(GameEvent.new(GameEvent.HEAT, {"unit_id": hot_unit, "heat": 12}), warm, 0)
	check_eq(heat.completed_count(), 0, "overheating does not pass cooling goal")
	heat.observe(GameEvent.new(GameEvent.HEAT, {"unit_id": hot_unit, "heat": 7}), warm, 0)
	check_eq(heat.completed_count(), 1, "later controlled heat satisfies check")


func test_practice_restores_from_packed_ledger_at_original_turn() -> void:
	var c := TrainingCampaign.load_file()
	var s := ScenarioLoader.load_file(c.scenario_path(2), terrain(), designs())
	var p := TrainingPractice.from_mission(c.missions[2])
	var own := s.units[0].id
	s.turn = 8
	var frames := [
		{"turn": 1, "events": [
			{"turn": 1, "event": GameEvent.HEAT,
				"data": BattleCodec.pack({"unit_id": own, "heat": 3})}]},
		{"turn": 2, "events": [
			{"turn": 2, "event": GameEvent.WEAPON_FIRED,
				"data": BattleCodec.pack({"attacker_id": own, "need": 7, "hit": false})},
			{"turn": 2, "event": GameEvent.HEAT,
				"data": BattleCodec.pack({"unit_id": own, "heat": 6})}]}]
	p.restore(frames, s, 0)
	check_eq(p.completed_count(), 2, "ledger reconstructs checks without replaying rules")
	p.restore(frames, s, 0)
	check_eq(p.completed_count(), 2, "restoring twice is idempotent")


func test_training_retry_keeps_best_result_and_old_records() -> void:
	var old := {"won": true, "kills": 2}
	var after_loss := TrainingCampaign.merge_result(old, {
			"won": false, "kills": 0, "practice": 2, "practice_total": 3})
	check(after_loss["won"], "old win survives losing retry")
	check_eq(after_loss["attempts"], 2, "legacy record inferred as one attempt")
	check_eq(after_loss["wins"], 1, "old win counted")
	check_eq(after_loss["kills"], 2, "best kills preserved")
	var after_win := TrainingCampaign.merge_result(after_loss, {
			"won": true, "kills": 3, "practice": 1, "practice_total": 3})
	check_eq(after_win["attempts"], 3)
	check_eq(after_win["wins"], 2)
	check_eq(after_win["practice"], 2, "best practice not reduced by retries")
	check_eq(after_win["kills"], 3, "best kills can improve")



func test_damage_practice_requires_player_source_and_real_hit() -> void:
	var c := TrainingCampaign.load_file()
	var s := ScenarioLoader.load_file(c.scenario_path(3), terrain(), designs())
	var p := TrainingPractice.from_mission(c.missions[3])
	var own := s.units[0].id
	var enemy := s.units[2].id
	p.observe(GameEvent.new(GameEvent.DAMAGE, {
			"unit_id": enemy, "source_id": enemy, "amount": 6}), s, 0)
	check_eq(p.completed_count(), 0, "enemy self-damage is not player practice")
	p.observe(GameEvent.new(GameEvent.DAMAGE, {
			"unit_id": enemy, "source_id": own, "amount": 6, "covered": true}), s, 0)
	check_eq(p.completed_count(), 0, "covered hits do not count as actual damage")
	p.observe(GameEvent.new(GameEvent.DAMAGE, {
			"unit_id": enemy, "source_id": own, "amount": 6, "covered": false}), s, 0)
	check_eq(p.completed_count(), 1, "player damage to enemy completes check")
