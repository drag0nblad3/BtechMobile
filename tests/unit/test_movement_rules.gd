extends TestCase
## Minimum movement, going prone and piloting rolls caused by movement.


func test_minimum_movement_one_hex() -> void:
	# Heavy woods ahead cost 3 MP; a 'Mech left with 1 MP may still step in.
	var s := GameState.new(make_map(["c0 c0 c0", "c0 H0 c0", "c0 c0 c0"]))
	var u := mech("atlas_as7d", 0, hex_at(1, 2), 0, 1)
	s.add_unit(u)
	u.structure[Location.LL] = 0  # leg gone: walk MP drops
	u.armor[Location.LL] = 0
	var budget := MoveMode.budget(u, MoveMode.Kind.WALK)
	check(budget >= 1 and budget < 3, "few MP left: %d" % budget)
	var opts := MovePlanner.plan(s, u, MoveMode.Kind.WALK)
	check(opts.can_reach(MoveOptions.key(hex_at(1, 1), 0)), "one hex into the woods")
	check_eq(opts.cost[MoveOptions.key(hex_at(1, 1), 0)], budget, "uses all MP")


func test_go_prone() -> void:
	var s := GameState.new(open_map(5, 5))
	var a := mech("hunchback_hbk4g", 0, hex_at(2, 4), 0, 1)
	var b := mech("hunchback_hbk4g", 1, hex_at(2, 0), 3, 2)
	s.add_unit(a)
	s.add_unit(b)
	var gc := GameController.new(s, 3)
	gc.start_turn()
	var mover := gc.pending_units()[0]
	check(gc.go_prone(mover), "may drop prone")
	check(mover.prone and mover.has_moved, "prone and done moving")
	check_eq(mover.heat_generated, 1)
	var e: GameEvent = gc.history.filter(func(x: GameEvent) -> bool: return x.type == GameEvent.WENT_PRONE)[0]
	check(Explainer.text(e, s, ExplainLevel.FULL).contains("adjacent"), "explained")


func test_wading_and_damaged_running_cost_rolls() -> void:
	var s := GameState.new(make_map(["c0 c0 c0", "c0 w0d2 c0", "c0 c0 c0"]))
	var u := mech("hunchback_hbk4g", 0, hex_at(1, 2), 0, 1)
	s.add_unit(u)
	var path: Array[Vector3i] = [MoveOptions.key(hex_at(1, 1), 0)]
	MovePsr.after_move(s, u, path, MoveMode.Kind.WALK)
	check_eq(u.psr_pending.size(), 1, "deep water")
	check_eq(u.psr_pending[0]["mod"], 0, "depth 2 is +0")
	u.psr_pending.clear()
	u.gyro_hits = 1
	MovePsr.after_move(s, u, [] as Array[Vector3i], MoveMode.Kind.RUN)
	check(u.psr_pending.size() == 1 and String(u.psr_pending[0]["reason"]).contains("gyro"), "running on a hit gyro")
