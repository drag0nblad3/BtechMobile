extends TestCase
## Shape-first Marauder/Timber Wolf regression tests for Claude's JSON rig.


func test_both_designs_have_coarse_and_fine_versions() -> void:
	for id in ["marauder", "timber_wolf"]:
		var low := VxModel.load_file("res://data/voxels/%s_shape.json" % id)
		var high := VxModel.load_file("res://data/voxels/%s.json" % id)
		check(low.errors.is_empty(), "%s shape errors: %s" % [id, low.errors])
		check(high.errors.is_empty(), "%s fine errors: %s" % [id, high.errors])
		check_eq(low.detail, 1)
		check_eq(high.detail, 3)
		check(low.cell_count() > 2500 and low.cell_count() < 12000,
				"%s shape is intended as a lightweight sculpt" % id)
		check(high.cell_count() >= 100000 and high.cell_count() <= 160000,
				"%s fine voxels: %d" % [id, high.cell_count()])
		check_eq(low.unit_id, high.unit_id, "both LODs use one official record")
		check(designs().get_def(low.unit_id) != null, "unit exists for " + id)
		check_eq(low.legs, "digitigrade")
		check_eq(high.legs, "digitigrade")
		for loc in Location.COUNT:
			check(not low.parts_at(loc).is_empty(), "%s low missing %s" % [id, Location.code(loc)])
			check(not high.parts_at(loc).is_empty(), "%s high missing %s" % [id, Location.code(loc)])
		for name in ["ct", "hd", "lt", "rt", "la", "ra", "ll", "rl"]:
			check(not low.part(name).is_empty(), "%s low missing %s" % [id, name])
			check(not high.part(name).is_empty(), "%s high missing %s" % [id, name])


func test_coarse_sculpt_has_no_overlapping_components() -> void:
	for id in ["marauder", "timber_wolf"]:
		for suffix in ["_shape", ""]:
			var d: Dictionary = JsonFile.read("res://data/voxels/%s%s.json" % [id, suffix])
			d["subdivide"] = 1
			# Fine-grid decorations are not defined in the coarse authoring grid.
			for part: Dictionary in d["parts"]:
				part.erase("detail")
			var m := VxModel.from_dict(d)
			check(m.errors.is_empty(), "coarse load errors for %s%s" % [id, suffix])
			var owners := {}
			for p: Dictionary in m.parts:
				for c: Vector3i in p["cells"]:
					check(not owners.has(c), "%s%s overlapping %s and %s at %s" %
							[id, suffix, owners.get(c, "?"), p["name"], c])
					owners[c] = p["name"]


func test_timber_wolf_has_forty_open_missile_tubes() -> void:
	var d: Dictionary = JsonFile.read("res://data/voxels/timber_wolf.json")
	d["subdivide"] = 1
	for p: Dictionary in d["parts"]:
		p.erase("detail")
	var m := VxModel.from_dict(d)
	check(m.errors.is_empty(), "Timber Wolf must load")
	for loc in [Location.LT, Location.RT]:
		var spec: Dictionary = m.part("lt_rack" if loc == Location.LT else "rt_rack")
		var cells: Dictionary = spec["cells"]
		var unique := {}
		var muzzles: Array = m.muzzles[loc]
		check_eq(muzzles.size(), 20, "LRM-20 needs twenty separate tubes")
		for point: Vector3 in muzzles:
			var x := floori(point.x)
			var y := floori(point.y)
			unique[Vector2i(x, y)] = true
			for z in range(-12, -8):
				check(not cells.has(Vector3i(x, y, z)),
						"blocked LRM port at %s %d,%d,%d" % [Location.code(loc), x, y, z])
			check(cells.has(Vector3i(x, y + 1, -12)) or y == 43,
					"missile tubes need visible frame separation")
		check_eq(unique.size(), 20, "twenty distinct grid ports")
	check_eq(VxVolley.salvo_count(15), 15, "Catapult salvo stays at 15")
	check_eq(VxVolley.salvo_count(20), 20, "Timber Wolf salvo is 20")


func test_primary_high_res_contours_match_low_res_shape() -> void:
	for id in ["marauder", "timber_wolf"]:
		var lo: Dictionary = JsonFile.read("res://data/voxels/%s_shape.json" % id)
		var hi: Dictionary = JsonFile.read("res://data/voxels/%s.json" % id)
		var low_parts := {}
		for p: Dictionary in lo["parts"]:
			low_parts[p["name"]] = p
		for p: Dictionary in hi["parts"]:
			if p.has("mirror"):
				continue
			var src: Dictionary = low_parts[p["name"]]
			for i in src["shapes"].size():
				if src["shapes"][i].has("loft"):
					check_eq(p["shapes"][i]["loft"], src["shapes"][i]["loft"],
							"%s %s contour changed while detailing" % [id, p["name"]])
