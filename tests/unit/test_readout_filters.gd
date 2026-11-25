extends TestCase
## Catalog filtering is independent of combat state.


func test_combined_unit_filters() -> void:
	var d := make_def(9, 20)
	d.name = "Piranha"
	d.tech_base = "clan"
	d.bv = 998
	d.source = {"role": "Striker"}
	var filters := {"kind": 1, "tech": 2, "weight": 1, "role": "Striker", "bv": 1}
	check(ReadoutFilters.unit_matches(d, "Piranha", filters))
	check(not ReadoutFilters.unit_matches(d, "Atlas", filters))
	filters["bv"] = 2
	check(not ReadoutFilters.unit_matches(d, "", filters))
	d.bv = 1000
	check(ReadoutFilters.unit_matches(d, "", filters))
	filters["weight"] = 3
	check(not ReadoutFilters.unit_matches(d, "", filters))


func test_sort_keeps_all_entries() -> void:
	var light := make_def(9, 20)
	light.bv = 998
	var heavy := make_def(4, 80)
	heavy.bv = 2200
	var entries: Array[UnitDef] = [light, heavy]
	ReadoutFilters.sort_units(entries, 2)
	check_eq(entries[0], heavy)
	ReadoutFilters.sort_units(entries, 3)
	check_eq(entries[0], light)
	check_eq(entries.size(), 2)


func test_equipment_defaults_and_filters() -> void:
	var db := weapons()
	var total := 0
	for w: WeaponDef in db.by_id.values():
		if ReadoutFilters.weapon_matches(w, "", {}):
			total += 1
	check_eq(total, db.by_id.size(), "Blank search must show entire catalog")
	var laser := WeaponDef.new()
	laser.name = "ER Medium Laser"
	laser.id = "c_er_medium_laser"
	laser.tech = "clan"
	laser.type = "energy"
	check(ReadoutFilters.weapon_matches(laser, "medium laser", {"type": "energy", "tech": 2, "ammo": 2}))
	check(not ReadoutFilters.weapon_matches(laser, "", {"ammo": 1}))
	check(not ReadoutFilters.weapon_matches(laser, "", {"tech": 1}))
	check(not ReadoutFilters.weapon_matches(laser, "", {"type": "missile"}))
