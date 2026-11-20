extends TestCase
## Equipment rules: double heat sinks, CASE.


func _def(extra: Dictionary) -> UnitDef:
	var d := {"id": "t", "name": "Test", "tonnage": 50, "walk_mp": 4,
			"armor": {"LT": 10, "CT": 10}, "rear_armor": {"LT": 10, "CT": 5}}
	d.merge(extra, true)
	return UnitDef.from_dict(d, weapons())


func test_double_heat_sinks() -> void:
	var def := _def({"heat_sinks": 12, "heat_sink_type": "double",
			"equipment": {"LT": ["heat_sink", "heat_sink"]}})
	var u := Unit.new(1, def, 0, Vector2i.ZERO, 0)
	check_eq(u.dissipation(), 24, "12 doubles remove 24")
	var sinks: Array = u.slots[Location.LT].filter(func(s: CritSlot) -> bool: return s.kind == CritSlot.Kind.HEAT_SINK)
	check_eq(sinks.size(), 6, "3 slots each")
	sinks[0].hit = true
	check(u.lose_heat_sink(sinks[0]))
	check_eq(u.dissipation(), 22, "one double lost: -2")
	sinks[1].hit = true
	check(not u.lose_heat_sink(sinks[1]), "same sink's second slot")
	check_eq(u.dissipation(), 22)
	sinks[3].hit = true
	check(u.lose_heat_sink(sinks[3]), "the other sink")
	check_eq(u.dissipation(), 20)
	check_eq(DesignWeight.breakdown(def)["heat_sinks"], 2.0, "same weight as singles")


func test_double_sinks_under_water() -> void:
	var def := _def({"heat_sinks": 12, "heat_sink_type": "double",
			"equipment": {"LL": ["heat_sink"], "RT": ["heat_sink"]}})
	var u := Unit.new(1, def, 0, Vector2i.ZERO, 0)
	var tile := make_map(["w0d1"]).get_tile(Vector2i.ZERO)
	check_eq(HeatPhase.leg_heat_sinks(u), 1)
	check_eq(HeatPhase.water_cooling(tile, u), 2, "one leg double: 2 extra")
	u.prone = true
	check_eq(HeatPhase.water_cooling(tile, u), 6, "all under: capped at 6")


func _bin_unit(case: bool) -> Unit:
	var eq := ["ammo:ac20"]
	if case:
		eq.append("case")
	return Unit.new(1, _def({"equipment": {"LT": eq}}), 0, Vector2i.ZERO, 0)


func test_case_caps_explosion() -> void:
	var u := _bin_unit(true)
	check(u.def.has_case(Location.LT))
	var ct := u.structure[Location.CT]
	var steps := AmmoExplosion.internal(u, Location.LT, 100)
	check_eq(steps.size(), 1, "nothing transfers")
	check_eq(int(steps[0]["structure"]), 10, "10 to structure")
	check_eq(int(steps[0]["armor"]), 10, "10 to rear armor")
	check_eq(u.rear_armor[Location.LT], 0)
	check_eq(u.armor[Location.LT], 10, "front armor untouched")
	check_eq(u.structure[Location.CT], ct, "center torso safe")
	check(not u.destroyed)
	check_eq(DesignWeight.breakdown(u.def)["case"], 0.5)


func test_no_case_transfers() -> void:
	var u := _bin_unit(false)
	var lt := u.structure[Location.LT]
	var ct := u.structure[Location.CT]
	AmmoExplosion.internal(u, Location.LT, 100)
	check(u.is_location_destroyed(Location.LT))
	check_eq(u.structure[Location.CT], ct - (20 - lt), "the rest of the 20 cap goes inward")


func test_case_catches_transferred_damage() -> void:
	var def := _def({"equipment": {"LA": ["ammo:ac20"], "LT": ["case"]}})
	var u := Unit.new(1, def, 0, Vector2i.ZERO, 0)
	var la := u.structure[Location.LA]
	var ct := u.structure[Location.CT]
	var steps := AmmoExplosion.internal(u, Location.LA, 100)
	check(u.is_location_destroyed(Location.LA))
	check_eq(int(steps[-1]["structure"]), mini(10, 20 - la), "side torso takes it like its own blast")
	check_eq(u.structure[Location.CT], ct, "stops at the CASE torso")
