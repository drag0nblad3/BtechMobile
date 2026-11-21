extends TestCase
## Piloting skill rolls, falls and standing up.

var events: Array = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append([t, d])


func test_twenty_damage_needs_roll() -> void:
	var u := mech("hunchback_hbk4g", 0, hex_at(1, 1))
	var s := GameState.new(open_map(3, 3))
	s.add_unit(u)
	u.damage_this_phase = 20
	var dice := LoadedDice.new()
	dice.queue_2d6(5)   # needs 6 (5 + 1): fail
	dice.queue_2d6(1)   # fall direction: 1, 1 -> front ... d6 queue
	Psr.end_of_phase(s, dice, _emit)
	check(u.prone, "failed roll -> prone")
	var falls := events.filter(func(e): return e[0] == GameEvent.FALL)
	check_eq(falls.size(), 1)
	check_eq(falls[0][1]["damage"], 5, "50 tons -> 5 damage")


func test_pass_keeps_standing() -> void:
	var u := mech("hunchback_hbk4g", 0, hex_at(1, 1))
	var s := GameState.new(open_map(3, 3))
	s.add_unit(u)
	u.psr_pending.append({"reason": "test", "mod": 0})
	var dice := LoadedDice.new()
	dice.queue_2d6(5)
	Psr.end_of_phase(s, dice, _emit)
	check(not u.prone, "5 vs 5 passes")


func test_fall_damage_scales() -> void:
	var a := mech("atlas_as7d", 0, Vector2i.ZERO)
	check_eq(Fall.damage_for(a, 0), 10)
	check_eq(Fall.damage_for(a, 2), 30)
	var j := mech("jenner_jr7d", 0, Vector2i.ZERO)
	check_eq(Fall.damage_for(j, 0), 4)


func test_stand_up_costs_mp() -> void:
	var u := mech("hunchback_hbk4g", 0, hex_at(1, 1))
	check_eq(MoveMode.budget(u, MoveMode.Kind.WALK), 4)
	u.prone = true
	check_eq(MoveMode.budget(u, MoveMode.Kind.WALK), 2)
	u.gyro_hits = 2
	check(not Psr.can_stand(u), "destroyed gyro")


func test_shutdown_doesnt_fall() -> void:
	var u := mech("jenner_jr7d", 0, hex_at(1, 1))
	var s := GameState.new(open_map(3, 3))
	s.add_unit(u)
	u.heat = 30  # 20 after 10 heat sinks
	var dice := LoadedDice.new()
	dice.queue_2d6(2)   # shutdown roll (6+) fails: shutdown comes first
	dice.queue_2d6(12)  # ammo explosion roll passes
	HeatPhase.run(s, dice, _emit)
	check(u.shutdown, "shut down")
	check(not u.prone, "shutting down doesn't knock it over")
	check(not u.can_act(), "can't act")


func test_cant_stand_on_one_leg_without_arms() -> void:
	var u := mech("hunchback_hbk4g", 0, hex_at(1, 1))
	u.prone = true
	u.structure[Location.LL] = 0
	check(Psr.can_stand(u), "one leg, arms intact: may try (p. 51)")
	u.structure[Location.LA] = 0
	check(Psr.can_stand(u), "one leg, one arm: may try")
	u.structure[Location.RA] = 0
	check(not Psr.can_stand(u), "one leg and no arms: can't")
	u.structure[Location.LL] = 5
	check(Psr.can_stand(u), "two legs, no arms: may try")


func test_tries_to_stand_again_with_spare_mp() -> void:
	var s := GameState.new(open_map(5, 5))
	var u := mech("hunchback_hbk4g", 0, hex_at(2, 2), 0, 1)
	s.add_unit(u)
	u.prone = true
	events.clear()
	var dice := LoadedDice.new()
	dice.queue_2d6(2)  # first try fails; then 6s: the fall, a second try that works
	check(MoveExecutor.run(s, dice, _emit, u, MoveOptions.key(u.coord, 3), MoveMode.Kind.WALK, -1))
	var stands := events.filter(func(e: Array) -> bool: return e[0] == GameEvent.STAND)
	check_eq(stands.size(), 2, "4 walking MP: 2 for the first try, 2 spare for another (p. 51)")
	check(not u.prone and u.facing == 3, "up on the second try")
	var v := mech("hunchback_hbk4g", 0, hex_at(0, 0), 0, 2)
	s.add_unit(v)
	v.prone = true
	events.clear()
	dice = LoadedDice.new()
	dice.queue_2d6(2)
	var far := MoveOptions.key(Hex.neighbor(v.coord, 2), 2)
	MoveExecutor.run(s, dice, _emit, v, far, MoveMode.Kind.WALK, -1)
	check_eq(events.filter(func(e: Array) -> bool: return e[0] == GameEvent.STAND).size(), 1, "no spare MP left after the planned move: one try")
