extends TestCase
## Advanced Tactical Missiles (Atm, p. 186): three munitions, built-in Artemis.


func _setup(dist: int, kinds: Array = ["", "er", "he"]) -> Array:
	var s := GameState.new(open_map(30, 4))
	var eq := ["c_atm6"]
	for k: String in kinds:
		eq.append("ammo:c_atm6" + (":" + k if k != "" else ""))
	var d := UnitDef.from_dict({"id": "a", "name": "a", "tonnage": 50, "walk_mp": 4, "tech_base": "clan",
			"armor": {"CT": 20}, "equipment": {"RT": eq}}, weapons())
	var a := Unit.new(1, d, 0, hex_at(1, 2), 2)
	var t := Unit.new(2, make_def(4), 1, hex_at(1 + dist, 2), 5)
	for i in t.armor.size():
		t.armor[i] = 99
	s.add_unit(a)
	s.add_unit(t)
	return [s, a, t]


func _fire(v: Array, rolls: Array) -> Array:
	var a: Unit = v[1]
	var dice := LoadedDice.new()
	for r: int in rolls:
		dice.queue_2d6(r)
	var ev := []
	WeaponFire.resolve(v[0], dice, func(ty: StringName, e: Dictionary) -> void: ev.append([ty, e]),
			a, a.weapons[0], v[2], ToHitCalc.weapon(v[0], a, a.weapons[0], v[2]))
	return ev


func test_munitions_and_modes() -> void:
	var v := _setup(3)
	var w: MountedWeapon = v[1].weapons[0]
	check_eq(WeaponModes.modes(w), ["", "er", "he"] as Array[String])
	check(w.def.artemis_builtin and WeaponModes.has_artemis(w), "Artemis built in")
	check_eq(w.def.munitions["er"].long_range, 27)
	check_eq(w.def.munitions["he"].damage, 3)
	var th := ToHitCalc.weapon(v[0], v[1], w, v[2])
	check(th.mods.any(func(m: Dictionary) -> bool: return m["label"] == "minimum range"), "standard: 4-hex minimum")
	w.mode = Atm.HE
	th = ToHitCalc.weapon(v[0], v[1], w, v[2])
	check(not th.mods.any(func(m: Dictionary) -> bool: return m["label"] == "minimum range"), "HE: none")
	check_eq(WeaponModes.ammo_kind(w), Atm.HE)
	var far := _setup(20)
	check(not ToHitCalc.weapon(far[0], far[1], far[1].weapons[0], far[2]).possible(), "standard reaches 15")
	far[1].weapons[0].mode = Atm.ER
	check(ToHitCalc.weapon(far[0], far[1], far[1].weapons[0], far[2]).possible(), "ER reaches 27")


func test_he_hits_in_six_point_groups_with_artemis() -> void:
	var v := _setup(5)
	var w: MountedWeapon = v[1].weapons[0]
	w.mode = Atm.HE
	var ev := _fire(v, [12, 8, 7, 7, 7, 7, 7, 7])
	var fired: Dictionary = ev.filter(func(e: Array) -> bool: return e[0] == GameEvent.WEAPON_FIRED)[0][1]
	check_eq(fired["cluster_bonus"], 2, "Artemis +2")
	var n := ClusterTable.hits(6, 10)
	check_eq(fired["missiles"], n)
	var dmg := ev.filter(func(e: Array) -> bool: return e[0] == GameEvent.DAMAGE).map(func(e: Array) -> int: return e[1]["amount"])
	check_eq(dmg.reduce(func(t: int, x: int) -> int: return t + x, 0), n * 3, "3 a missile")
	check(dmg.all(func(x: int) -> bool: return x <= 6), "6-point groups")
	check_eq(v[1].ammo_for(w.def, Atm.HE), 9, "HE bin used")
	check_eq(v[1].ammo_for(w.def), 10, "standard bin untouched")


func test_starts_on_ammo_it_has_and_bot_picks_by_range() -> void:
	var only_er := _setup(3, ["er"])
	check_eq(only_er[1].weapons[0].mode, Atm.ER)
	check_eq(WeaponModes.modes(only_er[1].weapons[0]), [""] as Array[String], "one munition: no choice")
	var near := _setup(2)
	BotModes.apply(near[0], near[1], near[2], false)
	check_eq(near[1].weapons[0].mode, Atm.HE, "close in: high explosive")
	var far := _setup(20)
	BotModes.apply(far[0], far[1], far[2], false)
	check_eq(far[1].weapons[0].mode, Atm.ER, "far away: extended range")
