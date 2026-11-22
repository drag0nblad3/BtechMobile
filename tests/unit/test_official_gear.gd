extends TestCase
## Gear the official designs brought in: active probes, inert gear (A-pods,
## TAG), half-ton ammo, weapons split across two locations, official BV.


func _def(eq: Dictionary, tech := "inner_sphere") -> UnitDef:
	return UnitDef.from_dict({"id": "g", "name": "Gear Test", "tonnage": 50, "walk_mp": 4, "tech_base": tech,
			"armor": {"HD": 9, "CT": 20, "LT": 15, "RT": 15, "LA": 10, "RA": 10, "LL": 15, "RL": 15},
			"equipment": eq}, weapons())


func _duel(eq: Dictionary) -> Array:
	var s := GameState.new(open_map(8, 3))
	var a := Unit.new(1, _def(eq), 0, hex_at(0, 1), 2)
	var t := mech("hunchback_hbk4g", 1, hex_at(3, 1), 5, 2)
	s.add_unit(a)
	s.add_unit(t)
	return [s, a, t]


func test_probe_clears_fog_and_murk() -> void:
	var v := _duel({"RA": ["medium_laser"], "CT": ["beagle_probe"]})
	var s: GameState = v[0]
	var a: Unit = v[1]
	var t: Unit = v[2]
	s.map.get_tile(t.coord).fog = 1
	s.conditions.low_visibility = true
	var mods: Array = ToHitCalc.weapon(s, a, a.weapons[0], t).mods.map(func(m: Dictionary) -> String: return m["label"])
	check(not mods.has("low visibility") and not mods.has("target in fog"), str(mods))
	a.probe_lost = true
	mods = ToHitCalc.weapon(s, a, a.weapons[0], t).mods.map(func(m: Dictionary) -> String: return m["label"])
	check(mods.has("low visibility") and mods.has("target in fog"), "a destroyed probe sees nothing")
	a.probe_lost = false
	t.coord = hex_at(5, 1)  # 5 hexes: past the Beagle's 4
	check(not ActiveProbe.clears(s, a, t), "out of range")


func test_hostile_ecm_blinds_the_probe() -> void:
	var v := _duel({"RA": ["medium_laser"], "CT": ["beagle_probe"]})
	var s: GameState = v[0]
	check(ActiveProbe.clears(s, v[1], v[2]))
	s.add_unit(Unit.new(3, _def({"CT": ["guardian_ecm"], "RA": ["small_laser"]}), 1, hex_at(1, 0), 3))
	check(not ActiveProbe.clears(s, v[1], v[2]), "inside hostile ECM")


func test_sizes_and_slots() -> void:
	var d := _def({"RA": ["medium_laser"], "LT": ["c_active_probe", "a_pod"], "RT": ["tag", "ammo:machine_gun:half"],
			"LA": ["machine_gun"]}, "clan")
	var parts := DesignWeight.breakdown(d)
	check_eq(parts["probe"], 1.0)
	check_eq(parts["inert"], 1.5, "A-pod 0.5 + TAG 1")
	var u := Unit.new(1, d, 0, Vector2i.ZERO, 0)
	check_eq(u.ammo[0].shots, 100, "half of 200 machine gun rounds")
	var gear: Array = u.slots[Location.LT].filter(func(c: CritSlot) -> bool: return c.kind == CritSlot.Kind.GEAR)
	check_eq(gear.size(), 1)
	check_eq(CritEffects.apply(GameState.new(open_map(2, 2)), LoadedDice.new(), func(_t, _d): pass, u, Location.LT, gear[0]),
			"A-Pod destroyed")
	check_eq(Ecm.slots(d), 1, "a Clan ECM suite takes one slot")


func test_split_weapon_spills_inward() -> void:
	var u := Unit.new(1, _def({"RA": ["ac20~2"]}), 0, Vector2i.ZERO, 0)
	var in_arm: int = u.slots[Location.RA].filter(func(c: CritSlot) -> bool: return c.kind == CritSlot.Kind.WEAPON).size()
	var in_torso: int = u.slots[Location.RT].filter(func(c: CritSlot) -> bool: return c.kind == CritSlot.Kind.WEAPON).size()
	check_eq([in_arm, in_torso], [8, 2])
	check_eq(u.weapons.size(), 1, "still one weapon, fired from the arm")
	check_eq(u.weapons[0].loc, Location.RA)


func test_official_battle_value() -> void:
	var db := designs()
	var atlas := db.get_def("atlas_as7d")
	check_eq(atlas.source.get("bv"), "sheet")
	check_eq(BattleValue.of(atlas), 1897)
	check(BvText.line(atlas, ExplainLevel.LIGHT).contains("official"))
	for def: UnitDef in db.by_id.values():
		check(def.bv > 0, def.id + " has an official or MegaMek BV")
		check(def.source.has("megamek"), def.id + " names its MegaMek file")
