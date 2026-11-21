extends TestCase
## Ice, mud, snow, avalanches and the conditions that lay them down (book pp. 121-125).

var events: Array = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append([t, d])


func _rows3() -> Array:
	return ["c2 c1 c0", "c2 w2d1 c0", "p0 c0 c0"]


func test_conditions_lay_down_ice_mud_snow_and_sinkholes() -> void:
	var s := GameState.new(make_map(_rows3()))
	var water := hex_at(1, 1)
	s.conditions = Conditions.from_dict({"cold": 1})
	var wt := s.map.get_tile(water)
	check_eq(wt.surface, "ice", "cold freezes water")
	check(not wt.is_water(), "walk on the ice")
	check_eq(wt.floor_level(), 2, "on the surface")
	s = GameState.new(make_map(_rows3()))
	s.conditions = Conditions.from_dict({"heat": 1})
	wt = s.map.get_tile(water)
	check(not wt.terrain.is_water and wt.level == 1 and wt.depth == 0, "dried into a sinkhole at level 1")
	s = GameState.new(make_map(_rows3()))
	s.conditions = Conditions.from_dict({"rain": true})
	check_eq(s.map.get_tile(hex_at(0, 0)).surface, "mud")
	check_eq(s.map.get_tile(hex_at(0, 2)).surface, "", "no mud on pavement")
	check_eq(s.map.get_tile(water).surface, "", "no mud in water")
	check(s.map.no_fire, "rain: no fires")
	s = GameState.new(make_map(_rows3()))
	s.conditions = Conditions.from_dict({"snowfall": true})
	check_eq(s.map.get_tile(hex_at(0, 2)).surface, "snow", "snow on pavement too")


func test_ice_adds_to_piloting_rolls() -> void:
	var s := GameState.new(MapLoader.from_dict({"rows": ["c0 c0"], "surface": {"ice": ["0101"]}}, terrain()))
	var u := mech("hunchback_hbk4g", 0, hex_at(0, 0), 0, 1)
	s.add_unit(u)
	events.clear()
	var dice := LoadedDice.new()
	dice.queue_2d6(5)
	check(not Psr.roll(dice, _emit, u, "test", 0, s), "5 + 1 ice")


func test_mud_turn_while_running() -> void:
	var s := GameState.new(MapLoader.from_dict({"rows": ["c0 c0 c0", "c0 c0 c0", "c0 c0 c0"],
			"surface": {"mud": ["0202"]}}, terrain()))
	var u := mech("hunchback_hbk4g", 0, hex_at(1, 2), 0, 1)
	s.add_unit(u)
	var mid := hex_at(1, 1)
	var path: Array[Vector3i] = [MoveOptions.key(mid, 0), MoveOptions.key(mid, 1), MoveOptions.key(mid, 2)]
	var rolls := MovePsr.action_rolls(s, u, path, MoveOptions.key(u.coord, 0), MoveMode.Kind.RUN)
	check_eq(rolls.size(), 1, "one roll for turning in the mud hex")
	check_eq(int(rolls[0]["mod"]), -1)
	check(MovePsr.action_rolls(s, u, path, MoveOptions.key(u.coord, 0), MoveMode.Kind.WALK).is_empty(), "walking is fine")


func test_snow_cools_and_avalanches() -> void:
	var s := GameState.new(MapLoader.from_dict({"rows": ["c3 c0 c0", "c0 c0 c0", "c0 c0 c0"],
			"surface": {"snow": ["0101"]}}, terrain()))
	var u := mech("hunchback_hbk4g", 0, hex_at(0, 0), 0, 1)
	s.add_unit(u)
	check_eq(Surfaces.snow_cooling(s, u), 2, "1 per leg")
	u.prone = true
	check_eq(Surfaces.snow_cooling(s, u), 4, "4 prone")
	u.prone = false
	events.clear()
	Fall.fall(s, LoadedDice.new([6, 6, 6, 6, 6, 6, 6, 6]), _emit, u, 0, "test")
	check(u.coord != hex_at(0, 0), "slid off the snowy hilltop")
	var falls := events.filter(func(e): return e[0] == GameEvent.FALL)
	check_eq(falls[0][1]["levels"], 3, "fell the 3 levels it slid down")
