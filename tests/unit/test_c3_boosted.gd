extends TestCase
## Boosted C3 (p. 199): ignores Guardian ECM, except through a standard Master.


func _def(id: String, item: String) -> UnitDef:
	var eq := {"RA": ["medium_laser", "ppc"]}
	if item != "":
		eq["RT"] = [item]
	return UnitDef.from_dict({"id": id, "name": id, "tonnage": 50, "walk_mp": 4,
			"armor": {"HD": 9, "CT": 20, "LT": 15, "RT": 15, "LA": 10, "RA": 10, "LL": 15, "RL": 15},
			"equipment": eq}, weapons())


## Master at row 12, Slave at row 4 near the target at row 1; a jammer at `jam`.
func _setup(master: String, slave: String, jam: Vector2i) -> Array:
	var s := GameState.new(open_map(5, 16))
	var m := Unit.new(1, _def("m", master), 0, hex_at(2, 12), 0)
	var sl := Unit.new(2, _def("s", slave), 0, hex_at(2, 4), 0)
	var t := Unit.new(3, _def("t", ""), 1, hex_at(2, 1), 3)
	var e := Unit.new(4, _def("e", "guardian_ecm"), 1, jam, 3)
	for u in [m, sl, t, e]:
		s.add_unit(u)
	return [s, m, sl, t]


func _ecm(r: Array) -> int:
	var m: Unit = r[1]
	var ppc: MountedWeapon = m.weapons.filter(func(w: MountedWeapon) -> bool: return w.def.id == "ppc")[0]
	var th := ToHitCalc.weapon(r[0], m, ppc, r[3])
	check(th.mods.any(func(x: Dictionary) -> bool: return x["label"] == "C3 network"), "the network helps: " + th.summary())
	var mods := th.mods.filter(func(x: Dictionary) -> bool: return x["label"] == "ECM vs C3")
	return 0 if mods.is_empty() else mods[0]["value"]


func test_sizes() -> void:
	var sl := _def("s", "c3bs_slave")
	check(sl.c3_boosted and C3.has(sl))
	check_eq(DesignWeight.breakdown(sl)["c3"], 3.0)
	var u := Unit.new(1, _def("m", "c3bs_master"), 0, Vector2i.ZERO, 0)
	check_eq(u.slots[Location.RT].filter(func(c: CritSlot) -> bool: return c.kind == CritSlot.Kind.C3).size(), 6)
	check_eq(DesignWeight.breakdown(u.def)["c3"], 6.0)


func test_boosted_network_shrugs_off_guardian_ecm() -> void:
	check_eq(_ecm(_setup("c3bs_master", "c3bs_slave", hex_at(0, 5))), 0, "jammer next to the boosted Slave")
	check_eq(_ecm(_setup("c3_master", "c3_slave", hex_at(0, 5))), 1, "a standard Slave is degraded: +1 for one bracket")


func test_standard_master_degrades_boosted_members() -> void:
	check_eq(_ecm(_setup("c3_master", "c3bs_slave", hex_at(0, 13))), 1, "jammer by the standard Master")
	check_eq(_ecm(_setup("c3_master", "c3bs_slave", hex_at(0, 5))), 0, "jammer by the boosted Slave only")
