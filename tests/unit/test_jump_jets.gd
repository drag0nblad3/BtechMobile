extends TestCase
## Improved jump jets (pp. 51, 102): half heat, 2 slots and double weight each.


func _def(jets: String) -> UnitDef:
	return UnitDef.from_dict({"id": "j", "name": "j", "tonnage": 75, "walk_mp": 4, "jump_mp": 2,
			"jump_jet_type": jets, "armor": {"CT": 20},
			"equipment": {"LL": ["jump_jet"], "RL": ["jump_jet"], "RA": ["medium_laser"]}}, weapons())


func test_half_heat_minimum_three() -> void:
	check_eq(MoveMode.heat(MoveMode.Kind.JUMP, 6, true), 3)
	check_eq(MoveMode.heat(MoveMode.Kind.JUMP, 7, true), 4, "rounds up")
	check_eq(MoveMode.heat(MoveMode.Kind.JUMP, 2, true), 3, "still at least 3")
	check_eq(MoveMode.heat(MoveMode.Kind.JUMP, 7), 7)


func test_slots_weight_and_damage() -> void:
	var u := Unit.new(1, _def("improved"), 0, Vector2i.ZERO, 0)
	var ll: Array = u.slots[Location.LL].filter(func(c: CritSlot) -> bool: return c.kind == CritSlot.Kind.JUMP_JET)
	check_eq(ll.size(), 2, "one improved jet, two slots")
	check_eq(DesignWeight.breakdown(u.def)["jump_jets"], 4.0, "2 jets x 1 t x 2")
	check_eq(DesignWeight.breakdown(_def("")).get("jump_jets"), 2.0)
	ll[0].hit = true
	check_eq(u.jump_mp(), 1, "a hit on either slot costs that jet")
	ll[1].hit = true
	check_eq(u.jump_mp(), 1, "the same jet again")
	check_eq(u.leg_jump_jets(), 1)
