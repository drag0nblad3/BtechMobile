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
	check_eq(tile.building.cf, 40)
	check_eq(tile.building.absorbs(), 4)
	check_eq(MoveCost.enter_cost(s.map, hex_at(2, 3), hex_at(2, 2), MoveMode.Kind.WALK), 3, "1 + 2 for medium")
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


func test_heavy_mech_collapses_light_building() -> void:
	var s := _state("light")
	var u := mech("atlas_as7d", 0, hex_at(2, 4), 0, 1)
	s.add_unit(u)
	var path: Array[Vector3i] = [MoveOptions.key(hex_at(2, 3), 0), MoveOptions.key(hex_at(2, 2), 0),
			MoveOptions.key(hex_at(2, 1), 0)]
	var entry := BuildingRules.plan_entry(s.map, u, path, false)
	check(entry["collapse"], "100 t > 15 CF")
	check_eq((entry["path"] as Array).size(), 2, "move stops in the building")
	u.coord = hex_at(2, 2)
	var dice := LoadedDice.new([1])  # fall direction, then 6s
	for i in 6:
		dice.queue_2d6(7)  # 30 fall damage to the center torso
	BuildingRules.enter(s, dice, _emit, u, hex_at(2, 2))
	var tile := s.map.get_tile(hex_at(2, 2))
	check(tile.building == null and tile.terrain.id == "rubble", "now rubble")
	check(u.prone, "Atlas fell")
	check(not u.destroyed, "survives")
	check(Explainer.text(events[0], s, ExplainLevel.FULL).contains("heavier"), "explains why")


func test_failed_roll_scrapes_walls() -> void:
	var s := _state("medium")
	var u := mech("jenner_jr7d", 0, hex_at(2, 2), 0, 1)  # 35 t: under the 40 CF
	s.add_unit(u)
	var dice := LoadedDice.new()
	dice.queue_2d6(2)  # piloting roll fails
	dice.queue_2d6(7)  # center torso
	BuildingRules.enter(s, dice, _emit, u, hex_at(2, 2))
	var dmg := 0
	for e in events:
		if e.type == GameEvent.DAMAGE:
			dmg += int(e.data["amount"])
	check_eq(dmg, 4, "CF 40 / 10")
	check_eq(s.map.get_tile(hex_at(2, 2)).building.cf, 40, "own walls not damaged")


func test_walls_soak_hits() -> void:
	var s := _state("medium")
	var u := mech("griffin_grf1n", 0, hex_at(2, 2), 0, 1)
	s.add_unit(u)
	var before := u.armor[Location.CT]
	var hl := {"loc": Location.CT, "rear": false, "tac": false}
	WeaponFire.hit_with(s, LoadedDice.new(), _emit, u, FiringArc.FRONT, 10, 99, "AC/10", hl)
	check_eq(before - u.armor[Location.CT], 6, "4 of 10 soaked")
	check_eq(s.map.get_tile(hex_at(2, 2)).building.cf, 30, "building took the hit")
	for i in 3:
		WeaponFire.hit_with(s, LoadedDice.new(), _emit, u, FiringArc.FRONT, 10, 99, "AC/10", hl)
	check(s.map.get_tile(hex_at(2, 2)).building == null, "collapsed at 0 CF")
	check(u.prone, "fell with it")


func test_city_battle_runs() -> void:
	var fb := ForceBuilder.new(UnitDb.load_dir(), 8000)
	for id in ["atlas_as7d", "jenner_jr7d", "griffin_grf1n"]:
		fb.add(0, id)
	for id in ["warhammer_whm6r", "commando_com2d", "hunchback_hbk4g"]:
		fb.add(1, id)
	var building_events := 0
	for seed_value in [3, 4]:
		var map := MapLoader.load_file("res://data/maps/city_outskirts.json", terrain())
		var gc := GameController.new(fb.build(map), seed_value)
		SimBot.play(gc, 20)
		check(gc.state.turn > 1, "played")
		var b := gc.history.filter(func(e: GameEvent) -> bool: return e.type == GameEvent.BUILDING)
		building_events += b.size()
	check(building_events > 0, "'Mechs fought around the buildings")
