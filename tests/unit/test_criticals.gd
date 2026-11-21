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


func test_autocannon_survives_first_crit() -> void:
	var u := mech("hunchback_hbk4g", 0, hex_at(1, 1))
	var s := _state_with(u)
	var dice := LoadedDice.new()
	dice.queue_2d6(8)       # one critical
	dice.pick_queue = [0]   # first hittable RT slot: AC/20
	CriticalHits.roll_location(s, dice, _emit, u, Location.RT)
	check(not gun(u, "ac20").destroyed, "AC/20 still fires after its first critical (p. 183)")
	check(u.slots[Location.RT][0].hit, "the slot is marked")
	dice.queue_2d6(8)
	dice.pick_queue = [0]   # the next AC/20 slot
	CriticalHits.roll_location(s, dice, _emit, u, Location.RT)
	check(gun(u, "ac20").destroyed, "second critical disables it")


func test_one_slot_autocannon_needs_two_hits() -> void:
	var d := UnitDef.from_dict({"id": "a", "name": "a", "tonnage": 50, "walk_mp": 4,
			"armor": {"CT": 20}, "equipment": {"LA": ["ac2"]}}, weapons())
	var u := Unit.new(1, d, 0, hex_at(1, 1), 0)
	var s := _state_with(u)
	var slot: CritSlot = u.slots[Location.LA].filter(func(c: CritSlot) -> bool: return c.kind == CritSlot.Kind.WEAPON)[0]
	CriticalHits.hit_slot(s, LoadedDice.new(), _emit, u, Location.LA, slot)
	check(not u.weapons[0].destroyed, "first hit: AC/2 works")
	check(AutocannonCrit.rehittable(u, slot), "its one slot can be hit again")
	CriticalHits.hit_slot(s, LoadedDice.new(), _emit, u, Location.LA, slot)
	check(u.weapons[0].destroyed, "second hit on the same slot disables it")
	check(not AutocannonCrit.rehittable(u, slot), "then the slot is done")


func test_other_weapons_die_on_first_crit() -> void:
	var u := mech("hunchback_hbk4g", 0, hex_at(1, 1))
	var s := _state_with(u)
	for i in u.weapons.size():
		if not AutocannonCrit.is_autocannon(u.weapons[i].def):
			var w: MountedWeapon = u.weapons[i]
			var slot: CritSlot = u.slots[w.loc].filter(func(c: CritSlot) -> bool:
					return c.kind == CritSlot.Kind.WEAPON and c.ref == i)[0]
			CriticalHits.hit_slot(s, LoadedDice.new(), _emit, u, w.loc, slot)
			check(w.destroyed, w.def.name)
			return


func test_autocannon_ids() -> void:
	for id in ["ac2", "ac20", "ultra_ac5", "rotary_ac2", "lb10x_ac", "c_lb2x_ac", "c_ultra_ac20"]:
		check(AutocannonCrit.is_autocannon(weapons().get_def(id)), id)
	for id in ["gauss_rifle", "machine_gun", "c_atm3", "large_laser"]:
		check(not AutocannonCrit.is_autocannon(weapons().get_def(id)), id)


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
	check_eq(Psr.standing_mods(g).target(), 7, "5 piloting + 2 gyro")


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


func test_disarmed_and_immobile_is_destroyed() -> void:
	var u := mech("hunchback_hbk4g", 0, hex_at(1, 1))
	var s := _state_with(u)
	for w in u.weapons:
		w.destroyed = true
	EndPhase.run(s, LoadedDice.new(), _emit)
	check(not u.destroyed, "no weapons but still mobile: fights on (p. 99)")
	u.shutdown = true
	EndPhase.run(s, LoadedDice.new(), _emit)
	check(u.destroyed, "no weapons and immobile: destroyed")
	check(events.any(func(e: Array) -> bool: return e[0] == GameEvent.UNIT_DESTROYED), "announced")
	var v := mech("hunchback_hbk4g", 0, hex_at(1, 1))
	v.shutdown = true
	check(not Disarmed.check(v), "shut down with guns: not destroyed")
