extends TestCase
## The additional official chassis must keep independent shape/high recipes and actual weapon bores.

const IDS := ["tian_zong","jackalope","rattlesnake_ii","stealth","hermes","marauder_ii","thunder","champion","uziel","galahad","dragon_fire","cerberus","bane","locust_iic","mad_cat_mk_ii","shiro","grand_dragon","gunsmith","gladiator","shadow_hawk_iic","huntsman","cougar","ebon_jaguar","kingfisher","arctic_wolf","avatar","battle_cobra","black_lanner","griffin_iic","highlander_iic","jenner_iic","jinggau","peacekeeper","raptor","sunder","tempest","templar","thunderbolt_iic","glass_spider"]

func _raw(id: String, high: bool) -> Dictionary:
	return JsonFile.read("res://data/voxels/%s%s.json" % [id, "" if high else "_shape"])


func test_missing_chassis_have_official_records_and_fifty_geometric_passes() -> void:
	var db := UnitDb.load_dir()
	for id: String in IDS:
		var lo := _raw(id, false)
		var hi := _raw(id, true)
		check(not lo.is_empty() and not hi.is_empty(), id + " both LOD recipes exist")
		if lo.is_empty() or hi.is_empty():
			continue
		check(db.get_def(String(lo.get("unit", ""))) != null, id + " official design")
		check_eq(lo["unit"], hi["unit"], id + " same official sheet")
		check_eq(int(lo.get("subdivide", 0)), 1, id + " coarse silhouette")
		check_eq(int(hi.get("subdivide", 0)), 3, id + " fine voxelization")
		for d: Dictionary in [lo, hi]:
			check_eq(int(d.get("art_quality_passes", 0)), 50, id + " completed fifty passes")
			check(int(d.get("shape_refinement_edit_totals", 0)) >= 1000,
				id + " passes performed real polygon edits")
			check_eq(String(d.get("shape_refinement_revision", "")),
				"new-chassis-50-real-passes-20261122", id + " correct generation revision")
			check(bool(d.get("exclusive_parts", false)), id + " exclusive moving parts")
			check(d.get("signature", "").length() > 15, id + " defined unique features")
		check_eq(lo["parts"].size(), hi["parts"].size(), id + " same articulated sources")
		check_eq(lo.get("legs"), hi.get("legs"), id + " same gait")
		check_eq(lo.get("muzzles"), hi.get("muzzles"), id + " consistent firing origins")
		var has_details := false
		for i in lo["parts"].size():
			var a: Dictionary = lo["parts"][i]
			var b: Dictionary = hi["parts"][i]
			check_eq(a["name"], b["name"], id + " component identity")
			check_eq(a["loc"], b["loc"], id + " component hit location")
			check_eq(a.get("parent", ""), b.get("parent", ""), id + " component hierarchy")
			check_eq(a["shapes"], b["shapes"], id + " approved silhouette unchanged")
			if not b.get("detail", []).is_empty():
				has_details = true
		check(has_details, id + " has separate fine-grid details")


func test_missing_chassis_have_real_signature_weapon_apertures() -> void:
	for id: String in IDS:
		var d := _raw(id, true)
		check(not d.get("weapons", []).is_empty(), id + " signature weapons")
		var muzzle_count := 0
		for loc: String in d["muzzles"]:
			var points: Array = d["muzzles"][loc]
			if not points.is_empty() and points[0] is not Array:
				points = [points]
			var occupied := {}
			for point: Array in points:
				var coord := Vector3i(roundi(float(point[0])), roundi(float(point[1])),
					roundi(float(point[2])))
				check(not occupied.has(coord), id + " unique " + loc + " muzzle")
				occupied[coord] = true
				var has_bore := false
				for part: Dictionary in d["parts"]:
					if part.get("loc", "") != loc:
						continue
					for shape: Dictionary in part.get("shapes", []):
						if not shape.has("erase"):
							continue
						var a: Array = shape["erase"][0]
						var b: Array = shape["erase"][1]
						if coord.x >= a[0] and coord.x <= b[0] \
							and coord.y >= a[1] and coord.y <= b[1] \
							and coord.z >= a[2] and coord.z <= b[2]:
							has_bore = true
				check(has_bore, id + " drilled " + loc + " muzzle, not black paint")
				muzzle_count += 1
		check(muzzle_count > 0, id + " has an actionable signature gun")


func test_missing_chassis_coarse_recipes_load_with_valid_locations() -> void:
	for id: String in IDS:
		var d := _raw(id, false)
		var m := VxModel.from_dict(d)
		check(m.errors.is_empty(), "%s loader errors: %s" % [id, m.errors])
		for loc in Location.COUNT:
			check(not m.parts_at(loc).is_empty(), id + " " + Location.code(loc))
		var names := {}
		for p: Dictionary in m.parts:
			check(not names.has(p["name"]), id + " unique moving part " + p["name"])
			names[p["name"]] = true
		check(names.size() >= 15, id + " distinct connected geometry groups")
