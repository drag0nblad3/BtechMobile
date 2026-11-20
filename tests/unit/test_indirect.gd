extends TestCase
## Indirect LRM fire over a hill, called by a friendly spotter.


func _setup(with_spotter: bool) -> Array:
	var rows := []
	for r in 10:
		rows.append("c0 c0 c3 c0 c0" if r == 5 else "c0 c0 c0 c0 c0")
	var s := GameState.new(make_map(rows))
	var a := mech("catapult_cplt_c1", 0, hex_at(2, 9), 0, 1)
	var t := mech("hunchback_hbk4g", 1, hex_at(2, 1), 3, 2)
	s.add_unit(a)
	s.add_unit(t)
	if with_spotter:
		var sp := mech("jenner_jr7d", 0, hex_at(0, 2), 0, 3)
		sp.move_mode = MoveMode.Kind.RUN
		s.add_unit(sp)
	return [s, a, t]


func _lrm(u: Unit) -> MountedWeapon:
	for w in u.weapons:
		if w.def.indirect:
			return w
	return null


func test_blocked_without_spotter() -> void:
	var r := _setup(false)
	var th := ToHitCalc.weapon(r[0], r[1], _lrm(r[1]), r[2])
	check(not th.possible(), "hill blocks")
	check(th.impossible.contains("spot"), "says a spotter would help: " + th.impossible)


func test_spotter_allows_lrms_only() -> void:
	var r := _setup(true)
	var s: GameState = r[0]
	var a: Unit = r[1]
	var th := ToHitCalc.weapon(s, a, _lrm(a), r[2])
	check(th.possible(), "spotted shot allowed: " + th.impossible)
	var labels := []
	for m in th.mods:
		labels.append(m["label"])
	check(labels.has("indirect fire"), "+1 indirect")
	check(labels.has("spotter ran"), "spotter's running counts")
	for w in a.weapons:
		if not w.def.indirect:
			check(not ToHitCalc.weapon(s, a, w, r[2]).possible(), w.def.name + " needs line of sight")
	# Spotter shooting too adds +1.
	s.declared_fire.append({"attacker_id": 3, "weapon_index": 0, "target_id": 2})
	var th2 := ToHitCalc.weapon(s, a, _lrm(a), r[2])
	check_eq(th2.target(), th.target() + 1, "spotter firing +1")
