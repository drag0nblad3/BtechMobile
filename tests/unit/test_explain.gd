extends TestCase
## Explanation text exists at each level and advice reflects the numbers.


func _skirmish() -> GameController:
	var s := ScenarioLoader.load_file("res://data/scenarios/test_skirmish.json",
			terrain(), UnitDb.load_dir())
	return GameController.new(s, 22)


func test_every_event_describes_at_every_level() -> void:
	var gc := _skirmish()
	SimBot.play(gc, 6)
	var types := {}
	for e in gc.history:
		for level in [ExplainLevel.FULL, ExplainLevel.LIGHT, ExplainLevel.OFF]:
			var t := Explainer.text(e, gc.state, level)
			check(t is String, "text")
		types[e.type] = true
		check(Explainer.text(e, gc.state, ExplainLevel.FULL).length()
				>= Explainer.text(e, gc.state, ExplainLevel.OFF).length(), "full >= off")
	check(types.has(GameEvent.WEAPON_FIRED), "a game fires weapons")


func test_full_explains_modifiers() -> void:
	var th := ToHit.new()
	th.add("Gunnery", 4, "base")
	th.add("medium range", 2, "because 5 hexes")
	var full := ModsText.lines(th.mods, ExplainLevel.FULL)
	check(full.contains("because 5 hexes"), full)
	var light := ModsText.lines(th.mods, ExplainLevel.LIGHT)
	check(light.contains("= 6") and not light.contains("because"), light)
	check_eq(ModsText.lines(th.mods, ExplainLevel.OFF), "")


func test_volley_heat_advice() -> void:
	var s := GameState.new(open_map(8, 3))
	var a := mech("jenner_jr7d", 0, hex_at(0, 1), 2, 1)
	var b := mech("hunchback_hbk4g", 1, hex_at(2, 1), 5, 2)
	s.add_unit(a)
	s.add_unit(b)
	a.heat_generated = 2  # ran
	var shots := []
	for i in a.weapons.size():
		shots.append({"weapon": i, "target_id": b.id})
	# 15 weapon heat + 2 running - 10 sinks = 7
	check_eq(Advisor.projected_heat(a, FireOptions.volley_heat(a, [0, 1, 2, 3, 4])), 7)
	var tip := Advisor.volley(s, a, shots, ExplainLevel.FULL)
	check(tip.contains("Heat after this turn: 7"), tip)
	check(tip.contains("Holding"), "suggests holding a weapon: " + tip)
	check_eq(Advisor.volley(s, a, shots, ExplainLevel.OFF), "")


func test_target_ranking_and_physical() -> void:
	var s := GameState.new(open_map(8, 4))
	var a := mech("atlas_as7d", 0, hex_at(2, 2), 0, 1)
	var near := mech("jenner_jr7d", 1, Hex.neighbor(hex_at(2, 2), 0), 3, 2)
	var far := mech("hunchback_hbk4g", 1, hex_at(7, 0), 3, 3)
	s.add_unit(a)
	s.add_unit(near)
	s.add_unit(far)
	var tip := Advisor.targets(s, a, ExplainLevel.FULL)
	check(tip.begins_with("Best target: Blue Jenner"), tip)
	var ph := Advisor.physical(s, a, near, ExplainLevel.FULL)
	check(ph.contains("kick"), ph)


func test_move_advice_compares_run_and_walk() -> void:
	var s := GameState.new(open_map(10, 3))
	var u := mech("hunchback_hbk4g", 0, hex_at(0, 1), 2, 1)
	s.add_unit(u)
	var opts := MovePlanner.plan(s, u, MoveMode.Kind.RUN)
	# Run 2 hexes: no better than walking.
	var two := MoveOptions.key(Hex.neighbor(Hex.neighbor(u.coord, 2), 2), 2)
	var tip := Advisor.move(s, u, MoveMode.Kind.RUN, two, opts, ExplainLevel.FULL)
	check(tip.contains("walk instead"), tip)


func test_reasons_not_repeated() -> void:
	var th := ToHit.new()
	th.add("Gunnery", 4, "base")
	th.add("target moved 5 hexes", 2, "fast")
	var seen := {}
	check(ModsText.lines(th.mods, ExplainLevel.FULL, seen).contains("fast"), "first time")
	var th2 := ToHit.new()
	th2.add("target moved 7 hexes", 3, "fast")
	check(not ModsText.lines(th2.mods, ExplainLevel.FULL, seen).contains("fast"), "second time")


func test_tutorial_lessons_fire_once_in_order() -> void:
	var path := "res://data/scenarios/tutorial.json"
	var s := ScenarioLoader.load_file(path, terrain(), UnitDb.load_dir())
	var tut := Tutorial.from_scenario(path)
	check(tut.lessons.size() >= 8, "has lessons")
	var gc := GameController.new(s, 9)
	var titles: Array[String] = []
	gc.event.connect(func(e: GameEvent) -> void:
		for l in tut.on_event(e, gc.state):
			titles.append(l["title"]))
	SimBot.play(gc, 30)
	check(titles.size() >= 6, "most lessons shown: %s" % [titles])
	check_eq(titles[0], "Your first battle")
	check_eq(titles[1], "Moving")
	var unique := {}
	for t in titles:
		unique[t] = true
	check_eq(unique.size(), titles.size(), "each lesson once")
	if gc.state.game_over:
		check_eq(titles[titles.size() - 1], "Lesson one complete")
