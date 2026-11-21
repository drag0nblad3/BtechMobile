extends TestCase
## Shape-first 3-D sculpt QA: Warhammer, Archer, and Shadow Hawk.

const CHASSIS := ["warhammer", "archer", "shadow_hawk"]
const EXPECTED_UNITS := ["warhammer_whm6r", "archer_arc2r", "shadow_hawk_shd2h"]


func test_coarse_silhouettes_and_fine_models_have_full_rigs() -> void:
	var db := UnitDb.load_dir()
	for i in CHASSIS.size():
		var id: String = CHASSIS[i]
		for suffix in ["_shape", ""]:
			var m := VxModel.load_file("res://data/voxels/%s%s.json" % [id, suffix])
			check(m.errors.is_empty(), "%s%s errors: %s" % [id, suffix, m.errors])
			check_eq(m.unit_id, EXPECTED_UNITS[i], "unit matches canonical record")
			check(db.get_def(m.unit_id) != null, "official unit exists: " + id)
			for loc in Location.COUNT:
				check(not m.parts_at(loc).is_empty(),
						"%s%s lacks %s" % [id, suffix, Location.code(loc)])
			check_eq(m.legs, "plantigrade", id + " knee geometry")
			if suffix == "_shape":
				check(m.cell_count() > 5000 and m.cell_count() < 13000,
						"%s low shape count %d" % [id, m.cell_count()])
			else:
				check(m.cell_count() >= 95000 and m.cell_count() <= 165000,
						"%s fine voxel count %d" % [id, m.cell_count()])


func test_fine_contours_are_identical_to_primary_shape_sculpt() -> void:
	for id in CHASSIS:
		var coarse: Dictionary = JsonFile.read("res://data/voxels/%s_shape.json" % id)
		var detail: Dictionary = JsonFile.read("res://data/voxels/%s.json" % id)
		var originals := {}
		for p: Dictionary in coarse["parts"]:
			originals[p["name"]] = p
		for p: Dictionary in detail["parts"]:
			if p.has("mirror"):
				continue
			var source: Dictionary = originals[p["name"]]
			for j in source["shapes"].size():
				if source["shapes"][j].has("loft"):
					check_eq(source["shapes"][j]["loft"], p["shapes"][j]["loft"],
							"refinement changed %s/%s silhouette" % [id, p["name"]])


func test_part_volumes_do_not_interpenetrate() -> void:
	# Check authored coarse cells (no need to subdivide for this invariant).
	for id in CHASSIS:
		for suffix in ["_shape", ""]:
			var d: Dictionary = JsonFile.read("res://data/voxels/%s%s.json" % [id, suffix])
			d["subdivide"] = 1
			for part: Dictionary in d["parts"]:
				part.erase("detail")
			var m := VxModel.from_dict(d)
			var owners := {}
			for p: Dictionary in m.parts:
				for c: Vector3i in p["cells"]:
					check(not owners.has(c), "%s%s overlaps %s and %s at %s" %
							[id, suffix, owners.get(c, "?"), p["name"], c])
					owners[c] = p["name"]


func test_archer_lrm20_launchers_have_real_mirrored_tubes() -> void:
	var d: Dictionary = JsonFile.read("res://data/voxels/archer.json")
	d["subdivide"] = 1
	for part: Dictionary in d["parts"]:
		part.erase("detail")
	var m := VxModel.from_dict(d)
	check(m.errors.is_empty(), "Archer JSON must load")
	for loc in [Location.LT, Location.RT]:
		var rack: Dictionary = m.part("lt_rack" if loc == Location.LT else "rt_rack")
		var cells: Dictionary = rack["cells"]
		var tubes: Array = m.muzzles[loc]
		check_eq(tubes.size(), 20, "Archer rack should have 20 apertures")
		var seen := {}
		for p: Vector3 in tubes:
			var cx := floori(p.x)
			var cy := floori(p.y)
			seen[Vector2i(cx, cy)] = true
			for cz in range(-12, -8):
				check(not cells.has(Vector3i(cx, cy, cz)),
						"Blocked LRM-20 tube at %s" % Vector3i(cx, cy, cz))
		check_eq(seen.size(), 20, "tubes must have unique positions")


func test_hollow_lofts_preserve_exterior_without_solid_center() -> void:
	var d: Dictionary = JsonFile.read("res://data/voxels/warhammer.json")
	d["subdivide"] = 1
	var with_skin := VxModel.from_dict(d)
	var skin_count := with_skin.cell_count()
	for part: Dictionary in d["parts"]:
		for step: Dictionary in part.get("shapes", []):
			step.erase("hollow")
	var solid := VxModel.from_dict(d)
	check(skin_count < solid.cell_count(),
			"high-detail loft skin must remove inaccessible interior volume")
	check(skin_count > solid.cell_count() / 2,
			"high-detail loft skin should retain visible exterior armor")
