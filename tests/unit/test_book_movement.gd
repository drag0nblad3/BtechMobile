extends TestCase
## Movement and piloting rules checked against the book: leg damage MP,
## cumulative piloting mods, the domino effect, jumping and standing up.

var events: Array[GameEvent] = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append(GameEvent.new(t, d))


func _hit_actuator(u: Unit, loc: int, name: String) -> void:
	for s: CritSlot in u.slots[loc]:
		if s.kind == CritSlot.Kind.ACTUATOR and s.name == name:
			s.hit = true
			return


func _psr_needs() -> Array[int]:
	var out: Array[int] = []
	for e in events:
		if e.type == GameEvent.PSR:
			out.append(int(e.data["need"]))
	return out


func test_leg_damage_lowers_walk_mp() -> void:
	var u := mech("hunchback_hbk4g", 0, hex_at(1, 1))
	check_eq(u.walk_mp(), 4)
	_hit_actuator(u, Location.LL, "foot")
	_hit_actuator(u, Location.RL, "upper_leg")
	check_eq(u.walk_mp(), 2, "-1 per leg actuator")
	check_eq(u.run_mp(), 3)
	u.structure[Location.LL] = 0
	check_eq(u.walk_mp(), 1, "one leg left: 1 MP")
	u.structure[Location.RL] = 0
	check_eq(u.walk_mp(), 0, "no legs")
	check(ToHitCalc.is_immobile(u), "no legs is immobile")


func test_psr_mods_add_up_and_one_roll_per_leg() -> void:
	events.clear()
	var s := GameState.new(open_map(3, 3))
	var u := mech("hunchback_hbk4g", 0, hex_at(1, 1))
	s.add_unit(u)
	u.psr_pending.append({"reason": "took 20 damage", "mod": 1})
	u.psr_pending.append({"reason": "hip hit", "mod": 0, "leg": Location.LL})
	u.psr_pending.append({"reason": "foot hit", "mod": 0, "leg": Location.LL})
	Psr.resolve_pending(s, LoadedDice.new(), _emit, u)
	check_eq(_psr_needs(), [6, 6] as Array[int], "the +1 applies to both rolls; one roll for the leg")


func test_domino_steps_aside_or_falls_off_the_map() -> void:
	events.clear()
	var s := GameState.new(open_map(3, 4))
	var a := mech("hunchback_hbk4g", 0, hex_at(1, 2), 0, 1)
	var b := mech("hunchback_hbk4g", 1, hex_at(1, 1), 0, 2)
	s.add_unit(a)
	s.add_unit(b)
	check(Displacement.push(s, LoadedDice.new(), _emit, a, 0), "pushed")
	check_eq(a.coord, hex_at(1, 1))
	check_eq(b.coord, hex_at(1, 0), "made room by stepping forward")
	check(not b.prone, "passed its roll")
	check(Displacement.push(s, LoadedDice.new(), _emit, b, 0), "off the edge")
	check(b.destroyed, "pushed off the map is destroyed")


func test_push_limits_by_level() -> void:
	events.clear()
	var s := GameState.new(make_map(["c3 c0 c0", "c0 c0 c0", "c0 c0 c0"]))
	var u := mech("hunchback_hbk4g", 0, hex_at(0, 1), 0, 1)
	s.add_unit(u)
	check(not Displacement.push(s, LoadedDice.new(), _emit, u, 0), "can't be pushed 3 levels up")
	check_eq(u.coord, hex_at(0, 1))


func test_jump_from_water_and_onto_buildings() -> void:
	var s := GameState.new(MapLoader.from_dict({"rows": ["c0 c0 c0 c0", "w0d1 c0 c0 c0", "w0d2 c0 c0 c0"],
			"buildings": [{"hex": "0302", "type": "medium", "height": 1}]}, terrain()))
	var u := mech("jenner_jr7d", 0, hex_at(0, 1), 0, 1)
	s.add_unit(u)
	check_eq(JumpPlanner.jump_mp(s, u), u.jump_mp() - u.leg_jump_jets(), "leg jets don't fire in depth 1")
	var opts := JumpPlanner.plan(s, u)
	check(not opts.can_reach(MoveOptions.key(hex_at(2, 1), 0)), "no landing in a building")
	u.coord = hex_at(0, 2)
	check_eq(JumpPlanner.jump_mp(s, u), 0, "can't jump out of depth 2")


func test_backward_level_change_needs_a_roll() -> void:
	var s := GameState.new(make_map(["c0 c1 c0", "c0 c0 c0", "c0 c0 c0"]))
	var u := mech("hunchback_hbk4g", 0, hex_at(1, 1), 3, 1)  # facing south
	s.add_unit(u)
	var path: Array[Vector3i] = [MoveOptions.key(hex_at(1, 0), 3)]
	var rolls := MovePsr.action_rolls(s, u, path, MoveOptions.key(u.coord, 3), MoveMode.Kind.WALK)
	check_eq(rolls.size(), 1)
	check_eq(String(rolls[0]["reason"]), "backward level change")


func test_standing_up_allows_any_facing() -> void:
	var s := GameState.new(open_map(3, 3))
	var u := mech("hunchback_hbk4g", 0, hex_at(1, 1), 0, 1)
	s.add_unit(u)
	u.prone = true
	var opts := MovePlanner.plan(s, u, MoveMode.Kind.WALK)
	check(opts.can_reach(MoveOptions.key(hex_at(1, 1), 3)), "stand facing backward at no extra cost")
	check_eq(opts.cost[MoveOptions.key(hex_at(1, 1), 3)], 0)


func test_drop_prone_after_moving() -> void:
	events.clear()
	var s := GameState.new(open_map(5, 8))
	var u := mech("hunchback_hbk4g", 0, hex_at(2, 6), 0, 1)
	s.add_unit(u)
	var opts := MovePlanner.plan(s, u, MoveMode.Kind.WALK)
	var three := MoveOptions.key(hex_at(2, 3), 0)
	var four := MoveOptions.key(hex_at(2, 2), 0)
	check(ProneMoves.can_drop_after(opts, three), "3 of 4 MP leaves 1 to drop")
	check(not ProneMoves.can_drop_after(opts, four), "no MP left to drop")
	check(not MoveExecutor.run(s, LoadedDice.new(), _emit, u, four, MoveMode.Kind.WALK, -1, true))
	check(MoveExecutor.run(s, LoadedDice.new(), _emit, u, three, MoveMode.Kind.WALK, -1, true))
	check(u.prone and u.coord == hex_at(2, 3), "moved, then dropped")
	check(events.any(func(e: GameEvent) -> bool: return e.type == GameEvent.WENT_PRONE))
	var j := mech("griffin_grf1n", 0, hex_at(0, 6), 0, 2)
	s.add_unit(j)
	var jo := MovePlanner.plan(s, j, MoveMode.Kind.JUMP)
	check(not ProneMoves.can_drop_after(jo, MoveOptions.key(hex_at(0, 5), 0)), "not after jumping")


func test_destroyed_gyro_turns_one_hexside() -> void:
	var s := GameState.new(open_map(5, 8))
	var u := mech("hunchback_hbk4g", 0, hex_at(2, 4), 0, 1)
	s.add_unit(u)
	u.prone = true
	u.gyro_hits = CritEffects.GYRO_KILL
	var opts := MovePlanner.plan(s, u, MoveMode.Kind.WALK)
	check_eq(opts.reachable_hexes().keys(), [hex_at(2, 4)], "can't leave its hex")
	check(opts.can_reach(MoveOptions.key(hex_at(2, 4), 1)))
	check(not opts.can_reach(MoveOptions.key(hex_at(2, 4), 2)), "only one facing change")
	events.clear()
	check(MoveExecutor.run(s, LoadedDice.new(), _emit, u, MoveOptions.key(hex_at(2, 4), 5), MoveMode.Kind.WALK, -1))
	check(u.prone and u.facing == 5, "turned without trying to stand")
	check(not events.any(func(e: GameEvent) -> bool: return e.type == GameEvent.STAND))
	u.gyro_hits = 0
	u.structure[Location.LL] = 0
	u.structure[Location.RL] = 0
	check(MovePlanner.plan(s, u, MoveMode.Kind.WALK).reachable_hexes().size() == 1, "legless: stays put")


func test_consciousness_rolled_right_after_the_move() -> void:
	events.clear()
	var s := GameState.new(open_map(5, 8))
	var u := mech("hunchback_hbk4g", 0, hex_at(2, 6), 0, 1)
	s.add_unit(u)
	u.pilot.hits = 1
	u.pilot.roll_owed = true
	check(MoveExecutor.run(s, LoadedDice.new(), _emit, u, MoveOptions.key(hex_at(2, 5), 0), MoveMode.Kind.WALK, -1))
	check(events.any(func(e: GameEvent) -> bool: return e.type == GameEvent.CONSCIOUSNESS), "rolled in the Movement Phase")
	check(not u.pilot.roll_owed)
