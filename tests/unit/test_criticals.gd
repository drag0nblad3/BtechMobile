extends TestCase
## Critical hits and their effects.

var events: Array = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append([t, d])


func _state_with(u: Unit) -> GameState:
	var s := GameState.new(open_map(3, 3))
	s.add_unit(u)
	return s


func test_crit_table() -> void:
	check_eq(CriticalHits.crits_for_roll(7), 0)
	check_eq(CriticalHits.crits_for_roll(8), 1)
	check_eq(CriticalHits.crits_for_roll(11), 2)
	check_eq(CriticalHits.crits_for_roll(12), 3)


func test_weapon_crit_destroys_weapon() -> void:
	var u := mech("hunchback_hbk4g", 0, hex_at(1, 1))
	var s := _state_with(u)
	var dice := LoadedDice.new()
	dice.queue_2d6(8)       # one critical
	dice.pick_queue = [0]   # first hittable RT slot: AC/20
	CriticalHits.roll_location(s, dice, _emit, u, Location.RT)
	check(u.weapons[1].destroyed, "AC/20 destroyed")


func test_engine_and_gyro() -> void:
	var u := mech("hunchback_hbk4g", 0, hex_at(1, 1))
	var s := _state_with(u)
	var dice := LoadedDice.new()
	for i in 3:
		dice.queue_2d6(8)
		dice.pick_queue.append(0)  # always the first engine slot left
		CriticalHits.roll_location(s, dice, _emit, u, Location.CT)
	check_eq(u.engine_hits, 3)
	check(u.destroyed, "three engine hits destroy")
	var g := mech("hunchback_hbk4g", 0, hex_at(1, 1))
	s = _state_with(g)
	dice.queue_2d6(8)
	dice.pick_queue.append(3)  # Gyro (after 3 engine slots)
	CriticalHits.roll_location(s, dice, _emit, g, Location.CT)
	check_eq(g.gyro_hits, 1)
	check_eq(g.psr_pending.size(), 1, "gyro hit owes a piloting roll")
	check_eq(Psr.standing_mods(g).target(), 8, "5 piloting + 3 gyro")


func test_limb_blown_off() -> void:
	var u := mech("atlas_as7d", 0, hex_at(1, 1))
	var s := _state_with(u)
	var dice := LoadedDice.new()
	dice.queue_2d6(12)
	CriticalHits.roll_location(s, dice, _emit, u, Location.LA)
	check(u.is_location_destroyed(Location.LA), "arm blown off")
	check(u.weapons[3].destroyed or u.weapons.any(func(w): return w.loc == Location.LA and w.destroyed), "arm laser gone")


func test_ammo_crit_explodes() -> void:
	var u := mech("hunchback_hbk4g", 0, hex_at(1, 1))
	var s := _state_with(u)
	var dice := LoadedDice.new()
	dice.queue_2d6(8)
	dice.pick_queue = [0]  # LT slot 0: AC/20 ammo
	CriticalHits.roll_location(s, dice, _emit, u, Location.LT)
	check(u.is_location_destroyed(Location.LT), "ammo explosion guts LT")
	check(u.is_location_destroyed(Location.LA), "and the arm with it")


func test_breach_triggers_check() -> void:
	var u := mech("jenner_jr7d", 0, hex_at(1, 1))
	var s := _state_with(u)
	var dice := LoadedDice.new()
	var steps := Damage.apply(u, Location.LL, 13)  # 12 armor + 1 structure
	dice.queue_2d6(7)
	events.clear()
	CriticalHits.after_damage(s, dice, _emit, u, steps, false)
	check_eq(events.size(), 1, "one crit check")
	check_eq(events[0][0], GameEvent.CRIT_CHECK)
