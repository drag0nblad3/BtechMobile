extends TestCase
## Anti-missile systems (p. 206).


func _setup(eq: Array) -> Array:
	var s := GameState.new(open_map(10, 4))
	var a := mech("griffin_grf1n", 0, hex_at(1, 2), 2, 1)
	var d := UnitDef.from_dict({"id": "t", "name": "Target", "tonnage": 50, "walk_mp": 4,
			"armor": {"CT": 20, "LT": 20, "RT": 20, "LA": 16, "RA": 16, "LL": 20, "RL": 20, "HD": 9},
			"equipment": {"LT": eq}}, weapons())
	var t := Unit.new(2, d, 1, hex_at(4, 2), 5)
	s.add_unit(a)
	s.add_unit(t)
	return [s, a, t]


func _lrm(a: Unit) -> MountedWeapon:
	for w in a.weapons:
		if w.def.id == "lrm10":
			return w
	return null


func _fire(v: Array, rolls: Array) -> Dictionary:
	var s: GameState = v[0]
	var a: Unit = v[1]
	var t: Unit = v[2]
	var w := _lrm(a)
	var th := ToHitCalc.weapon(s, a, w, t, false)
	var out := {}
	var emit := func(type: Variant, d: Dictionary) -> void:
		if type == GameEvent.WEAPON_FIRED:
			out.merge(d, true)
	WeaponFire.resolve(s, LoadedDice.new(rolls), emit, a, w, t, th)
	return out


func test_ams_cuts_cluster_roll() -> void:
	var plain := _fire(_setup([]), [6, 6, 3, 3])
	check_eq(plain["missiles"], 6, "roll 6 on the LRM 10 column")
	var v := _setup(["ams", "ammo:ams"])
	var t: Unit = v[2]
	var hit := _fire(v, [6, 6, 3, 3])
	check(hit["ams"])
	check_eq(hit["missiles"], 3, "6 - 4 = 2: 3 missiles")
	check_eq(t.ammo_for(t.weapons[0].def), 11, "one AMS shot used")
	check_eq(t.heat_generated, 1, "1 heat")
	check(Explainer.text(GameEvent.new(GameEvent.WEAPON_FIRED, hit), v[0], ExplainLevel.FULL).contains("anti-missile"))


func test_ams_stops_everything_on_low_roll() -> void:
	var hit := _fire(_setup(["ams", "ammo:ams"]), [6, 6, 2, 3])
	check_eq(hit["missiles"], 0, "5 - 4 = 1: all shot down")


func test_ams_twice_a_turn_and_needs_ammo() -> void:
	var v := _setup(["ams", "ammo:ams"])
	_fire(v, [6, 6, 3, 3])
	_fire(v, [6, 6, 3, 3])
	var third := _fire(v, [6, 6, 3, 3])
	check(not third.has("ams"), "two attacks a turn")
	var w := _setup(["ams"])
	check(not _fire(w, [6, 6, 3, 3]).has("ams"), "no ammo, no AMS")


func test_ams_cant_fire_at_targets() -> void:
	var v := _setup(["ams", "ammo:ams"])
	var t: Unit = v[2]
	check(not ToHitCalc.weapon(v[0], t, t.weapons[0], v[1], false).possible())
