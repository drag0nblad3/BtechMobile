extends TestCase
## Gyro types and engine types (pp. 98, 204).


func _def(gyro: String, engine := "standard") -> UnitDef:
	return UnitDef.from_dict({"id": "g", "name": "Gyro Test", "tonnage": 50, "walk_mp": 4, "gyro_type": gyro,
			"engine_type": engine, "equipment": {"RA": ["medium_laser"]}}, weapons())


func _gyro_slot(u: Unit) -> CritSlot:
	return u.slots[Location.CT].filter(func(c: CritSlot) -> bool: return c.kind == CritSlot.Kind.GYRO and not c.hit)[0]


func _hit(u: Unit) -> String:
	var slot := _gyro_slot(u)
	slot.hit = true
	return CritEffects.apply(GameState.new(open_map(2, 2)), LoadedDice.new(), func(_t, _d): pass, u, Location.CT, slot)


func test_slots_and_weight() -> void:
	for pair in [["standard", 4, 2.0], ["xl", 6, 1.0], ["compact", 2, 3.0], ["heavy_duty", 4, 4.0]]:
		var u := Unit.new(1, _def(pair[0]), 0, Vector2i.ZERO, 0)
		var n: int = u.slots[Location.CT].filter(func(c: CritSlot) -> bool: return c.kind == CritSlot.Kind.GYRO).size()
		check_eq(n, pair[1], pair[0] + " slots")
		check_eq(Gyro.tons(u.def), pair[2], pair[0] + " tons (200 engine: 2 t standard)")


func test_heavy_duty_takes_four_hits() -> void:
	var u := Unit.new(1, _def("heavy_duty"), 0, Vector2i.ZERO, 0)
	check(_hit(u).contains("no roll now"))
	check(u.psr_pending.is_empty(), "no roll for a heavy-duty hit")
	check_eq(Psr.standing_mods(u).target(), 6, "+1 per hit")
	_hit(u)
	check_eq(Psr.standing_mods(u).target(), 7)
	MovePsr.after_move(u, MoveMode.Kind.RUN, 3)
	check(u.psr_pending.is_empty(), "running needs no roll")
	MovePsr.after_move(u, MoveMode.Kind.JUMP, 3)
	check(u.psr_pending.any(func(p: Dictionary) -> bool: return p["reason"].contains("gyro") and p["mod"] == 2), "a jump is a +2 roll")
	u.psr_pending.clear()
	_hit(u)
	check(not Gyro.destroyed(u))
	check(_hit(u).contains("destroyed"), "the fourth hit")
	check(Gyro.destroyed(u))


func test_standard_gyro_unchanged() -> void:
	var u := Unit.new(1, _def("xl"), 0, Vector2i.ZERO, 0)
	_hit(u)
	check_eq(u.psr_pending.size(), 1, "a hit forces a roll")
	check_eq(Psr.standing_mods(u).target(), 7, "+2")
	check(_hit(u).contains("destroyed"), "second hit")


func test_light_and_compact_engines() -> void:
	var light := Unit.new(1, _def("standard", "light"), 0, Vector2i.ZERO, 0)
	check_eq(light.slots[Location.LT].filter(func(c: CritSlot) -> bool: return c.kind == CritSlot.Kind.ENGINE).size(), 2)
	check_eq(DesignWeight.breakdown(light.def)["engine"], 6.5, "8.5 t x 3/4, up to the half ton")
	Damage.destroy_location(light, Location.LT)
	check(not light.destroyed, "a light engine survives one side torso")
	check_eq(light.engine_hits, 2)
	var compact := Unit.new(1, _def("compact", "compact"), 0, Vector2i.ZERO, 0)
	check_eq(compact.slots[Location.CT].filter(func(c: CritSlot) -> bool: return c.kind == CritSlot.Kind.ENGINE).size(), 3)
	check_eq(DesignWeight.breakdown(compact.def)["engine"], 13.0, "8.5 t x 1.5, up to the half ton")
