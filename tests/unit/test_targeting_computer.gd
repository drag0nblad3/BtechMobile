extends TestCase
## Targeting computers (p. 200).


func _setup(with_tc: bool) -> Array:
	var s := GameState.new(open_map(10, 4))
	var eq := {"RA": ["large_laser", "medium_pulse_laser"], "LA": ["lrm10"], "LT": ["ammo:lrm10"]}
	if with_tc:
		eq["RT"] = ["targeting_computer"]
	var d := UnitDef.from_dict({"id": "tc", "name": "TC", "tonnage": 60, "walk_mp": 4,
			"armor": {"CT": 20}, "equipment": eq}, weapons())
	var a := Unit.new(1, d, 0, hex_at(1, 2), 2)
	var t := mech("atlas_as7d", 1, hex_at(4, 2), 5, 2)
	s.add_unit(a)
	s.add_unit(t)
	return [s, a, t]


func test_size_and_slots() -> void:
	var v := _setup(true)
	var a: Unit = v[1]
	check_eq(TargetingComputer.size(a.def), 2, "large laser 5 t + pulse 2 t = 7 t: 2")
	check_eq(DesignWeight.breakdown(a.def)["targeting_computer"], 2.0)
	var n := 0
	for s: CritSlot in a.slots[Location.RT]:
		if s.kind == CritSlot.Kind.TARGETING:
			n += 1
	check_eq(n, 2)


func test_minus_one_for_linked_weapons() -> void:
	var plain := _setup(false)
	var v := _setup(true)
	for i in 3:
		var before := ToHitCalc.weapon(plain[0], plain[1], plain[1].weapons[i], plain[2]).target()
		var after := ToHitCalc.weapon(v[0], v[1], v[1].weapons[i], v[2]).target()
		var linked: bool = v[1].weapons[i].def.id != "lrm10"
		check_eq(after, before - (1 if linked else 0), v[1].weapons[i].def.name)
	var a: Unit = v[1]
	CritEffects.apply(v[0], LoadedDice.new(), func(_t: Variant, _d: Dictionary) -> void: pass, a, Location.RT,
			a.slots[Location.RT].filter(func(s: CritSlot) -> bool: return s.kind == CritSlot.Kind.TARGETING)[0])
	check_eq(ToHitCalc.weapon(v[0], a, a.weapons[0], v[2]).target(),
			ToHitCalc.weapon(plain[0], plain[1], plain[1].weapons[0], plain[2]).target(), "destroyed: no bonus")


func test_aimed_shot_at_moving_target() -> void:
	var v := _setup(true)
	var s: GameState = v[0]
	var a: Unit = v[1]
	var t: Unit = v[2]
	var normal: ToHit = FireOptions.declare(s, a, [{"weapon": 0, "target_id": t.id}])[0]["to_hit"]
	var aimed: ToHit = FireOptions.declare(s, a, [{"weapon": 0, "target_id": t.id, "aim": Location.CT}])[0]["to_hit"]
	check_eq(aimed.aim_loc, Location.CT)
	check_eq(aimed.target(), normal.target() + 1 + 3, "lose the -1, take +3")
	var head: ToHit = FireOptions.declare(s, a, [{"weapon": 0, "target_id": t.id, "aim": Location.HEAD}])[0]["to_hit"]
	check_eq(head.aim_loc, -1, "no head shots on a moving target")
	var pulse: ToHit = FireOptions.declare(s, a, [{"weapon": 1, "target_id": t.id, "aim": Location.CT}])[0]["to_hit"]
	check_eq(pulse.aim_loc, -1, "pulse can't aim at a moving target")
	check(not AimPicker.available(_setup(false)[1], t), "no computer, moving target: no aim button")
	check(AimPicker.available(a, t))


func _mounted(id: String) -> MountedWeapon:
	return MountedWeapon.new(weapons().get_def(id), Location.RA, false)


func test_links_rapid_fire_but_no_machine_guns() -> void:
	for id in ["machine_gun", "c_light_machine_gun", "c_machine_gun", "c_heavy_machine_gun", "c_er_flamer"]:
		check(not TargetingComputer.linked(_mounted(id)), "%s isn't linked" % id)
	var uac := _mounted("ultra_ac5")
	uac.mode = WeaponModes.ULTRA
	check(TargetingComputer.linked(uac), "rapid-firing Ultra keeps the -1")
	var rac := _mounted("rotary_ac5")
	rac.mode = "x6"
	check(TargetingComputer.linked(rac), "rapid-firing rotary keeps the -1")
	var lbx := _mounted("lb10x_ac")
	lbx.mode = WeaponModes.CLUSTER
	check(not TargetingComputer.linked(lbx), "LB-X cluster rounds aren't linked")
