extends TestCase
## High density voxel passes preserve the 255-cycle polygon source files.
## No APK, geometry-only source edits, or battle rule changes required.

const NAMES := ["atlas", "wolverine", "jenner"]


func test_three_high_resolution_models_keep_authored_shape_sources() -> void:
	for chassis: String in NAMES:
		var source: Dictionary = JsonFile.read("res://data/voxels/%s_shape.json" % chassis)
		check_eq(int(source.get("subdivide", 0)), 1,
				"Do not overwrite approved coarse geometry: " + chassis)
		var raw := VxModel.from_dict(source)
		var model := VxModel.load_file("res://data/voxels/%s_voxel.json" % chassis)
		check(model.errors.is_empty(), "High-density model invalid: " + chassis)
		check_eq(model.detail, 2, "Voxel model must use twice the authored resolution")
		check_eq(model.parts.size(), raw.parts.size(), "Lost a distinct sculpted component")
		check(is_equal_approx(model.voxel_size * 2.0, raw.voxel_size),
				"Voxelization must not change model dimensions")
		check(model.cell_count() > raw.cell_count() * 5,
				"Fine contours were not rasterized into dense geometry")
		check(model.cell_count() >= 100000 and model.cell_count() <= 200000,
				"Check high-density count; approximate target 100k–150k per 'Mech")
		for loc in Location.COUNT:
			check(not model.parts_at(loc).is_empty(), "Missing gameplay hit location: " + chassis)
		for part: Dictionary in raw.parts:
			var fine: Dictionary = model.part(part["name"])
			check(not fine.is_empty(), "Missing source component " + part["name"])
			check(fine["cells"].size() > 0, "Empty high-density component " + part["name"])
			check(fine["pivot"].is_equal_approx(part["pivot"] * 2.0),
					"Joint changed position " + part["name"])


func test_interpolated_loft_has_new_silhouette_cells_between_original_slices() -> void:
	var d := {
		"id": "fine_taper",
		"voxel_size": 0.05,
		"subdivide": 2,
		"voxelize_lofts": true,
		"materials": [{"name":"armor", "color":"778899", "role":"armor"}],
		"parts": [{"name":"ct", "loc":"CT", "shapes":[
			{"loft":{"axis":"y","sections":[
				{"at":0,"polygon":[[-1.3,-1],[1.3,-1],[1.3,1],[-1.3,1]]},
				{"at":4,"polygon":[[-5.3,-1],[5.3,-1],[5.3,1],[-5.3,1]]}
			]},"mat":"armor"}]}]
	}
	var fine := VxModel.from_dict(d)
	var cells: Dictionary = fine.part("ct")["cells"]
	# At fine y=3 the width is larger than at fine y=2. Splitting old
	# coarse cells into eight identical cubes would fail this assertion.
	check(cells.has(Vector3i(5, 3, 0)), "Missing interpolated half-slice contour")
	check(not cells.has(Vector3i(5, 2, 0)), "High-res taper collapsed to duplicated cells")


func test_mirrors_keep_cell_parity_and_are_symmetric() -> void:
	for chassis: String in NAMES:
		var m := VxModel.load_file("res://data/voxels/%s_voxel.json" % chassis)
		var source: Dictionary = JsonFile.read("res://data/voxels/%s_shape.json" % chassis)
		for p: Dictionary in source["parts"]:
			if not p.has("mirror"):
				continue
			var src: Dictionary = m.part(p["mirror"])["cells"]
			var mirrored: Dictionary = m.part(p["name"])["cells"]
			check_eq(src.size(), mirrored.size(), "Unequal mirrored cell count: " + p["name"])
			# Added right-side details intentionally break perfect parity.
			if p.get("add", []).is_empty():
				for c: Vector3i in src:
					check(mirrored.has(Vector3i(-c.x - 1, c.y, c.z)),
							"Bad reflected cell in " + p["name"])
