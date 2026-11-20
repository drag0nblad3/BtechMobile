extends TestCase
## Charges, death from above and pushes.


func _setup(attacker_id: String) -> Array:
	var s := GameState.new(open_map(6, 8))
	var a := mech(attacker_id, 0, hex_at(2, 6), 0, 1)
	var t := mech("hunchback_hbk4g", 1, hex_at(2, 2), 3, 2)
	s.add_unit(a)
	s.add_unit(t)
	return [s, a, t]


func test_charge_declared_and_resolved() -> void:
	var r := _setup("atlas_as7d")
	var s: GameState = r[0]
	var a: Unit = r[1]
	var t: Unit = r[2]
	var gc := GameController.new(s, 5)
	gc.start_turn()
	if s.active_side() == 1:
		gc.submit_move(t, MoveOptions.key(t.coord, t.facing), 0)
	# Walk 3 hexes north to stand next to the Hunchback, facing it.
	var dest := MoveOptions.key(hex_at(2, 3), 0)
	check(gc.submit_move(a, dest, MoveMode.Kind.WALK, t.id), "move + charge")
	check_eq(s.declared_physical.size(), 1, "charge stored")
	check(a.has_fired and a.has_physical, "charger skips other attacks")
	var opt: Dictionary = s.declared_physical[0]
	check_eq(opt["damage"], 30, "10 x 3 hexes")
	check_eq(opt["self_damage"], 5, "Hunchback's 50 t / 10")


func test_charge_needs_target_ahead() -> void:
	var r := _setup("atlas_as7d")
	var a: Unit = r[1]
	a.coord = hex_at(2, 3)
	a.facing = 1
	a.hexes_moved = 2
	a.move_mode = MoveMode.Kind.WALK
	check(not Charge.option(r[0], a, r[2], "charge")["to_hit"].possible(), "not straight ahead")
	a.facing = 0
	check(Charge.option(r[0], a, r[2], "charge")["to_hit"].possible(), "straight ahead")
	check(not Charge.option(r[0], a, r[2], "dfa")["to_hit"].possible(), "dfa needs a jump")


func test_dfa_hit_displaces_target() -> void:
	var r := _setup("jenner_jr7d")
	var s: GameState = r[0]
	var a: Unit = r[1]
	var t: Unit = r[2]
	a.coord = hex_at(2, 3)
	a.move_mode = MoveMode.Kind.JUMP
	a.hexes_moved = 3
	var opt := Charge.option(s, a, t, "dfa")
	check(opt["to_hit"].possible(), opt["to_hit"].summary())
	check_eq(opt["damage"], 12, "4 x 3")
	opt["attacker_id"] = a.id
	opt["target_id"] = t.id
	var dice := LoadedDice.new()
	dice.queue_2d6(12)
	dice.d6_queue.append_array([3, 3, 3])  # punch table: center torso
	var old := t.coord
	Charge.resolve(s, dice, func(_ty, _d): pass, opt)
	check_eq(t.coord, Hex.neighbor(old, 0), "target shoved away")
	check_eq(a.coord, old, "attacker takes its hex")
	check_eq(a.psr_pending.size(), 1)


func test_push_option() -> void:
	var r := _setup("atlas_as7d")
	var a: Unit = r[1]
	a.coord = hex_at(2, 3)
	var push: Dictionary = PhysicalOptions.for_target(r[0], a, r[2])[4]
	check_eq(push["kind"], "push")
	check_eq(push["to_hit"].target(), 4, "piloting 5 - 1")
