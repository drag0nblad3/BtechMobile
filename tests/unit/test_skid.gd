extends TestCase
## Skid helpers (kept for optional rules; the Core Rulebook move doesn't skid).

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


func test_core_rules_moves_never_skid() -> void:
	var s := _road()
	var u := mech("hunchback_hbk4g", 0, hex_at(1, 7), 0, 1)
	s.add_unit(u)
	var dice := LoadedDice.new()
	dice.queue_2d6(2)   # would fail a skid roll
	MoveExecutor.run(s, dice, _emit, u, MoveOptions.key(hex_at(1, 3), 1), MoveMode.Kind.RUN, -1)
	check_eq(u.coord, hex_at(1, 3))
	check_eq(u.facing, 1)
	check(not u.prone, "still standing")
	check(events.filter(func(e: GameEvent) -> bool: return e.type == GameEvent.SKID).is_empty(), "no skid")
