extends TestCase
## Mixed Clan and Inner Sphere tech: each part uses its own maker's sizes.


func _def(tech: String, parts: Dictionary) -> UnitDef:
	return UnitDef.from_dict({"id": "t", "name": "Test", "tonnage": 50, "walk_mp": 4, "tech_base": tech,
			"engine_type": "xl", "heat_sink_type": "double", "clan_parts": parts,
			"armor": {"HD": 9, "CT": 20, "LT": 10, "RT": 10, "LA": 8, "RA": 8, "LL": 10, "RL": 10},
			"equipment": {}}, weapons())


func test_parts_default_to_the_chassis_tech() -> void:
	var d := _def("inner_sphere", {})
	check(not d.clan_part("engine") and not d.clan_part("heat_sinks"))
	check(_def("clan", {}).clan_part("armor"))


func test_clan_engine_in_inner_sphere_chassis() -> void:
	var d := _def("inner_sphere", {"engine": true})
	check_eq(ClanTech.xl_side_slots(d), 2, "Clan XL: 2 slots a side")
	check_eq(ClanTech.dhs_slots(d), 3, "Inner Sphere double heat sinks stay 3 slots")


func test_inner_sphere_parts_in_clan_chassis() -> void:
	var d := _def("clan", {"heat_sinks": false, "engine": false})
	check_eq(ClanTech.xl_side_slots(d), 3)
	check_eq(ClanTech.dhs_slots(d), 3)
