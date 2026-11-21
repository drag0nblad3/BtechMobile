extends TestCase
## Geometry-only study. No voxel density or damage quality assertions.

const MODELS := [
	"res://data/voxels/atlas_shape.json",
	"res://data/voxels/wolverine_shape.json",
	"res://data/voxels/jenner_shape.json",
]


func test_independent_component_shapes_use_only_authored_profiles() -> void:
	for path: String in MODELS:
		var d: Dictionary = JsonFile.read(path)
		check_eq(d.get("subdivide", -1), 1, "no subdivision permitted in the shape gate")
		var polygons := 0
		for part: Dictionary in d.get("parts", []):
			for op: Dictionary in part.get("shapes", []):
				if op.has("loft"):
					polygons += 1
					check(op["loft"]["sections"].size() >= 2, "loft must have multiple profiles")
		check(polygons >= 12, "expected authored contours: %s" % path)
		var m := VxModel.from_dict(d)
		check(m.errors.is_empty(), "invalid shape study %s: %s" % [path, m.errors])
		# Shape proportions may stretch existing occupied cells without
		# adding any subdivisions. Keep only a generous low-res safety cap.
		check(m.cell_count() > 1200 and m.cell_count() < 28000,
				"shape-only count unexpected %s %d" % [m.id, m.cell_count()])
		for loc in Location.COUNT:
			check(not m.parts_at(loc).is_empty(), "%s missing %s" % [m.id, Location.code(loc)])


func test_loft_rasterization_changes_cross_section() -> void:
	var d := {
		"materials": [{"name": "form", "color": "b5b9bc", "role": "armor"}],
		"parts": [{"name":"ct", "loc":"CT", "shapes":[
			{"loft":{"axis":"y","sections":[
				{"at":0,"polygon":[[-1,-1],[1,-1],[1,1],[-1,1]]},
				{"at":4,"polygon":[[-4,-2],[4,-2],[4,2],[-4,2]]}
			]},"mat":"form"}]}]
	}
	var model := VxModel.from_dict(d)
	check(model.part("ct")["cells"].has(Vector3i(0,0,0)), "loft base missing")
	check(model.part("ct")["cells"].has(Vector3i(3,4,0)), "loft upper expansion missing")
	check(not model.part("ct")["cells"].has(Vector3i(3,0,0)),
			"loft should be tapered, not a box")


func test_chassis_defining_housings_are_independently_sculpted() -> void:
	var a := VxModel.load_file(MODELS[0])
	check(not a.part("pelvis").is_empty(), "Atlas armored pelvis should be separate")
	check(not a.part("rt_ac20_shroud").is_empty(), "Atlas AC20 needs an open shroud")
	check_eq(a.muzzles[Location.RT].size(), 1, "Atlas main bore")
	var w := VxModel.load_file(MODELS[1])
	check(not w.part("pelvis").is_empty(), "Wolverine needs a hip assembly")
	check(not w.part("lt_srm6").is_empty(), "Wolverine launcher must be its own shape")
	check_eq(w.muzzles[Location.LT].size(), 6, "Wolverine SRM-6 must have six ports")
	var j := VxModel.load_file(MODELS[2])
	check(not j.part("belly").is_empty(), "Jenner fuselage needs an undercarriage")
	for name in ["la_laser_lower", "la_laser_upper", "ra_laser_lower", "ra_laser_upper"]:
		check(not j.part(name).is_empty(), "Jenners paired lasers must be distinct: " + name)
	check_eq(j.muzzles[Location.CT].size(), 4, "Jenner SRM-4")
	check_eq(j.muzzles[Location.LA].size(), 2, "Jenner left double laser")
	check_eq(j.muzzles[Location.RA].size(), 2, "Jenner right double laser")


func test_authored_weapon_mouths_are_physically_empty() -> void:
	for path: String in MODELS:
		var model := VxModel.load_file(path)
		var location_to_part := {
			"atlas_shape": ["rt_ac20_shroud", "RT"],
			"wolverine_shape": ["lt_srm6", "LT"],
			"jenner_shape": ["la_laser_lower", "LA"],
		}
		var pair: Array = location_to_part[model.id]
		var section: Dictionary = model.part(pair[0])
		check(not section.is_empty(), "no weapon housing for " + model.id)
		var location: int = Location.from_code(pair[1])
		var muzzle: Vector3 = model.muzzles[location][0]
		var mouth := Vector3i(floori(muzzle.x), floori(muzzle.y), ceili(muzzle.z))
		check(not section["cells"].has(mouth), "weapon bore obstructed %s at %s" % [model.id, mouth])


func test_reference_shape_landmarks_are_real_separate_geometry() -> void:
	# Shape-stage regressions: these silhouette-defining landmarks must be
	# physical authored parts, not a texture, procedural detail or faux paint.
	var atlas := VxModel.load_file(MODELS[0])
	check(not atlas.part("hd_cheek_left").is_empty(), "Atlas needs separate cheek silhouette")
	check(not atlas.part("hd_cheek_right").is_empty(), "Atlas needs matching cheek silhouette")
	check(atlas.part("rt_ac20_shroud")["cells"].has(Vector3i(8, 44, -24)),
			"Atlas AC20 barrel must project from the right torso")
	var wolverine := VxModel.load_file(MODELS[1])
	check(wolverine.part("ra_ac5_shroud")["cells"].has(Vector3i(15, 26, -31)),
			"Wolverine forearm cannon must project independently of shoulder")
	var jenner := VxModel.load_file(MODELS[2])
	check(jenner.part("hd")["cells"].has(Vector3i(0, 28, -39)),
			"Jenner aircraft nose must extend forward of laser housings")
	check(not jenner.part("ll_hock_joint").is_empty(),
			"Jenner knee and rear hock must be independent geometry")
