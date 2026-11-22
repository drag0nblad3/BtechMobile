extends TestCase
## Angel ECM, Watchdog CEWS and improved C3 (C3i).


func _unit(eq: Dictionary, uid := 1, side := 0, at := Vector2i.ZERO, tech := "inner_sphere") -> Unit:
	var d := UnitDef.from_dict({"id": "t%d" % uid, "name": "Test", "tonnage": 50, "walk_mp": 4, "tech_base": tech,
			"armor": {"HD": 9, "CT": 20, "LT": 10, "RT": 10, "LA": 8, "RA": 8, "LL": 10, "RL": 10},
			"equipment": eq}, weapons())
	return Unit.new(uid, d, side, at, 2)


func test_suite_sizes_and_bv() -> void:
	var a := _unit({"LT": ["angel_ecm"]}).def
	check_eq([Ecm.tons(a), Ecm.slots(a), EcmTypes.bv(a)], [2.0, 2, 100.0])
	var w := _unit({"LT": ["watchdog_ecm"]}, 1, 0, Vector2i.ZERO, "clan").def
	check_eq([Ecm.tons(w), Ecm.slots(w), EcmTypes.bv(w)], [1.5, 2, 68.0])
	check_eq(DesignWeight.breakdown(_unit({"LT": ["c3i"]}).def)["c3"], 2.5)


func test_watchdog_is_also_a_probe() -> void:
	var u := _unit({"LT": ["watchdog_ecm"]}, 1, 0, Vector2i.ZERO, "clan")
	check_eq(ActiveProbe.range_of(u.def), 5)
	check(ActiveProbe.working(u))
	u.ecm_lost = true
	check(not ActiveProbe.working(u), "one suite: a hit stops both")


func test_only_angel_degrades_boosted_c3() -> void:
	var s := GameState.new(open_map(10, 3))
	var me := _unit({"LT": ["c3bs_slave"]}, 1, 0, hex_at(0, 1))
	var guardian := _unit({"LT": ["guardian_ecm"]}, 2, 1, hex_at(3, 1))
	s.add_unit(me)
	s.add_unit(guardian)
	check(not C3Boosted.jammed(s, 0, me))
	var angel := _unit({"LT": ["angel_ecm"]}, 3, 1, hex_at(4, 1))
	s.add_unit(angel)
	check(C3Boosted.jammed(s, 0, me))


func test_c3i_network_shares_range() -> void:
	var s := GameState.new(open_map(16, 3))
	var a := _unit({"LT": ["c3i"], "RA": ["medium_laser"]}, 1, 0, hex_at(0, 1))
	var b := _unit({"LT": ["c3i"]}, 2, 0, hex_at(8, 1))
	var t := _unit({}, 3, 1, hex_at(9, 1))
	for u in [a, b, t]:
		s.add_unit(u)
	check_eq(C3.network(s, a).size(), 2)
	check(C3.network(s, t).is_empty())
	var th := ToHitCalc.weapon(s, a, a.weapons[0], t)
	check(th.mods.any(func(m: Dictionary) -> bool: return m["label"] == "C3 network"), th.summary())
	check_eq(C3.form([a.def, b.def, t.def]), [0, 1] as Array[int])
