extends TestCase
## Buildings: entering, cover from walls, collapse, line of sight.

var events: Array[GameEvent] = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append(GameEvent.new(t, d))


## 5 x 6 open map with one building at column 2, row 2 (label 0303).
func _state(type: String, height: int = 2) -> GameState:
	var rows := []
	for r in 6:
		rows.append("c0 c0 c0 c0 c0")
	var m := MapLoader.from_dict({"rows": rows,
			"buildings": [{"hex": "0303", "type": type, "height": height}]}, terrain())
	events.clear()
	return GameState.new(m)


func test_loads_and_costs_mp() -> void:
	var s := _state("medium")
	var tile := s.map.get_tile(hex_at(2, 2))
	check(tile.building != null, "building placed from its label")
	check_eq(tile.building.type.threshold, 10)
	check_eq(tile.building.type.destroy_tn, 9)
	check_eq(MoveCost.enter_cost(s.map, hex_at(2, 3), hex_at(2, 2), MoveMode.Kind.WALK), 2, "1 + 1 for any building")
	var city := MapLoader.load_file("res://data/maps/city_outskirts.json", terrain())
	var n := 0
	for t: MapTile in city.tiles.values():
		n += 1 if t.building != null else 0
	check(n >= 6, "city map has buildings")


func test_blocks_line_of_sight() -> void:
	var s := _state("heavy", 2)
	var a := mech("griffin_grf1n", 0, hex_at(2, 4), 0, 1)
	var b := mech("griffin_grf1n", 1, hex_at(2, 0), 3, 2)
	s.add_unit(a)
	s.add_unit(b)
	check(LineOfSight.check(s.map, a, b)["blocked"], "two-level building blocks")
	s.map.get_tile(hex_at(2, 2)).building.height = 1
	check(not LineOfSight.check(s.map, a, b)["blocked"], "one level does not")


func test_too_light_to_force_entry() -> void:
	var s := _state("heavy")
	var light := mech("jenner_jr7d", 0, hex_at(2, 3), 0, 1)
	s.add_unit(light)
	var into := MoveOptions.key(hex_at(2, 2), 0)
	check(not MovePlanner.plan(s, light, MoveMode.Kind.WALK).can_reach(into), "a light 'Mech can't push into a heavy building")
	light.coord = hex_at(0, 0)
	var big := mech("warhammer_whm6r", 0, hex_at(2, 3), 0, 2)
	s.add_unit(big)
	check(MovePlanner.plan(s, big, MoveMode.Kind.WALK).can_reach(into), "a heavy one can")


func test_failed_entry_roll_risks_collapse() -> void:
	var s := _state("medium", 3)
	var u := mech("griffin_grf1n", 0, hex_at(2, 2), 0, 1)
	s.add_unit(u)
	var dice := LoadedDice.new()
	dice.queue_2d6(2)   # entry roll fails (needs 6)
	dice.queue_2d6(9)   # destroy check passes: it comes down
	for i in 2:
		dice.queue_2d6(7)   # collapse damage: 5 x 1 level above = 5, then 6s
	BuildingRules.enter(s, dice, _emit, u, hex_at(2, 2))
	var tile := s.map.get_tile(hex_at(2, 2))
	check(tile.building == null and tile.terrain.id == "rubble", "now rubble")
	check(not u.prone, "a failed entry doesn't knock you down")
	var dmg := 0
	for e in events:
		if e.type == GameEvent.DAMAGE:
			dmg += int(e.data["amount"])
	check_eq(dmg, 5, "half of threshold 10, one level above a standing 'Mech")
	check(Explainer.text(events.filter(func(e: GameEvent) -> bool: return e.type == GameEvent.BUILDING)[-1], s, ExplainLevel.FULL).contains("buried"), "explained")


func test_walking_flattens_civilian() -> void:
	var s := _state("civilian", 2)
	var u := mech("locust_lct1v", 0, hex_at(2, 2), 0, 1)
	s.add_unit(u)
	BuildingRules.enter(s, LoadedDice.new(), _emit, u, hex_at(2, 2))
	check(s.map.get_tile(hex_at(2, 2)).building == null, "flattened, no roll")
	check(events.filter(func(e: GameEvent) -> bool: return e.type == GameEvent.PSR).is_empty())


func test_inside_and_half_inside() -> void:
	var s := _state("medium", 2)
	var a := mech("griffin_grf1n", 0, hex_at(2, 5), 0, 1)
	var t := mech("griffin_grf1n", 1, hex_at(2, 2), 3, 2)
	s.add_unit(a)
	s.add_unit(t)
	check_eq(BuildingRules.inside_mod(s.map, t), 2, "two levels hide a standing 'Mech")
	s.map.get_tile(hex_at(2, 2)).building.height = 1
	check_eq(BuildingRules.inside_mod(s.map, t), 0, "one level doesn't")
	check(BuildingRules.half_inside(s.map, t), "but gives partial cover")
	var hl := {"loc": Location.LL, "rear": false, "tac": false}
	var before := t.armor[Location.LL]
	WeaponFire.hit_with(s, LoadedDice.new(), _emit, t, FiringArc.FRONT, 10, a.id, "AC/10", hl)
	check_eq(t.armor[Location.LL], before, "the walls took the leg hit")
	check_eq(int(s.building_hits[a.id][hex_at(2, 2)]), 10, "and count toward a Destroy Check")
	t.prone = true
	check_eq(BuildingRules.inside_mod(s.map, t), 2, "a prone 'Mech fits inside one level")


func test_city_battle_runs() -> void:
	var fb := ForceBuilder.new(UnitDb.load_dir(), 8000)
	for id in ["atlas_as7d", "jenner_jr7d", "griffin_grf1n"]:
		fb.add(0, id)
	for id in ["warhammer_whm6r", "commando_com2d", "hunchback_hbk4g"]:
		fb.add(1, id)
	var building_events := 0
	for seed_value in range(3, 13):  # games are short and chaotic; look across several
		var map := MapLoader.load_file("res://data/maps/city_outskirts.json", terrain())
		var gc := GameController.new(fb.build(map), seed_value)
		SimBot.play(gc, 20)
		check(gc.state.turn > 1, "played")
		var b := gc.history.filter(func(e: GameEvent) -> bool: return e.type == GameEvent.BUILDING \
				or (e.type == GameEvent.PSR and String(e.data["reason"]).begins_with("forcing")))
		building_events += b.size()
	check(building_events > 0, "'Mechs fought around the buildings")


func test_careful_entry_by_running_straight_in() -> void:
	var s := _state("heavy")
	var light := mech("jenner_jr7d", 0, hex_at(2, 3), 0, 1)
	s.add_unit(light)
	var into := MoveOptions.key(hex_at(2, 2), 0)
	var opts := MovePlanner.plan(s, light, MoveMode.Kind.RUN)
	check(opts.can_reach(into), "running straight in: careful entry, any class")
	check_eq(opts.careful_entry, into)
	check(not MovePlanner.plan(s, light, MoveMode.Kind.WALK).can_reach(into), "walking: still too light")
	var dice := LoadedDice.new()
	dice.queue_2d6(2)  # would fail an entry roll
	check(MoveExecutor.run(s, dice, _emit, light, into, MoveMode.Kind.RUN, -1))
	check_eq(light.coord, hex_at(2, 2))
	check(not events.any(func(e: GameEvent) -> bool: return e.type == GameEvent.PSR), "no roll")
	check(s.map.get_tile(hex_at(2, 2)).building != null, "no damage to the building")
	light.coord = hex_at(2, 4)
	check(not MovePlanner.plan(s, light, MoveMode.Kind.RUN).can_reach(into), "not from two hexes away")


func test_shoved_into_building_gets_destroy_check() -> void:
	var s := _state("medium", 3)
	var u := mech("jenner_jr7d", 1, hex_at(2, 3), 0, 1)
	s.add_unit(u)
	var dice := LoadedDice.new()
	dice.queue_2d6(5)  # destroy check fails (needs 9)
	check(Displacement.push(s, dice, _emit, u, 0), "a light 'Mech can be shoved in")
	check_eq(u.coord, hex_at(2, 2))
	var checks := events.filter(func(e: GameEvent) -> bool: return e.type == GameEvent.BUILDING and e.data["kind"] == "destroy_check")
	check_eq(checks.size(), 1, "an immediate destroy check")
	check(s.map.get_tile(hex_at(2, 2)).building != null, "it holds")


func test_smash_in_skips_roll_and_risks_collapse() -> void:
	var s := _state("medium", 3)
	var u := mech("griffin_grf1n", 0, hex_at(2, 2), 0, 1)
	s.add_unit(u)
	var dice := LoadedDice.new()
	dice.queue_2d6(5)   # destroy check fails (needs 9): the building holds
	BuildingRules.enter(s, dice, _emit, u, hex_at(2, 2), false, true)
	check(not events.any(func(e: GameEvent) -> bool: return e.type == GameEvent.PSR), "no entry roll")
	var kinds := events.filter(func(e: GameEvent) -> bool: return e.type == GameEvent.BUILDING).map(func(e: GameEvent) -> String: return e.data["kind"])
	check(kinds.has("smash") and kinds.has("destroy_check"), "smash, then a destroy check")
	check(s.map.get_tile(hex_at(2, 2)).building != null, "it holds")
