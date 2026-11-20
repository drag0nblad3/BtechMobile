extends TestCase
## Punches and kicks.


func _setup() -> Array:
	var s := GameState.new(open_map(5, 5))
	var a := mech("atlas_as7d", 0, hex_at(2, 3), 0, 1)
	var t := mech("hunchback_hbk4g", 1, Hex.neighbor(hex_at(2, 3), 0), 3, 2)
	s.add_unit(a)
	s.add_unit(t)
	return [s, a, t]


func test_punch_and_kick_numbers() -> void:
	var r := _setup()
	var opts := PhysicalOptions.for_target(r[0], r[1], r[2])
	check_eq(opts.size(), 4)
	var punch: Dictionary = opts[0]
	check(punch["to_hit"].possible(), punch["to_hit"].summary())
	check_eq(punch["to_hit"].target(), 5, "piloting 5")
	check_eq(punch["damage"], 10)
	var kick: Dictionary = opts[2]
	check_eq(kick["to_hit"].target(), 3, "piloting 5 - 2")
	check_eq(kick["damage"], 20)


func test_no_hand_and_fired_arm() -> void:
	var s := GameState.new(open_map(5, 5))
	var j := mech("jenner_jr7d", 0, hex_at(2, 3), 0, 1)
	var t := mech("hunchback_hbk4g", 1, Hex.neighbor(hex_at(2, 3), 0), 3, 2)
	s.add_unit(j)
	s.add_unit(t)
	var punch: Dictionary = PhysicalOptions.for_target(s, j, t)[0]
	# no hand +1, no lower arm +2
	check_eq(punch["to_hit"].target(), 8)
	check_eq(punch["damage"], 2, "4 halved")
	for w in j.weapons:
		if w.loc == Location.LA:
			w.fired = true
	check(not PhysicalOptions.for_target(s, j, t)[0]["to_hit"].possible(), "fired arm can't punch")


func test_not_adjacent() -> void:
	var r := _setup()
	r[2].coord = hex_at(2, 0)
	for o in PhysicalOptions.for_target(r[0], r[1], r[2]):
		check(not o["to_hit"].possible(), "too far")


func test_declare_two_punches_or_one_kick() -> void:
	var r := _setup()
	var both := PhysicalOptions.declare(r[0], r[1], [
			{"kind": "punch", "limb": Location.LA, "target_id": 2},
			{"kind": "punch", "limb": Location.RA, "target_id": 2}])
	check_eq(both.size(), 2)
	var mixed := PhysicalOptions.declare(r[0], r[1], [
			{"kind": "punch", "limb": Location.LA, "target_id": 2},
			{"kind": "kick", "limb": Location.RL, "target_id": 2}])
	check_eq(mixed.size(), 1, "kick can't join a punch")


func test_kick_resolution_forces_roll() -> void:
	var r := _setup()
	var s: GameState = r[0]
	var t: Unit = r[2]
	s.declared_physical = PhysicalOptions.declare(s, r[1], [
			{"kind": "kick", "limb": Location.RL, "target_id": 2}])
	var dice := LoadedDice.new()
	dice.queue_2d6(9)   # hit (needs 3)
	dice.d6_queue.append(1)  # kick table: right leg
	PhysicalPhase.resolve(s, dice, func(_t, _d): pass)
	check_eq(t.armor[Location.RL], 0, "20 damage strips 20 armor")
	check_eq(t.psr_pending.size(), 1, "kicked -> piloting roll")
