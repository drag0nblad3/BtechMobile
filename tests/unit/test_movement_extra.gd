extends TestCase
## Backward walking, jumping and torso twist.


func test_backward_walking() -> void:
	var s := GameState.new(open_map(3, 5))
	var u := mech("hunchback_hbk4g", 0, hex_at(1, 2), 0, 1)
	s.add_unit(u)
	var back := MoveOptions.key(Hex.neighbor(u.coord, 3), 0)
	check(MovePlanner.plan(s, u, MoveMode.Kind.WALK).can_reach(back), "walk backward keeping facing")
	check_eq(MovePlanner.plan(s, u, MoveMode.Kind.WALK).cost[back], 1)
	var run := MovePlanner.plan(s, u, MoveMode.Kind.RUN)
	check(run.cost.get(back, 99) > 1, "can't run backward")


func test_jump_range_and_landing() -> void:
	var s := GameState.new(make_map(["c0 c0 c0 c0 c0 c0", "c0 H0 w0d2 c0 c0 c0", "c0 c0 c0 c0 c0 c0"]))
	var u := mech("jenner_jr7d", 0, hex_at(0, 1), 2, 1)
	s.add_unit(u)
	var opts := MovePlanner.plan(s, u, MoveMode.Kind.JUMP)
	check_eq(opts.budget, 5)
	check(opts.can_reach(MoveOptions.key(hex_at(3, 1), 4)), "any facing after a jump, over woods")
	check(not opts.can_reach(MoveOptions.key(hex_at(2, 1), 0)), "not into deep water")
	check(not opts.cost.has(MoveOptions.key(hex_at(5, 1) + Vector2i(1, 0), 0)), "beyond range")
	var gc := GameController.new(s, 3)
	s.add_unit(mech("hunchback_hbk4g", 1, hex_at(5, 0), 3, 2))
	gc.start_turn()
	if s.active_side() == 1:
		var e := s.unit_by_id(2)
		gc.submit_move(e, MoveOptions.key(e.coord, e.facing), 0)
	check(gc.submit_move(u, MoveOptions.key(hex_at(4, 1), 1), MoveMode.Kind.JUMP), "jump")
	check_eq(u.hexes_moved, 4)
	check_eq(u.heat_generated, 4, "1 heat per hex, min 3")
	check_eq(ToHitCalc.target_movement_mod(4, true), 2, "jumped 4: +1 +1")


func test_hunchback_cant_jump() -> void:
	var s := GameState.new(open_map(3, 3))
	var u := mech("hunchback_hbk4g", 0, hex_at(1, 1), 0, 1)
	s.add_unit(u)
	check_eq(MovePlanner.plan(s, u, MoveMode.Kind.JUMP).reachable_hexes().size(), 1, "only stay")


func test_torso_twist_brings_target_into_arc() -> void:
	var s := GameState.new(open_map(8, 8))
	var a := mech("hunchback_hbk4g", 0, hex_at(3, 4), 0, 1)
	var t := mech("jenner_jr7d", 1, hex_at(3, 4) + Vector2i(3, 0), 0, 2)  # off to the right side
	s.add_unit(a)
	s.add_unit(t)
	var ac := a.weapons[1]
	check(not ToHitCalc.weapon(s, a, ac, t).possible(), "RT AC/20 can't fire to the side")
	a.torso_twist = 1
	check(ToHitCalc.weapon(s, a, ac, t).possible(), "after twisting right it can")
