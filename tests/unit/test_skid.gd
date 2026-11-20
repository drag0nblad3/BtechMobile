extends TestCase
## Skidding when a running 'Mech turns on pavement.

var events: Array[GameEvent] = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append(GameEvent.new(t, d))


func _road() -> GameState:
	var rows := []
	for r in 8:
		rows.append("p0 p0 p0")
	events.clear()
	return GameState.new(make_map(rows))


func test_find_and_modifier() -> void:
	var s := _road()
	var from := MoveOptions.key(hex_at(1, 7), 0)
	var path: Array[Vector3i] = []
	for r in [6, 5, 4, 3]:
		path.append(MoveOptions.key(hex_at(1, r), 0))
	path.append(MoveOptions.key(hex_at(1, 3), 1))
	var sk := Skid.find(s.map, path, from, MoveMode.Kind.RUN)
	check_eq(sk["index"], 4)
	check_eq(sk["hexes"], 4)
	check_eq(sk["mod"], 0, "3-4 hexes is +0")
	check(Skid.find(s.map, path, from, MoveMode.Kind.WALK).is_empty(), "walking never skids")
	check_eq(Skid.modifier(1), -1)
	check_eq(Skid.modifier(9), 2)


func test_failed_roll_slides_and_falls() -> void:
	var s := _road()
	var u := mech("hunchback_hbk4g", 0, hex_at(1, 7), 0, 1)
	s.add_unit(u)
	var dice := LoadedDice.new()
	dice.queue_2d6(2)   # skid roll fails
	dice.d6_queue.append(1)  # fall direction
	dice.queue_2d6(7)   # fall damage location
	var ok := MoveExecutor.run(s, dice, _emit, u, MoveOptions.key(hex_at(1, 3), 1), MoveMode.Kind.RUN, -1)
	check(ok, "move accepted")
	check_eq(u.coord, hex_at(1, 1), "slid 2 hexes past the turn")
	check(u.prone, "fell")
	var skids := events.filter(func(e: GameEvent) -> bool: return e.type == GameEvent.SKID)
	check_eq(skids.size(), 1)
	check(Explainer.text(skids[0], s, ExplainLevel.FULL).contains("pavement"), "explained")


func test_passed_roll_turns_normally() -> void:
	var s := _road()
	var u := mech("hunchback_hbk4g", 0, hex_at(1, 7), 0, 1)
	s.add_unit(u)
	MoveExecutor.run(s, LoadedDice.new(), _emit, u, MoveOptions.key(hex_at(1, 3), 1), MoveMode.Kind.RUN, -1)
	check_eq(u.coord, hex_at(1, 3))
	check_eq(u.facing, 1)
	check(not u.prone, "still standing")
