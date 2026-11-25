extends TestCase
## Equipment readout uses actual design definitions without changing combat data.


func test_catalog_categories_and_unique_ids() -> void:
	var db := weapons()
	var entries := ReadoutEquipmentCatalog.build(db, {})
	var ids := {}
	for item: Dictionary in entries:
		check(not ids.has(item["id"]), "Duplicate catalog item: " + String(item["id"]))
		ids[item["id"]] = item
	for id: String in db.by_id:
		check(ids.has("weapon:" + id))
	for id: String in ["guardian_ecm:is", "guardian_ecm:clan", "beagle_probe",
			"armor:stealth", "structure:endo_steel", "gyro:heavy_duty",
			"case2", "targeting_computer", "improved_jump_jet", "double_heat_sink", "hatchet"]:
		check(ids.has(id), "Missing " + id)
	check(ReadoutEquipmentCatalog.matches(ids["guardian_ecm:is"], "ecm", {"category": "Electronics", "tech": 1}))
	check(not ReadoutEquipmentCatalog.matches(ids["guardian_ecm:is"], "", {"tech": 2}))
	check(not ReadoutEquipmentCatalog.matches(ids["guardian_ecm:is"], "", {"ammo": 2}))


func test_actual_installations() -> void:
	var d := make_def(5, 50)
	d.ecm_loc = Location.CT
	d.ecm_type = "guardian_ecm"
	d.double_heat_sinks = true
	d.jump_mp = 3
	d.jump_jet_type = "improved"
	d.structure_type = "endo_steel"
	var w := WeaponDef.new()
	w.id = "example"
	d.weapon_mounts.append({"weapon": w, "artemis": true})
	d.ammo_mounts.append({"weapon": w, "kind": "narc", "half": true})
	d.ammo_mounts.append({"weapon": w, "kind": "narc", "half": false})
	var entries: Array[UnitDef] = [d]
	var usage := ReadoutEquipmentUsage.index(entries)
	for id: String in ["guardian_ecm:is", "double_heat_sink", "improved_jump_jet",
			"structure:endo_steel", "weapon:example", "artemis", "ammo:example:narc"]:
		check(usage.has(id), "Missing installed system " + id)
	check_eq(usage.get("ammo:example:narc", []).size(), 1, "Count designs, not bins")
	check(not usage.has("guardian_ecm:clan"))


func test_shipped_ammo_catalog() -> void:
	var db := weapons()
	var entries := ReadoutEquipmentCatalog.build(db, {})
	var found := false
	for item: Dictionary in entries:
		if item["category"] == "Ammunition":
			found = true
			check(ReadoutEquipmentCatalog.matches(item, "", {"category": "Ammunition"}))
			check(not ReadoutEquipmentCatalog.matches(item, "", {"ammo": 1}))
	check(found, "Ammunition must be independently browsable")
