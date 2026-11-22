extends TestCase
## iNarc missile beacons (book p. 188): Narc rules, longer range, 3-point pods.

var events: Array[GameEvent] = []


func _emit(t: StringName, d: Dictionary) -> void:
	events.append(GameEvent.new(t, d))


func _def(id: String, eq: Dictionary) -> UnitDef:
	return UnitDef.from_dict({"id": id, "name": id, "tonnage": 50, "walk_mp": 4,
			"armor": {"CT": 20, "LT": 20, "RT": 20, "LA": 16, "RA": 16, "LL": 20, "RL": 20, "HD": 9},
			"equipment": eq}, weapons())


func test_inarc_stats() -> void:
	var d := weapons().get_def("inarc_beacon")
	check(d.beacon, "a missile beacon")
	check_eq([d.short_range, d.medium_range, d.long_range], [4, 9, 15], "ranges p. 250")
	check_eq(AmmoBin.new(d, 0).explosion_damage(), 12, "4 pods x 3")


func test_inarc_pod_homes_narc_missiles() -> void:
	var s := GameState.new(open_map(16, 4))
	s.turn = 1
	var n := Unit.new(1, _def("n", {"RA": ["inarc_beacon"], "RT": ["ammo:inarc_beacon"]}), 0, hex_at(1, 1), 2)
	var l := Unit.new(2, _def("l", {"LT": ["lrm10", "ammo:lrm10:narc"]}), 0, hex_at(1, 2), 2)
	var t := Unit.new(3, _def("t", {}), 1, hex_at(11, 2), 5)
	for u in [n, l, t]:
		s.add_unit(u)
	var th := ToHitCalc.weapon(s, n, n.weapons[0], t)
	check(th.possible(), "10 hexes: in iNarc range, out of a Narc's: " + th.impossible)
	var dice := LoadedDice.new()
	dice.queue_2d6(12)
	dice.queue_2d6(7)
	WeaponFire.resolve(s, dice, _emit, n, n.weapons[0], t, th)
	check_eq(t.narc_pods.size(), 1, "pod attached")
	s.turn = 2
	check(ToHitCalc.weapon(s, l, l.weapons[0], t).narc_homing, "Narc-equipped LRMs home on it")


func test_designs_carry_inarc() -> void:
	var k := mech("kintaro_kto21", 0, hex_at(0, 0))
	check(k.weapons.any(func(w: MountedWeapon) -> bool: return w.def.id == "inarc_beacon"), "Kintaro KTO-21 carries iNarc")
	check(k.weapons.any(func(w: MountedWeapon) -> bool: return w.narc_ammo), "and Narc-equipped SRMs")
