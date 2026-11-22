extends TestCase
## MegaMek-sourced advanced weapons: stats, ammunition, armor and criticals.


func _def(eq: Dictionary, armor_kind := "standard", tech := "inner_sphere") -> UnitDef:
	return UnitDef.from_dict({"id": "extra_gear_test", "name": "Gear Test",
		"tonnage": 50, "walk_mp": 4, "tech_base": tech, "armor_type": armor_kind,
		"armor": {"HD": 9, "CT": 20, "LT": 12, "RT": 12, "RA": 8, "LA": 8, "LL": 15, "RL": 15},
		"equipment": eq}, weapons())


func _armor_lost(kind: String, attack: Array) -> int:
	var u := Unit.new(1, _def({}, kind), 0, Vector2i.ZERO, 0)
	var before := u.armor[Location.CT]
	Damage.apply(u, Location.CT, 6, false, attack)
	return before - u.armor[Location.CT]


func test_advanced_weapons_have_canonical_values() -> void:
	var db := weapons()
	check(db.by_id.size() >= 162, "catalog has the 21 extra official weapon types")
	# id, heat, damage, minimum, short, medium, long, slots, tons, BV, shots per ton
	var rows := [
		["re_small_laser", 4, 4, 0, 1, 2, 3, 1, 1.5, 14, 0],
		["re_medium_laser", 6, 6, 0, 3, 6, 9, 2, 2.5, 65, 0],
		["re_large_laser", 9, 9, 0, 5, 10, 15, 5, 8.0, 161, 0],
		["binary_laser_cannon", 16, 12, 0, 5, 10, 15, 4, 9.0, 222, 0],
		["c_small_chemical_laser", 1, 3, 0, 1, 2, 3, 1, 0.5, 7, 60],
		["c_medium_chemical_laser", 2, 5, 0, 3, 6, 9, 1, 1.0, 37, 30],
		["c_large_chemical_laser", 6, 8, 0, 5, 10, 15, 2, 5.0, 99, 10],
		["c_improved_large_laser", 8, 8, 0, 5, 10, 15, 1, 4.0, 123, 0],
		["c_improved_large_pulse_laser", 10, 9, 0, 3, 7, 10, 2, 6.0, 119, 0],
		["hvac2", 1, 2, 3, 10, 20, 35, 2, 8.0, 53, 30],
		["hvac5", 3, 5, 0, 8, 16, 28, 4, 12.0, 109, 15],
		["hvac10", 7, 10, 0, 6, 12, 20, 6, 14.0, 158, 8],
		["c_improved_ac2", 1, 2, 4, 8, 16, 24, 1, 5.0, 37, 45],
		["c_improved_ac5", 1, 5, 3, 6, 12, 18, 2, 7.0, 70, 20],
		["c_improved_ac10", 3, 10, 0, 5, 10, 15, 6, 11.0, 123, 10],
		["c_improved_ac20", 7, 20, 0, 3, 6, 9, 9, 13.0, 178, 5],
		["c_ap_gauss_rifle", 1, 3, 0, 3, 6, 9, 1, 0.5, 21, 40],
		["c_improved_gauss_rifle", 1, 15, 2, 7, 15, 22, 6, 13.0, 320, 8],
		["light_rifle", 1, 3, 0, 4, 8, 12, 1, 3.0, 21, 18],
		["medium_rifle", 2, 6, 1, 5, 10, 15, 2, 5.0, 51, 9],
		["heavy_rifle", 4, 9, 2, 6, 12, 18, 3, 8.0, 91, 6],
	]
	for row in rows:
		var w: WeaponDef = db.get_def(row[0])
		check(w != null, str(row[0]) + " exists")
		if w == null:
			continue
		check_eq([w.heat, w.damage, w.min_range, w.short_range, w.medium_range,
			w.long_range, w.slots, w.tons, w.bv, w.ammo_per_ton], row.slice(1),
			w.id + " matches MegaMek weapon and ammo tables")


func test_reengineered_lasers_ignore_special_armor_reduction() -> void:
	var ordinary := weapons().get_def("medium_laser").attack_types()
	var re := weapons().get_def("re_medium_laser")
	check_eq(re.to_hit_mod, -1)
	check(re.reengineered)
	var special := re.attack_types()
	check_eq(_armor_lost("reflective", ordinary), 3)
	check_eq(_armor_lost("reflective", special), 6)
	check_eq(_armor_lost("hardened", ordinary), 3)
	check_eq(_armor_lost("hardened", special), 6)
	check_eq(_armor_lost("ferro_lamellor", ordinary), 4)
	check_eq(_armor_lost("ferro_lamellor", special), 6)


func test_chemical_lasers_use_ammunition_despite_being_energy_weapons() -> void:
	var u := Unit.new(1, _def({"RA": ["c_medium_chemical_laser"],
			"LT": ["ammo:c_medium_chemical_laser"]}, "standard", "clan"), 0, Vector2i.ZERO, 0)
	var w: MountedWeapon = u.weapons[0]
	check_eq(w.def.type, "energy")
	check(w.def.uses_ammo())
	check_eq(u.ammo[0].shots, 30)
	check_eq(WeaponFire.take_shots(u, w), 1)
	check_eq(u.ammo[0].shots, 29)
	check_eq(DesignWeight.breakdown(u.def)["ammo"], 1.0)
	check_eq(w.def.ammo_bv, 5)


func test_primitive_rifles_lose_three_damage_vs_modern_armor() -> void:
	var mech := Unit.new(1, _def({}), 0, Vector2i.ZERO, 0)
	check_eq(RifleCannon.damage(3, mech), 0, "light rifle cannot penetrate military armor")
	check_eq(RifleCannon.damage(6, mech), 3)
	check_eq(RifleCannon.damage(9, mech), 6)
	check(weapons().get_def("heavy_rifle").rifle)


func test_gauss_specific_explosion_and_ammo() -> void:
	for item in [["c_ap_gauss_rifle", 3, 40], ["c_improved_gauss_rifle", 20, 8]]:
		var id: String = item[0]
		var u := Unit.new(1, _def({"RA": [id], "LT": ["ammo:" + id]}, "standard", "clan"),
			0, Vector2i.ZERO, 0)
		check_eq(ComponentExplosion.damage(u.weapons[0]), item[1], id)
		check_eq(u.ammo[0].shots, item[2])
		check_eq(u.ammo[0].explosion_damage(), 0, "Gauss rounds do not detonate")


func test_hvac_and_improved_autocannons_survive_first_critical() -> void:
	for id in ["hvac2", "hvac5", "hvac10", "c_improved_ac2", "c_improved_ac20"]:
		var w := MountedWeapon.new(weapons().get_def(id), Location.RA, false)
		check(AutocannonCrit.is_autocannon(w.def), id)
		check(AutocannonCrit.absorb(w), id + " survives first critical")
		check(not AutocannonCrit.absorb(w), id + " fails on second critical")
