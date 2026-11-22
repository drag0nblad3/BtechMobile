extends TestCase
## Record-sheet mounts must bind to authored, distinct chassis landmarks.


func _def(id: String) -> UnitDef:
	return UnitDef.from_dict(JsonFile.read("res://data/units/" + id + ".json"),
		WeaponDb.load_file())


func test_classic_chassis_sockets_match_record_sheet_locations() -> void:
	for id in ["atlas_as7d", "catapult_cplt_c1", "jenner_jr7d",
			"hunchback_hbk4g", "wolverine_wvr6r", "warhammer_whm6r",
			"griffin_grf1n", "marauder_mad3r"]:
		var design := _def(id)
		var authored := 0
		for i in design.weapon_mounts.size():
			var p := WeaponSockets.local_position(design, i)
			if p != Vector3.INF:
				authored += 1
				check(absf(p.x) < 0.65 and p.y > 0.35 and absf(p.z) < 0.65,
					"reasonable muzzle landmark for " + id)
		check(authored >= 2, id + " uses several real mount locations")


func test_missile_pods_have_opposite_sides() -> void:
	var catapult := _def("catapult_cplt_c1")
	var left := Vector3.INF
	var right := Vector3.INF
	for i in catapult.weapon_mounts.size():
		var loc: int = int(catapult.weapon_mounts[i]["loc"])
		if loc == Location.LA:
			left = WeaponSockets.local_position(catapult, i)
		elif loc == Location.RA:
			right = WeaponSockets.local_position(catapult, i)
	check(left.x < -0.3 and right.x > 0.3, "separate LRM pod sockets")


func test_rear_mounts_point_backwards() -> void:
	var atlas := _def("atlas_as7d")
	var found := 0
	for i in atlas.weapon_mounts.size():
		if atlas.weapon_mounts[i].get("rear", false):
			var p := WeaponSockets.local_position(atlas, i)
			check(p.z > 0.0, "rear lasers launch behind Atlas")
			found += 1
	check(found >= 2, "two rear-facing lasers are mapped")


func test_duplicate_weapons_get_distinct_muzzles() -> void:
	var jenner := _def("jenner_jr7d")
	var left: Array[Vector3] = []
	for i in jenner.weapon_mounts.size():
		if int(jenner.weapon_mounts[i]["loc"]) == Location.LA:
			left.append(WeaponSockets.local_position(jenner, i))
	check(left.size() >= 2, "Jenner has twin left-arm lasers")
	if left.size() >= 2:
		check(left[0] != left[1], "twin lasers use two distinct muzzles")


func test_jump_arcs_and_effect_budgets() -> void:
	var start := Vector3(-2, 0, 0)
	var finish := Vector3(2, 1, 0)
	check_eq(JumpJetFx.arc(start, finish, 0, 1.5), start)
	check_eq(JumpJetFx.arc(start, finish, 1, 1.5), finish)
	check(JumpJetFx.arc(start, finish, 0.5, 1.5).y > 1.5, "jump rises above ground")
	check(JumpJetFx.MESHES_PER_JUMP <= 4 and JumpJetFx.MAX_ACTIVE <= 12,
		"mobile effect budgets are bounded")
	for key in ["jet_launch", "jet_land", "jet_splash"]:
		check(VxBlast.KINDS.has(key), key + " has a low-cost burst")
