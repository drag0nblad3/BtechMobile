extends TestCase
## C3 computer networks (book pp. 198-199, BV p. 222).


func _def(id: String, item: String) -> UnitDef:
	var eq := {"RA": ["medium_laser", "ppc"]}
	if item != "":
		eq["RT"] = [item]
	return UnitDef.from_dict({"id": id, "name": id, "tonnage": 50, "walk_mp": 4,
			"armor": {"HD": 9, "CT": 20, "LT": 15, "RT": 15, "LA": 10, "RA": 10, "LL": 15, "RL": 15},
			"equipment": eq}, weapons())


## Master at row 8, slave at row 2 near the target at row 0; all facing north.
func _setup() -> Array:
	var s := GameState.new(open_map(5, 16))
	var m := Unit.new(1, _def("m", "c3_master"), 0, hex_at(2, 12), 0)
	var sl := Unit.new(2, _def("s", "c3_slave"), 0, hex_at(2, 4), 0)
	var t := Unit.new(3, _def("t", ""), 1, hex_at(2, 1), 3)
	for u in [m, sl, t]:
		s.add_unit(u)
	return [s, m, sl, t]


func _ppc(u: Unit) -> MountedWeapon:
	return u.weapons.filter(func(w: MountedWeapon) -> bool: return w.def.id == "ppc")[0]


func _has(th: ToHit, label: String) -> bool:
	return th.mods.any(func(m: Dictionary) -> bool: return m["label"] == label)


func test_items_slots_weight() -> void:
	var d := _def("m", "c3_master")
	check(C3.is_master(d))
	check_eq(DesignWeight.breakdown(d)["c3"], 5.0)
	check_eq(DesignWeight.breakdown(_def("s", "c3_slave"))["c3"], 1.0)
	var u := Unit.new(1, d, 0, Vector2i.ZERO, 0)
	check_eq(u.slots[Location.RT].filter(func(sl: CritSlot) -> bool: return sl.kind == CritSlot.Kind.C3).size(), 5)


func test_network_forms() -> void:
	var m := _def("m", "c3_master")
	var sl := _def("s", "c3_slave")
	var none := _def("n", "")
	check_eq(C3.form([none, sl, m, sl, sl, sl]), [2, 1, 3, 4] as Array[int], "a Master and three Slaves")
	check_eq(C3.form([m, none]), [] as Array[int], "one 'Mech is not a network")
	check_eq(C3.form([sl, sl]), [] as Array[int], "Slaves need a Master")
	check_eq(C3.form([m, m, sl]), [0, 2] as Array[int], "a Master links Slaves or Masters, not both")
	check_eq(C3.bv_percent(2), 10)
	check_eq(C3.bv_percent(4), 20)
	check_eq(C3.bv_percent(9), 40)


func test_master_uses_slave_range() -> void:
	var r := _setup()
	var th := ToHitCalc.weapon(r[0], r[1], _ppc(r[1]), r[3])
	check(th.possible(), th.summary())
	check(_has(th, "C3 network"), th.summary())
	check(not _has(th, "long range") and not _has(th, "medium range"), "3 hexes from the Slave: short range")
	var ml: MountedWeapon = r[1].weapons.filter(func(w: MountedWeapon) -> bool: return w.def.id == "medium_laser")[0]
	check(not ToHitCalc.weapon(r[0], r[1], ml, r[3]).possible(), "maximum range still counts from the shooter")


func test_ppc_minimum_range_uses_own_distance() -> void:
	var r := _setup()
	var th := ToHitCalc.weapon(r[0], r[2], _ppc(r[2]), r[3])
	check(_has(th, "minimum range"), "the Slave is 3 hexes away: inside the PPC's minimum range")


func test_network_down_without_master() -> void:
	var r := _setup()
	r[1].destroyed = true
	check(C3.network(r[0], r[2]).is_empty())
	r[1].destroyed = false
	for s: CritSlot in r[1].slots[Location.RT]:
		if s.kind == CritSlot.Kind.C3:
			s.hit = true
	check(not _has(ToHitCalc.weapon(r[0], r[1], _ppc(r[1]), r[3]), "C3 network"), "wrecked Master: no network")


func test_hostile_ecm_degrades() -> void:
	var r := _setup()
	var jam := Unit.new(4, UnitDef.from_dict({"id": "e", "name": "e", "tonnage": 50, "walk_mp": 4,
			"equipment": {"LT": ["guardian_ecm"]}}, weapons()), 1, hex_at(0, 6), 3)
	r[0].add_unit(jam)
	var th := ToHitCalc.weapon(r[0], r[1], _ppc(r[1]), r[3])
	check(_has(th, "ECM vs C3"), th.summary())
	var ecm: Dictionary = th.mods.filter(func(m: Dictionary) -> bool: return m["label"] == "ECM vs C3")[0]
	check_eq(ecm["value"], 1, "medium (11 hexes) to short through a jammed Slave: +1")


func test_force_bv() -> void:
	var db := UnitDb.new()
	var fb := ForceBuilder.new(db)
	check(fb.bv(0) == 0)
