extends TestCase
## CASE II (1 structure, up to 10 armor, -1 critical check) and the
## snub-nose PPC's variable damage.


func _unit(eq: Dictionary, tech := "inner_sphere") -> Unit:
	var d := UnitDef.from_dict({"id": "t", "name": "Test", "tonnage": 50, "walk_mp": 4, "tech_base": tech,
			"armor": {"HD": 9, "CT": 20, "LT": 10, "RT": 10, "LA": 8, "RA": 8, "LL": 10, "RL": 10},
			"rear_armor": {"CT": 5, "LT": 10, "RT": 4}, "equipment": eq}, weapons())
	return Unit.new(1, d, 0, hex_at(0, 1), 2)


func test_case_ii_caps_structure_at_one() -> void:
	var u := _unit({"LT": ["ammo:ac20", "case2"]})
	var lt := u.structure[Location.LT]
	var ct := u.structure[Location.CT]
	var steps := AmmoExplosion.internal(u, Location.LT, 100)
	check_eq(steps.size(), 1, "nothing transfers")
	check_eq(int(steps[0]["structure"]), 1)
	check_eq(int(steps[0]["armor"]), 10, "10 more to rear armor")
	check_eq(u.structure[Location.LT], lt - 1)
	check_eq(u.rear_armor[Location.LT], 0)
	check_eq(u.armor[Location.LT], 10, "front armor untouched")
	check_eq(u.structure[Location.CT], ct)
	check_eq(DesignWeight.breakdown(u.def)["case"], 1.0, "Inner Sphere CASE II weighs 1 t")
	check_eq(DesignWeight.breakdown(_unit({"LT": ["case2"]}, "clan").def)["case"], 0.5, "Clan 0.5 t")


func test_case_ii_softens_the_critical_check() -> void:
	var s := GameState.new(open_map(4, 3))
	var u := _unit({"LT": ["ammo:ac10", "case2"], "RT": ["ac10"]})
	s.add_unit(u)
	var dice := LoadedDice.new()
	dice.queue_2d6(8)  # would be one critical; CASE II makes it 7
	var checks := []
	AmmoExplosion.explode(s, dice, func(t: StringName, e: Dictionary) -> void:
		if t == GameEvent.CRIT_CHECK:
			checks.append(e), u, u.ammo[0])
	check_eq(checks.size(), 1)
	check_eq([checks[0]["roll"], checks[0]["crits"]], [7, 0])
	check_eq(u.pilot.hits, 1, "the feedback still hurts the MechWarrior")


func test_snub_nose_damage_falls_off() -> void:
	var w := weapons().get_def("snub_nose_ppc")
	check_eq([w.damage_at(9), w.damage_at(10), w.damage_at(13), w.damage_at(15)], [10, 8, 8, 5])
	check_eq(w.damage_at(11, 1), 5, "under water medium range deals long-range damage")
	check_eq(weapons().get_def("ppc").damage_at(15), 10, "fixed damage elsewhere")


func test_snub_nose_shot_uses_range_damage() -> void:
	var s := GameState.new(open_map(14, 3))
	var a := _unit({"RA": ["snub_nose_ppc"]})
	var t := Unit.new(2, make_def(4), 1, hex_at(11, 1), 5)
	s.add_unit(a)
	s.add_unit(t)
	var dice := LoadedDice.new()
	dice.queue_2d6(12)  # hit
	dice.queue_2d6(7)  # center torso
	var ev := []
	WeaponFire.resolve(s, dice, func(ty: StringName, e: Dictionary) -> void: ev.append([ty, e]), a, a.weapons[0], t,
			ToHitCalc.weapon(s, a, a.weapons[0], t))
	var dmg := ev.filter(func(e: Array) -> bool: return e[0] == GameEvent.DAMAGE).map(func(e: Array) -> int: return e[1]["amount"])
	check_eq(dmg, [8], "11 hexes is medium range: 8 damage")
