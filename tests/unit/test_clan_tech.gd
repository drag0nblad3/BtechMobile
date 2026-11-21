extends TestCase
## Clan construction (ClanTech): compact XL engine and double heat sinks,
## built-in CASE, lighter ferro-fibrous armor and targeting computers.


func _def(tech: String) -> UnitDef:
	return UnitDef.from_dict({"id": tech, "name": tech, "tonnage": 75, "walk_mp": 5,
			"tech_base": tech, "engine_type": "xl", "heat_sink_type": "double", "heat_sinks": 11,
			"armor_type": "ferro_fibrous",
			"armor": {"CT": 32, "LT": 24, "RT": 24, "LA": 20, "RA": 20, "LL": 28, "RL": 28, "HD": 9},
			"equipment": {"LA": ["heat_sink"], "RA": ["c_er_large_laser" if tech == "clan" else "er_large_laser", "targeting_computer"],
				"LT": ["ammo:c_lrm20" if tech == "clan" else "ammo:lrm20"],
				"RT": ["c_lrm20" if tech == "clan" else "lrm20"]}}, weapons())


func _count(u: Unit, loc: int, kind: int) -> int:
	return u.slots[loc].filter(func(s: CritSlot) -> bool: return s.kind == kind).size()


func test_compact_parts() -> void:
	var c := Unit.new(1, _def("clan"), 0, Vector2i.ZERO, 0)
	var i := Unit.new(2, _def("inner_sphere"), 0, Vector2i.ZERO, 0)
	check(c.def.is_clan() and not i.def.is_clan())
	check_eq(_count(c, Location.LT, CritSlot.Kind.ENGINE), 2, "Clan XL: 2 slots a side")
	check_eq(_count(i, Location.LT, CritSlot.Kind.ENGINE), 3)
	check_eq(_count(c, Location.LA, CritSlot.Kind.HEAT_SINK), 2, "Clan double heat sink: 2 slots")
	check_eq(_count(i, Location.LA, CritSlot.Kind.HEAT_SINK), 3)


func test_xl_survives_one_side_torso() -> void:
	var u := Unit.new(1, _def("clan"), 0, Vector2i.ZERO, 0)
	check(not XlEngine.torso_loss_kills(u))
	Damage.destroy_location(u, Location.LT)
	check_eq(u.engine_hits, 2)
	check(not u.destroyed, "still fighting on 2 engine hits")
	check(XlEngine.torso_loss_kills(u))
	Damage.destroy_location(u, Location.RT)
	check(u.destroyed)
	check(u.destroyed_reason.begins_with("Clan XL engine"), u.destroyed_reason)
	var i := Unit.new(2, _def("inner_sphere"), 0, Vector2i.ZERO, 0)
	Damage.destroy_location(i, Location.LT)
	check(i.destroyed, "Inner Sphere XL dies with one side torso")


func test_case_armor_and_targeting_computer() -> void:
	var c := _def("clan")
	var i := _def("inner_sphere")
	for loc in Location.COUNT:
		check(c.has_case(loc), "built-in CASE in %s" % Location.code(loc))
	check(not i.has_case(Location.LT))
	check_eq(DesignWeight.breakdown(c)["case"], 0.0, "free")
	check_eq(DesignWeight.breakdown(c)["armor"], 10.0, "185 points at 19.2 a ton")
	check_eq(DesignWeight.breakdown(i)["armor"], 10.5, "185 points at 17.92 a ton")
	check_eq(TargetingComputer.size(c), 1, "4 t of lasers / 5")
	check_eq(TargetingComputer.size(i), 2, "5 t / 4")
	check(BattleValue.breakdown(c)["structure"] > BattleValue.breakdown(i)["structure"], "harder to kill")


func test_log_explains_surviving_side_torso_loss() -> void:
	var s := GameState.new(open_map(8, 4))
	var u := Unit.new(1, _def("clan"), 0, hex_at(1, 1), 0)
	s.add_unit(u)
	var steps := Damage.apply(u, Location.LT, 40)
	var t := DamageText.damage(s, {"unit_id": 1, "amount": 40, "loc": Location.LT, "steps": steps,
			"covered": false}, ExplainLevel.FULL)
	check(t.contains("keeps running"), t)
