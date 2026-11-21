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
	check(jenner.part("hd")["cells"].has(Vector3i(0, 28, -36)),
			"Jenner CGL disc nose must reach z=-42, well ahead of side lasers")
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
	check(w.part("ra_elbow_link")["cells"].has(Vector3i(18, 38, -7)),
			"Wolverine raised elbow must bend from shoulder into the forward AC5 arm")
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


func test_coordinated_passes_118_127_keep_asymmetric_components() -> void:
	# Ten review cycles touch all three geometry sources. Protect the
	# physical chassis-defining parts rather than merely their preview tint.
	var atlas := VxModel.load_file(MODELS[0])
	var wolverine := VxModel.load_file(MODELS[1])
	var jenner := VxModel.load_file(MODELS[2])
	for model in [atlas, wolverine, jenner]:
		check(model.errors.is_empty(), "invalid model: " + model.id)
	for name in ["hd_jaw", "hd_cheek_left", "hd_cheek_right",
			"lt_shoulder_ridge", "rt_shoulder_ridge",
			"ct_left_breast_plate", "ct_right_breast_plate",
			"rt_ac20_shroud", "ll_knee_guard"]:
		check(not atlas.part(name).is_empty(), "Atlas missing part: " + name)
	for name in ["la", "ra", "ra_cannon_mount", "ra_elbow_link",
			"ra_ac5_shroud", "lt_srm6", "ct_rear_jump_pack"]:
		check(not wolverine.part(name).is_empty(), "Wolverine missing part: " + name)
	for name in ["hd", "la_laser_lower", "la_laser_upper", "ra_laser_lower",
			"ra_laser_upper", "ll_hock_joint", "rl_hock_joint",
			"ll_tarsus", "rl_tarsus", "ct_rear_reactor_spine"]:
		check(not jenner.part(name).is_empty(), "Jenner missing part: " + name)
	check_eq(wolverine.muzzles[Location.RA].size(), 1, "Wolverine AC5")
	check_eq(wolverine.muzzles[Location.LT].size(), 6, "Wolverine SRM6")
	check_eq(jenner.muzzles[Location.LA].size(), 2, "Jenner left lasers")
	check_eq(jenner.muzzles[Location.RA].size(), 2, "Jenner right lasers")
	check_eq(jenner.muzzles[Location.CT].size(), 4, "Jenner SRM4")
	check_eq(atlas.muzzles[Location.RT].size(), 1, "Atlas AC20")
	check_eq(atlas.muzzles[Location.LT].size(), 10, "Atlas rocket ports")


func test_passes_128_to_132_resculpted_silhouette_landmarks() -> void:
	# Large hand-defined section replacements, not cosmetic mesh bevels.
	var a: Dictionary = JsonFile.read(MODELS[0])
	var w: Dictionary = JsonFile.read(MODELS[1])
	var j: Dictionary = JsonFile.read(MODELS[2])
	var shoulder: Array = []
	for part: Dictionary in a["parts"]:
		if part["name"] == "lt":
			shoulder = part["shapes"][0]["loft"]["sections"]
	check(shoulder.size() >= 6, "Atlas rounded shoulder cowl needs six sculpted sections")
	check(shoulder[0]["polygon"][0][0] != shoulder[1]["polygon"][0][0],
			"Atlas must not have a rectangular continuous shoulder wall")
	var mount: Array = []
	for part: Dictionary in w["parts"]:
		if part["name"] == "ra_cannon_mount":
			mount = part["shapes"][0]["loft"]["sections"]
	check(mount.size() >= 6, "Wolverine cannon mount needs a stepped armor profile")
	var nose: Array = []
	for part: Dictionary in j["parts"]:
		if part["name"] == "hd":
			nose = part["shapes"][0]["loft"]["sections"]
	check_eq(nose[0]["at"], -36, "Jenner disc must project ahead of laser nacelles")
	check(nose[1]["polygon"][0][0] < nose[0]["polygon"][0][0],
			"Jenner saucer must flare behind its blunt nose")


func test_passes_128_to_137_weapon_arm_and_limb_structure_remain_sound() -> void:
	# The new component forms must still be physical occupied cells.
	var atlas := VxModel.load_file(MODELS[0])
	var w := VxModel.load_file(MODELS[1])
	var jenner := VxModel.load_file(MODELS[2])
	for model in [atlas, w, jenner]:
		check(model.errors.is_empty(), "invalid resculpt model " + model.id)
	var mount: Dictionary = w.part("ra_cannon_mount")["cells"]
	var arm: Dictionary = w.part("ra")["cells"]
	var housing: Dictionary = w.part("ra_ac5_shroud")["cells"]
	var touch_arm := false
	var touch_gun := false
	for v: Vector3i in mount:
		touch_arm = touch_arm or arm.has(v)
		touch_gun = touch_gun or housing.has(v)
	check(touch_arm, "Wolverine right upper arm no longer meets cannon elbow")
	check(touch_gun, "Wolverine AC5 bore housing detached")
	check_eq(w.muzzles[Location.RA].size(), 1, "Wolverine right arm has one cannon")
	check_eq(w.muzzles[Location.LT].size(), 6, "Wolverine left SRM6 must remain")
	for name in ["ll_shin", "rl_shin", "ll_toe_outer", "rl_toe_outer",
			"ct_left_breast_plate", "ct_right_breast_plate"]:
		check(not atlas.part(name).is_empty(), "Atlas missing " + name)
	for name in ["ll_tarsus", "rl_tarsus", "ll_hock_joint", "rl_hock_joint",
			"la_laser_lower", "ra_laser_lower", "la_laser_upper",
			"ra_laser_upper"]:
		check(not jenner.part(name).is_empty(), "Jenner missing " + name)


func test_bold_reference_passes_138_to_142_fix_fundamental_silhouette() -> void:
	var a := VxModel.load_file(MODELS[0])
	var w := VxModel.load_file(MODELS[1])
	var j := VxModel.load_file(MODELS[2])
	for model in [a, w, j]:
		check(model.errors.is_empty(), "Invalid major rebuild " + model.id)
	# The Atlas skull crown must now be BELOW the rounded shoulder crests.
	var atlas_source: Dictionary = JsonFile.read(MODELS[0])
	var crown := -1
	var left_shoulder := -1
	for p: Dictionary in atlas_source["parts"]:
		if p["name"] == "hd":
			crown = p["shapes"][0]["loft"]["sections"].back()["at"]
		if p["name"] == "lt":
			for s: Dictionary in p["shapes"][0]["loft"]["sections"]:
				for pt: Array in s["polygon"]:
					left_shoulder = maxi(left_shoulder, pt[1])
	check(crown < left_shoulder, "Atlas skull still floats above the shoulder bells")
	check(not a.part("la_finger_knuckles").is_empty(), "Atlas left fingers absent")
	check(not a.part("ra_finger_knuckles").is_empty(), "Atlas right fingers absent")
	# Broader Wolverine waist at y=36 with a single right hand behind AC5.
	var ct_source: Dictionary = JsonFile.read(MODELS[1])
	var waist_width := -1
	for p: Dictionary in ct_source["parts"]:
		if p["name"] == "ct":
			for s: Dictionary in p["shapes"][0]["loft"]["sections"]:
				if s["at"] == 36:
					var xs: Array = s["polygon"].map(func(v: Array) -> int: return v[0])
					waist_width = xs.max() - xs.min()
	check(waist_width >= 12, "Wolverine still has a pinched hourglass abdomen")
	check(not w.part("ra_integrated_hand").is_empty(), "Wolverine missing right hand")
	check(not w.part("la_finger_knuckles").is_empty(), "Wolverine missing left hand")
	# True disc is not a short orange beak: compare its diameter to torso width.
	var disc_source: Dictionary = JsonFile.read(MODELS[2])
	var diameter := 0
	for p: Dictionary in disc_source["parts"]:
		if p["name"] == "hd":
			for s: Dictionary in p["shapes"][0]["loft"]["sections"]:
				if s["at"] == -31:
					var x: Array = s["polygon"].map(func(v: Array) -> int: return v[0])
					diameter = x.max() - x.min()
	check(diameter >= 16 and diameter <= 20, "Jenner disc should be ~half the overall nacelle span")
	check(j.part("hd")["cells"].has(Vector3i(0, 28, -36)),
			"Jenner disc must protrude forward of its twin laser mounts")
	check(not j.part("hd_disc_rim").is_empty(), "Jenner disc edge absent")
	check(not j.part("hd_disc_crown").is_empty(), "Jenner disc dome absent")


func test_passes_143_to_147_reference_structure_and_usable_muzzles() -> void:
	var a := VxModel.load_file(MODELS[0])
	var w := VxModel.load_file(MODELS[1])
	var j := VxModel.load_file(MODELS[2])
	for m in [a, w, j]:
		check(m.errors.is_empty(), "invalid final staged sculpt " + m.id)
	for name in ["la_finger_knuckles", "ra_finger_knuckles",
			"la_outer_thumb_pad", "ra_outer_thumb_pad",
			"lt_round_shoulder_band", "rt_round_shoulder_band",
			"hd_skull_recess", "hd_lower_mandible"]:
		check(not a.part(name).is_empty(), "Atlas silhouette part lost " + name)
	for name in ["ct_wide_abdomen", "ct_lower_breastplate", "ra_integrated_hand",
			"ra_grip_knuckles", "la_finger_knuckles",
			"hd_angular_cheek_left", "hd_angular_cheek_right"]:
		check(not w.part(name).is_empty(), "Wolverine part lost " + name)
	for name in ["hd_disc_rim", "hd_disc_crown", "hd_front_windscreen",
			"hd_disc_lower_fairing", "hd_disc_neck_brace",
			"hd_left_disc_crescent", "hd_right_disc_crescent",
			"hd_top_glass_left", "hd_top_glass_right"]:
		check(not j.part(name).is_empty(), "Jenner disc subpart lost " + name)
	check_eq(w.muzzles[Location.LT].size(), 6, "Compact 2x3 Wolverine SRM6")
	for muzzle: Vector3 in w.muzzles[Location.LT]:
		check(is_equal_approx(muzzle.z, -15.5), "Compact Wolverine launcher muzzle must lie at the open face, not float forward")
	var rack: Dictionary = w.part("lt_srm6")["cells"]
	for barrel: Vector3 in w.muzzles[Location.LT]:
		var aperture := Vector3i(floori(barrel.x), floori(barrel.y), ceili(barrel.z))
		check(not rack.has(aperture), "Wolverine compact launcher closed port %s" % aperture)
	check(j.part("hd")["cells"].has(Vector3i(0, 28, -36)),
			"Jenner forward saucer must remain z=-36")
	check_eq(a.muzzles[Location.RT].size(), 1, "Atlas AC20")


func test_proportion_passes_148_152_are_balanced_and_connected() -> void:
	var atlas_source: Dictionary = JsonFile.read(MODELS[0])
	var w_source: Dictionary = JsonFile.read(MODELS[1])
	var j_source: Dictionary = JsonFile.read(MODELS[2])
	var atlas_head_y := 0
	var shoulder_y := 0
	for p: Dictionary in atlas_source["parts"]:
		if p["name"] == "hd":
			atlas_head_y = p["shapes"][0]["loft"]["sections"].back()["at"]
		if p["name"] == "lt":
			for s: Dictionary in p["shapes"][0]["loft"]["sections"]:
				for q: Array in s["polygon"]:
					shoulder_y = maxi(shoulder_y, q[1])
	check(shoulder_y >= atlas_head_y and shoulder_y <= atlas_head_y + 4,
			"Atlas shoulders must be level with, but slightly higher than, sunk head")
	var torso_width := 0
	for p: Dictionary in w_source["parts"]:
		if p["name"] != "ct":
			continue
		for s: Dictionary in p["shapes"][0]["loft"]["sections"]:
			if s["at"] == 36:
				var xs: Array = s["polygon"].map(func(v: Array) -> int: return v[0])
				torso_width = xs.max() - xs.min()
	check(torso_width >= 12 and torso_width <= 16,
			"Wolverine waist must be broad, not an egg-shaped or pinched plate")
	var disc_width := 0
	for p: Dictionary in j_source["parts"]:
		if p["name"] != "hd":
			continue
		for s: Dictionary in p["shapes"][0]["loft"]["sections"]:
			if s["at"] == -31:
				var xs: Array = s["polygon"].map(func(v: Array) -> int: return v[0])
				disc_width = xs.max() - xs.min()
	check(disc_width >= 16 and disc_width <= 20,
			"Jenner canopy must be a modest disc compared to side-pod span")
	var w := VxModel.load_file(MODELS[1])
	check(not w.part("ra_compact_elbow_armor").is_empty(),
			"AC5 forearm must be visibly attached to the shoulder by a compact elbow")
	var j := VxModel.load_file(MODELS[2])
	check(j.part("hd")["cells"].has(Vector3i(0, 28, -36)),
			"Jenner disc must still protrude ahead of the twin laser muzzles")


func test_passes_153_to_157_assembly_proportions_and_open_ports() -> void:
	var atlas := VxModel.load_file(MODELS[0])
	var w := VxModel.load_file(MODELS[1])
	var j := VxModel.load_file(MODELS[2])
	for m in [atlas, w, j]:
		check(m.errors.is_empty(), "Invalid final proportional sculpt: " + m.id)
	for name in ["la_rotator_socket", "ra_rotator_socket", "lt_lrm_cradle",
			"la_finger_knuckles", "ra_finger_knuckles"]:
		check(not atlas.part(name).is_empty(), "Atlas missing interface " + name)
	for name in ["ra_compact_elbow_armor", "hd_neck_yoke",
			"ra_integrated_hand", "la_finger_knuckles"]:
		check(not w.part(name).is_empty(), "Wolverine missing interface " + name)
	for name in ["lt_disc_bridge", "rt_disc_bridge", "hd_disc_neck_brace",
			"hd_front_windscreen", "hd_disc_crown"]:
		check(not j.part(name).is_empty(), "Jenner missing interface " + name)
	var src: Dictionary = JsonFile.read(MODELS[2])
	var nose := -99
	var back := -99
	var diameter := 0
	for item: Dictionary in src["parts"]:
		if item["name"] == "hd":
			var ss: Array = item["shapes"][0]["loft"]["sections"]
			nose = ss[0]["at"]
			back = ss.back()["at"]
			for sec: Dictionary in ss:
				for pt: Array in sec["polygon"]:
					diameter = maxi(diameter, absi(pt[0]) * 2)
	check_eq(nose, -36, "Jenner saucer must project in front of the laser pods")
	check_eq(back, -19, "Jenner disc must not extend to the middle of its body")
	check(diameter >= 16 and diameter <= 20 and back - nose <= 20,
			"Jenner cockpit must be disc-like in top view, not a long loaf")
	check_eq(w.muzzles[Location.LT].size(), 6, "Wolverine SRM6")
	for muzzle: Vector3 in w.muzzles[Location.LT]:
		var mouth := Vector3i(floori(muzzle.x), floori(muzzle.y), ceili(muzzle.z))
		check(not w.part("lt_srm6")["cells"].has(mouth),
				"Wolverine smaller SRM6 must have open mouths %s" % mouth)
	check_eq(atlas.muzzles[Location.LT].size(), 10, "Atlas LRM rack")
	for muzzle: Vector3 in atlas.muzzles[Location.LT]:
		var mouth := Vector3i(floori(muzzle.x), floori(muzzle.y), ceili(muzzle.z))
		check(not atlas.part("lt_lrm20_rack")["cells"].has(mouth),
				"Atlas shoulder rack opening blocked %s" % mouth)


func test_passes_158_162_no_second_right_arm_and_hand_grips_one_gun() -> void:
	var source: Dictionary = JsonFile.read(MODELS[1])
	var right: Array = []
	var hand: Array = []
	for p: Dictionary in source["parts"]:
		if p["name"] == "ra":
			right = p["shapes"]
		if p["name"] == "ra_integrated_hand":
			hand = p["shapes"]
	check_eq(right.size(), 2, "Exactly one Wolverine upper arm and one gun forearm")
	for op: Dictionary in right:
		check(op.has("loft") and op["loft"]["axis"] == "z",
				"No hanging vertical arm profile beneath AC5")
	check(hand[0]["loft"]["sections"][0]["at"] <= -20,
			"Wolverine hand must grip behind the gun shroud, not hang near torso")
	var model := VxModel.load_file(MODELS[1])
	check(model.errors.is_empty(), "Wolverine gun-arm rebuild invalid")
	var palm: Dictionary = model.part("ra_integrated_hand")["cells"]
	var mount: Dictionary = model.part("ra_cannon_mount")["cells"]
	var barrel: Dictionary = model.part("ra_ac5_shroud")["cells"]
	var upper: Dictionary = model.part("ra")["cells"]
	var palm_gun := false
	var palm_mount := false
	var elbow_upper := false
	for pos: Vector3i in palm:
		palm_gun = palm_gun or barrel.has(pos)
		palm_mount = palm_mount or mount.has(pos)
	for pos: Vector3i in model.part("ra_elbow_link")["cells"]:
		elbow_upper = elbow_upper or upper.has(pos)
	check(palm_gun and palm_mount, "Wolverine right hand must grip the same autocannon")
	check(elbow_upper, "Wolverine bent elbow must join the upper arm")
	check_eq(model.muzzles[Location.RA].size(), 1, "Wolverine exactly one AC5")


func test_passes_168_to_172_keep_single_wolverine_right_arm_and_disc() -> void:
	var w := VxModel.load_file(MODELS[1])
	var j := VxModel.load_file(MODELS[2])
	check(not w.part("ra_gun_grip_thumb").is_empty(),
			"Wolverine same-arm AC5 gripping thumb must be present")
	var d: Dictionary = JsonFile.read(MODELS[1])
	for part_source: Dictionary in d["parts"]:
		if part_source["name"] == "ra":
			check_eq(part_source["shapes"].size(), 2,
					"No additional hanging Wolverine right arm/forearm")
			for geometry: Dictionary in part_source["shapes"]:
				check(geometry.has("loft") and geometry["loft"]["axis"] == "z",
						"Right arm remains bent toward the forward AC5")
	check(not j.part("hd_rear_disc_saddle").is_empty(),
			"Jenner disc-to-hull rear attachment absent")
