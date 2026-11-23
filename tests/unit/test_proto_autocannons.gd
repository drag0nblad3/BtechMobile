extends TestCase
## Official Clan ProtoMech AC family, including standard ammo and criticals.

const ROWS := [
	["c_proto_ac2", 1, 2, 7, 14, 20, 3.5, 2, 34, 40, 4],
	["c_proto_ac4", 1, 4, 5, 10, 15, 4.5, 3, 49, 20, 6],
	["c_proto_ac8", 2, 8, 3, 7, 10, 5.5, 4, 66, 10, 8]
]


func test_proto_autocannons_match_megamek_equipment_sources() -> void:
	var db := weapons()
	for row: Array in ROWS:
		var w: WeaponDef = db.get_def(row[0])
		check(w != null, str(row[0]) + " must exist")
		if w == null:
			continue
		check_eq([w.heat, w.damage, w.short_range, w.medium_range,
				w.long_range, w.tons, w.slots, w.bv, w.ammo_per_ton,
				w.ammo_bv], row.slice(1), w.id + " official values")
		check_eq(w.tech, "clan")
		check_eq(w.type, "ballistic")
		check(AutocannonCrit.is_autocannon(w), w.id + " follows AC critical rules")


func test_proto_ac8_mounted_ammunition_and_hits() -> void:
	var d := UnitDef.from_dict({"id": "test_proto_ac8", "name": "Test",
			"tonnage": 55, "walk_mp": 4, "tech_base": "clan",
			"armor": {"HD": 9, "CT": 20, "LT": 15, "RT": 15,
				"LA": 12, "RA": 12, "LL": 18, "RL": 18},
			"equipment": {"RA": ["c_proto_ac8"], "LT": ["ammo:c_proto_ac8"]}},
			weapons())
	var u := Unit.new(1, d, 0, Vector2i.ZERO, 0)
	check_eq(u.weapons.size(), 1)
	check_eq(u.ammo.size(), 1)
	check_eq(u.ammo[0].shots, 10, "ten rounds per ton")
	check_eq(WeaponFire.take_shots(u, u.weapons[0]), 1)
	check_eq(u.ammo[0].shots, 9)
	var w: MountedWeapon = u.weapons[0]
	check(AutocannonCrit.absorb(w), "first hit does not disable AC")
	check(not AutocannonCrit.absorb(w), "second hit disables it")
