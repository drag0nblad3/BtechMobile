extends TestCase


func _state(rows: Array) -> GameState:
	return GameState.new(make_map(rows))


func _hex(col: int, row: int) -> Vector2i:
	return Hex.from_offset(Vector2i(col, row))


func test_enter_costs() -> void:
	var m := make_map(["c0 L0 H0 r0", "c1 c3 w0d1 w0d2"])
	var a := _hex(0, 0)
	check_eq(MoveCost.enter_cost(m, a, _hex(1, 0), MoveMode.Kind.WALK), 2, "light woods")
	check_eq(MoveCost.enter_cost(m, _hex(1, 0), _hex(2, 0), MoveMode.Kind.WALK), 3, "heavy woods")
	check_eq(MoveCost.enter_cost(m, a, _hex(0, 1), MoveMode.Kind.WALK), 2, "up one level")
	check_eq(MoveCost.enter_cost(m, a, _hex(1, 1), MoveMode.Kind.WALK),
			MoveCost.PROHIBITED, "3 levels is too steep")


func test_water_costs_and_running_in() -> void:
	var m := make_map(["c0 w0d1 w0d2"])
	var a := _hex(0, 0)
	var d1 := _hex(1, 0)
	check_eq(MoveCost.enter_cost(m, a, d1, MoveMode.Kind.WALK), 3, "depth 1: 1 + 1 water + 1 level down")
	check_eq(MoveCost.enter_cost(m, d1, _hex(2, 0), MoveMode.Kind.WALK), 4, "depth 2")
	check_eq(MoveCost.enter_cost(m, a, d1, MoveMode.Kind.RUN), 3, "running in is allowed (costs a roll)")


func test_run_mp_rounds_up() -> void:
	check_eq(make_def(3).run_mp(), 5)
	check_eq(make_def(4).run_mp(), 6)
	check_eq(make_def(5).run_mp(), 8)


func test_planner_respects_budget_and_turns() -> void:
	var s := _state(["c0 c0 c0 c0 c0", "c0 c0 c0 c0 c0", "c0 c0 c0 c0 c0"])
	var start := _hex(2, 2)
	var u := Unit.new(1, make_def(2), 0, start, 0)
	s.add_unit(u)
	var opts := MovePlanner.plan(s, u, MoveMode.Kind.WALK)
	# Facing north with 2 MP: two hexes straight ahead is reachable...
	var two_north := Hex.neighbor(Hex.neighbor(start, 0), 0)
	check(opts.can_reach(MoveOptions.key(two_north, 0)), "2 hexes north")
	# ...but turning around (3 hexsides) is not.
	check(not opts.can_reach(MoveOptions.key(start, 3)), "about-face costs 3")
	check_eq(opts.cost[MoveOptions.key(start, 1)], 1, "one turn")
	check_eq(opts.path_to(MoveOptions.key(two_north, 0)).size(), 2)


func test_enemy_blocks_friend_passes() -> void:
	var s := _state(["c0", "c0", "c0", "c0"])
	var u := Unit.new(1, make_def(3), 0, _hex(0, 3), 0)
	var friend := Unit.new(2, make_def(3), 0, _hex(0, 2), 0)
	s.add_unit(u)
	s.add_unit(friend)
	var opts := MovePlanner.plan(s, u, MoveMode.Kind.WALK)
	check(opts.can_reach(MoveOptions.key(_hex(0, 1), 0)), "through friend")
	check(not opts.can_reach(MoveOptions.key(_hex(0, 2), 0)), "can't stack on friend")
	friend.side = 1
	opts = MovePlanner.plan(s, u, MoveMode.Kind.WALK)
	check(not opts.cost.has(MoveOptions.key(_hex(0, 1), 0)), "enemy blocks")


func test_controller_turn_flow() -> void:
	var s := _state(["c0 c0 c0", "c0 c0 c0", "c0 c0 c0"])
	var a := Unit.new(1, make_def(4), 0, _hex(0, 2), 0)
	var b := Unit.new(2, make_def(4), 1, _hex(2, 0), 3)
	s.add_unit(a)
	s.add_unit(b)
	var gc := GameController.new(s, 1234)
	gc.start_turn()
	check_eq(s.phase, Phase.Kind.MOVEMENT)
	var first := s.unit_by_id(1) if s.active_side() == 0 else s.unit_by_id(2)
	var second := b if first == a else a
	check(not gc.submit_move(second, MoveOptions.key(second.coord, 1), 0), "out of turn")
	var target := MoveOptions.key(Hex.neighbor(first.coord, first.facing), first.facing)
	check(gc.submit_move(first, target, MoveMode.Kind.WALK), "legal move")
	check_eq(first.coord, MoveOptions.coord_of(target))
	check(gc.submit_move(second, MoveOptions.key(second.coord, second.facing), 0), "stand still")
	check_eq(s.phase, Phase.Kind.WEAPON_ATTACK, "all moved -> weapon attacks")
	check_eq(first.heat_generated, 1, "walking heat")
	check_eq(second.move_mode, -1, "standing still is not walking")
	var shooter := s.unit_by_id(1) if s.active_side() == 0 else s.unit_by_id(2)
	check(gc.declare_fire(shooter, []), "hold fire")
	check(gc.declare_fire(a if shooter == b else b, []), "hold fire")
	check_eq(s.turn, 2, "everyone done -> next turn")


func test_road_level_change_is_one_cheaper() -> void:
	var m := make_map(["p0 p1 p3", "c0 c1 p2"])
	check_eq(MoveCost.enter_cost(m, _hex(0, 0), _hex(1, 0), MoveMode.Kind.WALK), 1, "road to road, up 1: 1 + 0 (p. 53)")
	check_eq(MoveCost.enter_cost(m, _hex(2, 1), _hex(2, 0), MoveMode.Kind.WALK), 1, "road to road, level 2 to 3")
	check_eq(MoveCost.enter_cost(m, _hex(0, 1), _hex(1, 1), MoveMode.Kind.WALK), 2, "off the road: full level cost")
	check_eq(MoveCost.enter_cost(m, _hex(0, 1), _hex(0, 0), MoveMode.Kind.WALK), 1, "onto the road from clear at the same level")
	check_eq(MoveCost.enter_cost(m, _hex(1, 0), _hex(2, 0), MoveMode.Kind.WALK), 2, "road, up 2: 1 + 1")
