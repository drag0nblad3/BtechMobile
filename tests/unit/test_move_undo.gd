extends TestCase
## Training undo: only while no dice were rolled since the move, same phase.


func _game() -> GameController:
	var s := GameState.new(open_map(12, 4))
	s.add_unit(mech("hunchback_hbk4g", 0, hex_at(1, 1), 2, 1))
	s.add_unit(mech("hunchback_hbk4g", 1, hex_at(10, 1), 5, 2))
	var gc := GameController.new(s, 4)
	gc.start_turn()  # initiative rolled, now in movement
	return gc


func test_take_back_restores_position() -> void:
	var gc := _game()
	var u: Unit = gc.pending_units()[0]
	var start := u.coord
	var undo := MoveUndo.new()
	check(not undo.available(gc), "nothing to undo yet")
	undo.remember(gc, [], 0, 0, [])
	var opts := MovePlanner.plan(gc.state, u, MoveMode.Kind.WALK)
	var dest := Hex.neighbor(start, u.facing)
	check(gc.submit_move(u, opts.end_keys_in(dest)[0], MoveMode.Kind.WALK), "moved")
	check(undo.available(gc), "undo offered after a dice-free move")
	var back := BattleSave.restore(undo.snapshot, designs(), terrain())
	var c2: GameController = back["controller"]
	check_eq(c2.state.unit_by_id(u.id).coord, start, "unit back where it started")
	check_eq(c2.dice._rng.state, gc.dice._rng.state, "same dice ahead")
	gc.dice.roll_2d6()
	check(not undo.available(gc), "no undo once dice were rolled")
