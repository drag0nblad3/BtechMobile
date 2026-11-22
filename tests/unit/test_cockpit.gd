extends TestCase
## Small cockpits: 2 t, two free head slots, +1 to piloting rolls.


func _def(cockpit: String) -> UnitDef:
	return UnitDef.from_dict({"id": "t", "name": "Test", "tonnage": 50, "walk_mp": 4, "cockpit_type": cockpit,
			"armor": {"HD": 9, "CT": 20, "LT": 10, "RT": 10, "LA": 8, "RA": 8, "LL": 10, "RL": 10},
			"equipment": {"HD": ["medium_laser", "medium_laser"]}}, weapons())


func test_small_cockpit() -> void:
	var d := _def("small")
	check_eq(DesignWeight.breakdown(d)["cockpit"], 2.0)
	check_eq(DesignWeight.breakdown(_def("standard"))["cockpit"], 3.0)
	var u := Unit.new(1, d, 0, Vector2i.ZERO, 0)
	var names: Array = u.slots[Location.HEAD].map(func(s: CritSlot) -> String: return s.name)
	check_eq(names, ["Life Support", "Sensors", "Cockpit", "Sensors", "Medium Laser", "Medium Laser"])
	check(Psr.standing_mods(u).mods.any(func(m: Dictionary) -> bool: return m["label"] == "small cockpit"))
	check(not Psr.standing_mods(Unit.new(2, make_def(4), 0, Vector2i.ZERO, 0)).mods.any(
			func(m: Dictionary) -> bool: return m["label"] == "small cockpit"))
