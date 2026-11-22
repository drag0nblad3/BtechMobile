extends TestCase
## Apollo saturation mode (ApolloSaturation, p. 197).


func _def(id: String, eq: Dictionary) -> UnitDef:
	return UnitDef.from_dict({"id": id, "name": id, "tonnage": 50, "walk_mp": 4,
			"armor": {"CT": 20, "LT": 20, "RT": 20, "LA": 16, "RA": 16, "LL": 20, "RL": 20, "HD": 9},
			"equipment": eq}, weapons())


func _total_armor(u: Unit) -> int:
	var n := 0
	for a in u.armor:
		n += a
	for a in u.rear_armor:
		n += a
	return n


func test_mode_and_to_hit() -> void:
	var s := GameState.new(open_map(16, 4))
	var a := Unit.new(1, _def("a", {"RT": ["mrm30+apollo", "ammo:mrm30"]}), 0, hex_at(1, 2), 2)
	var t := Unit.new(2, _def("t", {}), 1, hex_at(4, 2), 5)
	s.add_unit(a)
	s.add_unit(t)
	var w := a.weapons[0]
	check(WeaponModes.modes(w).has(ApolloSaturation.MODE), "Apollo offers saturation")
	t.move_mode = MoveMode.Kind.RUN
	t.hexes_moved = 6
	w.mode = ApolloSaturation.MODE
	var th := ToHitCalc.weapon(s, a, w, t)
	check(th.possible(), th.impossible)
	check(not th.mods.any(func(m: Dictionary) -> bool: return String(m["label"]).begins_with("target")), "target movement doesn't count")
	w.apollo_lost = true
	check(not WeaponModes.modes(w).has(ApolloSaturation.MODE), "no saturation once Apollo is hit")


func test_hits_everyone_in_the_hex() -> void:
	var s := GameState.new(open_map(16, 4))
	var a := Unit.new(1, _def("a", {"RT": ["mrm30+apollo", "ammo:mrm30"]}), 0, hex_at(1, 2), 2)
	var t := Unit.new(2, _def("t", {}), 1, hex_at(4, 2), 5)
	var f := Unit.new(3, _def("f", {}), 0, hex_at(4, 2), 5)  # a friend in the same hex
	for u in [a, t, f]:
		s.add_unit(u)
	var w := a.weapons[0]
	w.mode = ApolloSaturation.MODE
	var th := ToHitCalc.weapon(s, a, w, t)
	var dice := LoadedDice.new()
	dice.queue_2d6(12)  # to hit
	dice.queue_2d6(7)  # cluster: 18 of 30 -> 6 damage
	var t0 := _total_armor(t)
	var f0 := _total_armor(f)
	var events := []
	WeaponFire.resolve(s, dice, func(ty: Variant, d: Dictionary) -> void: events.append([ty, d]), a, w, t, th)
	check_eq(t0 - _total_armor(t), 6, "6 damage to the target")
	check_eq(f0 - _total_armor(f), 6, "and to the friend in the hex")
	check_eq(events[0][1]["saturation_damage"], 6)
