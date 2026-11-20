extends TestCase
## Building roofs (book pp. 132-137): jump on, roof-to-roof moves, support
## limit, falling when the roof comes down, height for sight and physicals.

var events: Array[GameEvent] = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append(GameEvent.new(t, d))


## Row 2 holds three buildings: 0102 light/2, 0202 medium/2, 0302 medium/1.
func _state() -> GameState:
	events.clear()
	return GameState.new(MapLoader.from_dict({"rows": ["c0 c0 c0 c0", "c0 c0 c0 c0", "c0 c0 c0 c0", "c0 c0 c0 c0"],
			"buildings": [{"hex": "0102", "type": "light", "height": 2},
					{"hex": "0202", "type": "medium", "height": 2},
					{"hex": "0302", "type": "medium", "height": 1}]}, terrain()))


func _kinds() -> Array:
	return events.filter(func(e: GameEvent) -> bool: return e.type == GameEvent.BUILDING) \
			.map(func(e: GameEvent) -> String: return e.data["kind"])


func test_jump_onto_roof_and_walk_across() -> void:
	var s := _state()
	var u := mech("jenner_jr7d", 0, hex_at(1, 3), 0, 1)  # 35 t light
	s.add_unit(u)
	var roof := MoveOptions.key(hex_at(1, 1), 5)
	check(MoveExecutor.run(s, LoadedDice.new(), _emit, u, roof, MoveMode.Kind.JUMP, -1))
	check(u.on_roof, "on the roof")
	check_eq(Roofs.floor_of(s.map, u), 2)
	check_eq(LineOfSight.los_level(s.map, u), 4)
	check(not _kinds().has("destroy_check"), "a medium roof holds a light 'Mech")
	check(not events.any(func(e: GameEvent) -> bool: return e.type == GameEvent.PSR), "no entry roll")
	var opts := MovePlanner.plan(s, u, MoveMode.Kind.WALK)
	check(opts.can_reach(MoveOptions.key(hex_at(0, 1), 5)), "across to the light roof at the same level")
	check(not opts.reachable_hexes().has(hex_at(1, 0)), "can't step off to the ground")
	u.facing = 2
	opts = MovePlanner.plan(s, u, MoveMode.Kind.WALK)
	var down := MoveOptions.key(hex_at(2, 1), 2)
	check(opts.can_reach(down), "one level down onto the lower roof")
	check_eq(BuildingRules.inside_mod(s.map, u), 0, "not inside")


func test_heavy_mech_overloads_roof_and_falls() -> void:
	var s := _state()
	var u := mech("griffin_grf1n", 0, hex_at(0, 3), 0, 1)  # 55 t medium
	s.add_unit(u)
	check_eq(Roofs.support_mod(s.map.get_tile(hex_at(0, 1)).building, 55), 2, "one class over a light roof")
	check_eq(Roofs.support_mod(s.map.get_tile(hex_at(1, 1)).building, 55), -1, "a medium roof holds it")
	var dice := LoadedDice.new()
	dice.queue_2d6(5)  # 5 + 2 >= 7: the light building gives way
	check(MoveExecutor.run(s, dice, _emit, u, MoveOptions.key(hex_at(0, 1), 0), MoveMode.Kind.JUMP, -1))
	check(_kinds().has("destroy_check") and _kinds().has("collapsed"))
	check(not u.on_roof and u.prone, "fell to the ground")
	var falls := events.filter(func(e: GameEvent) -> bool: return e.type == GameEvent.FALL)
	check(falls.size() == 1 and int(falls[0].data["levels"]) == 2, "falls the building's height")


func test_roof_height_counts_for_physical_attacks() -> void:
	var s := _state()
	var u := mech("jenner_jr7d", 0, hex_at(2, 1), 0, 1)
	var t := mech("jenner_jr7d", 1, hex_at(2, 0), 3, 2)
	s.add_unit(u)
	s.add_unit(t)
	u.on_roof = true
	check_eq(PhysicalMods.level_diff(s, t, u), 1, "the roof 'Mech stands a level above")
	Displacement.push(s, LoadedDice.new(), _emit, u, 3)
	check(not u.on_roof, "pushed off the roof")
