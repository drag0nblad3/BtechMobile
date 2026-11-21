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
		check(m.cell_count() > 1200 and m.cell_count() < 32000,
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
	check(atlas.part("rt_ac20_shroud")["cells"].has(Vector3i(9, 42, -19)),
			"Atlas AC20 barrel must project from the right torso")
	var wolverine := VxModel.load_file(MODELS[1])
	check(wolverine.part("ra_ac5_shroud")["cells"].has(Vector3i(16, 27, -28)),
			"Wolverine forearm cannon must project independently of shoulder")
	var jenner := VxModel.load_file(MODELS[2])
	check(jenner.part("hd")["cells"].has(Vector3i(0, 28, -31)),
			"Jenner rounded CGL cockpit must project forward of side laser housings")
	check(not jenner.part("ll_hock_joint").is_empty(),
			"Jenner knee and rear hock must be independent geometry")


func test_cgl_plastic_missing_elements_and_open_mouths() -> void:
	# CGL Hansen Atlas shoulder rack is actually built from distinct open mouths.
	var atlas := VxModel.load_file(MODELS[0])
	check(not atlas.part("lt_lrm20_rack").is_empty(), "Atlas needs its left torso LRM rack")
	check_eq(atlas.muzzles[Location.LT].size(), 10,
			"Atlas visible double-column rack must retain ten physical openings")
	for muzzle: Vector3 in atlas.muzzles[Location.LT]:
		var opening := Vector3i(floori(muzzle.x), floori(muzzle.y), ceili(muzzle.z))
		check(not atlas.part("lt_lrm20_rack")["cells"].has(opening),
				"Atlas mouth blocked at %s" % opening)
	var w := VxModel.load_file(MODELS[1])
	check(not w.part("la_shoulder_yoke").is_empty(), "Wolverine left upper-arm joint missing")
	check(not w.part("ra_shoulder_yoke").is_empty(), "Wolverine right upper-arm joint missing")
	var j := VxModel.load_file(MODELS[2])
	check(not j.part("ct_belly_front_apron").is_empty(), "Jenner underslung belly shell missing")
	check(not j.part("lt_rear_exhaust").is_empty(), "Jenner left aft exhaust housing missing")
	check(not j.part("rt_rear_exhaust").is_empty(), "Jenner right aft exhaust housing missing")


func test_plastic_shape_pass47_joint_links_are_real_geometry() -> void:
	# Three material bridges prevent floating limb assemblies and guard the
	# missing mechanical components at our low-resolution approval gate.
	var atlas := VxModel.load_file(MODELS[0])
	for name in ["hd_neck_collar", "ll_hip_socket", "rl_hip_socket",
			"ll_ankle_collar", "rl_ankle_collar"]:
		check(not atlas.part(name).is_empty(), "Atlas component missing: " + name)
	check(atlas.part("ll_hip_socket")["cells"].has(Vector3i(-6, 30, 0)),
			"Atlas left hip bridge is not in the pelvis/upper-leg junction")
	var w := VxModel.load_file(MODELS[1])
	check(not w.part("ra_elbow_link").is_empty(), "Wolverine cannon-side elbow link missing")
	check(w.part("ra_elbow_link")["cells"].has(Vector3i(18, 30, 0)),
			"Wolverine elbow link cannot bridge the upper and lower arm")
	check_eq(w.muzzles[Location.LT].size(), 6, "Wolverine shoulder SRM6 rack")
	for muzzle: Vector3 in w.muzzles[Location.LT]:
		var opening := Vector3i(floori(muzzle.x), floori(muzzle.y), ceili(muzzle.z))
		check(not w.part("lt_srm6")["cells"].has(opening),
				"Wolverine SRM port obstructed at %s" % opening)
	var j := VxModel.load_file(MODELS[2])
	for name in ["ll_hip_link", "rl_hip_link", "ll_hock_joint", "rl_hock_joint"]:
		check(not j.part(name).is_empty(), "Jenner digitigrade joint missing: " + name)
	check(j.part("ll_hip_link")["cells"].has(Vector3i(-6, 24, 0)),
			"Jenner hip link is absent from the lower fuselage")


func test_plastic_pass57_cannon_mount_is_physically_connected() -> void:
	var w := VxModel.load_file(MODELS[1])
	var mount: Dictionary = w.part("ra_cannon_mount").get("cells", {})
	var upper: Dictionary = w.part("ra").get("cells", {})
	var shroud: Dictionary = w.part("ra_ac5_shroud").get("cells", {})
	check(not mount.is_empty(), "Wolverine AC5 diagonal arm mount missing")
	var touches_arm := false
	var touches_shroud := false
	for voxel: Vector3i in mount:
		touches_arm = touches_arm or upper.has(voxel)
		touches_shroud = touches_shroud or shroud.has(voxel)
	check(touches_arm, "Wolverine cannon mount does not actually contact the upper arm")
	check(touches_shroud, "Wolverine cannon mount does not contact the AC5 housing")
	var jenner := VxModel.load_file(MODELS[2])
	for part_name in ["ll_rear_hock_brace", "rl_rear_hock_brace"]:
		check(not jenner.part(part_name).is_empty(), "Jenner side-view hock brace missing")
	var atlas := VxModel.load_file(MODELS[0])
	check(not atlas.part("ct_lower_abdominal_armor").is_empty(),
			"Atlas ribcage/waist armor gap returned")


func test_cgl_plastic_pass57_structural_and_rear_landmarks() -> void:
	# Low-res shape gates from front, side and rear photos of CGL sculpts.
	# These are actual voxel positions, not render-only colored decorations.
	var atlas := VxModel.load_file(MODELS[0])
	var codpiece: Dictionary = atlas.part("pelvis_front_codpiece")
	check(not codpiece.is_empty(), "Atlas lower torso / pelvis missing")
	check(codpiece["cells"].has(Vector3i(0, 26, -8)),
			"Atlas center hip plate not connected beneath the chest")
	var w := VxModel.load_file(MODELS[1])
	var cannon_bridge: Dictionary = w.part("ra_cannon_mount")
	check(not cannon_bridge.is_empty(), "Wolverine forearm gun breech still disconnected")
	check(cannon_bridge["cells"].has(Vector3i(18, 29, -19)),
			"Wolverine cannon bridge does not meet forward housing")
	check(cannon_bridge["cells"].has(Vector3i(18, 38, -5)),
			"Wolverine cannon bridge does not reach upper arm")
	for name in ["ct_left_jump_exhaust", "ct_right_jump_exhaust"]:
		check(not w.part(name).is_empty(), "Wolverine missing rear jump exhaust: " + name)
	var j := VxModel.load_file(MODELS[2])
	for name in ["ll_rear_hock_brace", "rl_rear_hock_brace"]:
		check(not j.part(name).is_empty(), "Jenner hock assembly missing: " + name)
	check(j.part("ll_rear_hock_brace")["cells"].has(Vector3i(-7, 8, 10)),
			"Jenner hock brace not located behind the lower shin")


func test_cgl_twenty_pass_component_shapes_and_clear_bores() -> void:
	# Passes 58-77: compare actual shape cells, not preview mesh colors.
	# These parts are silhouette-defining structures visible from the
	# front, side or rear on CGL plastic, not decorative high-density detail.
	var atlas := VxModel.load_file(MODELS[0])
	for name in ["lt_shoulder_ridge", "rt_shoulder_ridge",
			"ct_rear_left_radiator", "ct_rear_right_radiator",
			"ll_rear_hip_shield", "rl_rear_hip_shield",
			"hd_left_orbit_brow", "hd_right_orbit_brow"]:
		check(not atlas.part(name).is_empty(), "Atlas shape lost: " + name)

	var w := VxModel.load_file(MODELS[1])
	check(not w.part("ct_lower_reactor_spine").is_empty(),
			"Wolverine rear spine no longer physically joins the backpack")
	var left_jet: Dictionary = w.part("ct_left_jump_exhaust")["cells"]
	check(left_jet.has(Vector3i(-5, 45, 11)),
			"Wolverine exhaust missing its inset backing")
	check(not left_jet.has(Vector3i(-5, 45, 14)),
			"Wolverine rear jet aperture accidentally filled")
	check(not w.part("ct_right_jump_exhaust").is_empty(),
			"Wolverine mirrored exhaust missing")

	var jenner := VxModel.load_file(MODELS[2])
	for name in ["ct_rear_reactor_spine", "ll_front_ankle_link",
			"rl_front_ankle_link"]:
		check(not jenner.part(name).is_empty(), "Jenner shape lost: " + name)
	for location in [Location.LA, Location.RA]:
		for i in range(2):
			var muzzle: Vector3 = jenner.muzzles[location][i]
			var part_name := ("la_" if location == Location.LA else "ra_")
			part_name += "laser_lower" if i == 0 else "laser_upper"
			var opening := Vector3i(floori(muzzle.x), floori(muzzle.y),
					ceili(muzzle.z))
			check(not jenner.part(part_name)["cells"].has(opening),
					"Jenner laser opening obstructed: %s %s" % [part_name, opening])


func test_wolverine_single_right_arm_geometry_not_two_right_fists() -> void:
	# The WVR-6R plastic has one AC/5 right arm, not a second
	# free-hanging right fist/forearm parallel to the cannon.
	var d: Dictionary = JsonFile.read(MODELS[1])
	var right_arm_shapes: Array = []
	for part: Dictionary in d["parts"]:
		if part.get("name", "") == "ra":
			right_arm_shapes = part.get("shapes", [])
			break
	check(not right_arm_shapes.is_empty(), "Wolverine RA geometry missing")
	var forearm_profiles := 0
	for shape: Dictionary in right_arm_shapes:
		check(not shape.has("box"),
				"Wolverine RA has another free fist box beside the AC/5")
		if shape.has("loft"):
			var spec: Dictionary = shape["loft"]
			if spec.get("axis", "") == "z":
				var sections: Array = spec.get("sections", [])
				if not sections.is_empty() and int(sections[0]["at"]) < -12:
					forearm_profiles += 1
			if spec.get("axis", "") == "y":
				for section: Dictionary in spec["sections"]:
					check(int(section["at"]) >= 30,
							"Wolverine extra downward gauntlet duplicates the gun arm")
	check_eq(forearm_profiles, 1, "Wolverine should have exactly one AC/5 forearm")
	var m := VxModel.load_file(MODELS[1])
	check_eq(m.muzzles[Location.RA].size(), 1, "Wolverine AC/5 needs one muzzle")


func test_pass_98_to_117_front_and_top_right_arm_identity() -> void:
	# A forward gun barrel is not another lower right fist. Review both
	# true head-on and top-down views; verify source and occupied cells.
	var preview_source := FileAccess.get_file_as_string(
			"res://tools/capture_component_shapes.gd")
	for view_name in ["gallery_three_quarter", "gallery_front",
			"gallery_side", "gallery_rear_three_quarter", "gallery_top_down"]:
		check(preview_source.contains(view_name),
				"Missing required shape-review angle: " + view_name)
	var data: Dictionary = JsonFile.read(MODELS[1])
	var authored_forearms := 0
	for p: Dictionary in data["parts"]:
		if p["name"] != "ra":
			continue
		for s: Dictionary in p.get("shapes", []):
			check(not s.has("box"), "RA must not grow a second fist")
			if not s.has("loft"):
				continue
			var loft: Dictionary = s["loft"]
			if loft["axis"] != "z":
				continue
			var front: int = int(loft["sections"][0]["at"])
			if front < -12:
				authored_forearms += 1
				check(front >= -15,
						"RA armor should stop behind AC5 rather than double its barrel")
	check_eq(authored_forearms, 1, "One RA armor forearm, not two")

	var m := VxModel.load_file(MODELS[1])
	var cannon: Dictionary = m.part("ra_ac5_shroud")["cells"]
	var fist: Dictionary = m.part("la")["cells"]
	var right_arm: Dictionary = m.part("ra")["cells"]
	check(not cannon.is_empty() and not fist.is_empty() and not right_arm.is_empty(),
			"Asymmetric gun arm and fist must all exist")
	var gun_front := 1000
	var fist_front := 1000
	var left_has_fist := false
	var right_has_extra_fist := false
	for cell: Vector3i in cannon:
		gun_front = mini(gun_front, cell.z)
		check(cell.x > 0, "AC5 housing crossed to left side")
	for cell: Vector3i in fist:
		fist_front = mini(fist_front, cell.z)
		left_has_fist = left_has_fist or (cell.x < 0 and cell.y <= 23)
	for cell: Vector3i in right_arm:
		right_has_extra_fist = right_has_extra_fist or (cell.y < 25)
	check(left_has_fist, "Wolverine left fist absent in head-on review")
	check(not right_has_extra_fist, "Wolverine has a second right dangling fist")
	check(gun_front <= fist_front - 9,
			"Top-down silhouette must show a forward AC5, not two fists")
	check_eq(m.muzzles[Location.RA].size(), 1, "one right arm autocannon")
	check_eq(m.muzzles[Location.LT].size(), 6, "six left torso missile openings")


func test_pass_98_to_117_cgl_shape_stage_does_not_add_subdivision() -> void:
	# Geometry remains real component volumes; no fake detail-density step.
	for path: String in MODELS:
		var d: Dictionary = JsonFile.read(path)
		check_eq(d.get("subdivide", -1), 1,
				"Only component forms are under review: " + path)
	var atlas := VxModel.load_file(MODELS[0])
	var wolverine := VxModel.load_file(MODELS[1])
	var jenner := VxModel.load_file(MODELS[2])
	for name in ["hd_jaw", "ct_left_breast_plate", "ct_right_breast_plate",
			"ll_toe_inner", "rl_toe_outer"]:
		check(not atlas.part(name).is_empty(), "Atlas component was lost: " + name)
	for name in ["ra_cannon_mount", "ra_elbow_link", "lt_srm6", "la_shoulder_yoke"]:
		check(not wolverine.part(name).is_empty(), "Wolverine component lost: " + name)
	for name in ["hd_chin_fairing", "la_pod_yoke", "ra_pod_yoke",
			"ll_rear_hock_brace", "rl_front_ankle_link"]:
		check(not jenner.part(name).is_empty(), "Jenner component lost: " + name)
