extends TestCase
## Guardian ECM suites (p. 200) against Artemis IV.


func _def(id: String, eq: Dictionary) -> UnitDef:
	return UnitDef.from_dict({"id": id, "name": id, "tonnage": 50, "walk_mp": 4,
			"armor": {"CT": 20, "LT": 20, "RT": 20, "LA": 16, "RA": 16, "LL": 20, "RL": 20, "HD": 9},
			"equipment": eq}, weapons())


## Attacker with an Artemis LRM 10; target 3 hexes away, carrying ECM if asked.
func _setup(target_ecm: bool) -> Array:
	var s := GameState.new(open_map(16, 4))
	var a := Unit.new(1, _def("a", {"RA": ["lrm10+artemis"], "RT": ["ammo:lrm10"]}), 0, hex_at(1, 2), 2)
	var t := Unit.new(2, _def("t", {"LT": ["guardian_ecm"]} if target_ecm else {}), 1, hex_at(4, 2), 5)
	s.add_unit(a)
	s.add_unit(t)
	return [s, a, t]


func _fire(v: Array) -> Dictionary:
	var a: Unit = v[1]
	var th := ToHitCalc.weapon(v[0], a, a.weapons[0], v[2])
	var dice := LoadedDice.new()
	dice.queue_2d6(12)
	dice.queue_2d6(3)  # 3 on the 10 column: 3; with Artemis 5: 6
	var out := {}
	WeaponFire.resolve(v[0], dice, func(t: Variant, d: Dictionary) -> void:
		if t == GameEvent.WEAPON_FIRED:
			out.merge(d, true), a, a.weapons[0], v[2], th)
	return out


func test_weight_and_slots() -> void:
	var t: Unit = _setup(true)[2]
	check_eq(t.def.ecm_loc, Location.LT)
	check_eq(DesignWeight.breakdown(t.def)["ecm"], 1.5)
	check_eq(t.slots[Location.LT].filter(func(s: CritSlot) -> bool: return s.kind == CritSlot.Kind.ECM).size(), 2)


func test_ecm_cancels_artemis() -> void:
	var plain := _fire(_setup(false))
	check_eq(plain["missiles"], 6, "Artemis +2")
	var jammed := _fire(_setup(true))
	check_eq(jammed["missiles"], 3, "no bonus inside enemy ECM")
	check_eq(jammed["artemis_blocked"], "enemy ECM jams the Artemis guidance")


func test_ecm_range_and_crit() -> void:
	var v := _setup(true)
	var s: GameState = v[0]
	var t: Unit = v[2]
	check(Ecm.hostile_at(s, 0, hex_at(10, 2)), "6 hexes from the suite")
	check(not Ecm.hostile_at(s, 0, hex_at(11, 2)), "7 hexes: clear")
	check(not Ecm.hostile_at(s, 1, hex_at(4, 2)), "own ECM isn't hostile")
	var slot: CritSlot = t.slots[Location.LT].filter(func(c: CritSlot) -> bool: return c.kind == CritSlot.Kind.ECM)[0]
	check_eq(CritEffects.apply(s, LoadedDice.new(), func(_t: Variant, _d: Dictionary) -> void: pass, t, Location.LT, slot),
			"ECM suite destroyed")
	check(not Ecm.working(t))
	check_eq(_fire(v)["missiles"], 6, "bonus back once the suite is gone")


func test_indirect_fire_gets_no_artemis() -> void:
	var v := _setup(false)
	var th := ToHit.new()
	th.spotter_id = 3
	check_eq(Ecm.artemis_blocked(v[0], v[1], v[2], th), "indirect fire gets no Artemis bonus")
	var fired := _fire(v)
	check(not fired.has("artemis_blocked"))
	check(WeaponText.fired(v[0], fired, ExplainLevel.FULL, {}).contains("Artemis +2"))


func test_new_designs_carry_the_gear() -> void:
	var db := UnitDb.load_dir()
	check(db.get_def("raven_rvn3l").ecm_loc >= 0, "Raven ECM")
	check(db.get_def("marauder_mad3r_tc").tc_loc >= 0, "Marauder TC")
	var atlas := db.get_def("atlas_as7k")
	check(atlas.weapon_mounts.any(func(m: Dictionary) -> bool: return m["weapon"].ams), "Atlas AMS")
	check_eq(BattleValue.breakdown(db.get_def("raven_rvn3l"))["ecm"], BattleValue.ECM_BV)
