extends TestCase
## Shape-stage guards for the Atlas, Wolverine and Jenner sculpts
## (`data/voxels/*_shape.json`) and their high-resolution voxel versions.
## Geometry only: no damage, density quality or game rules. One test per
## chassis holds every landmark the review passes established.

const ATLAS := "res://data/voxels/atlas_shape.json"
const WOLVERINE := "res://data/voxels/wolverine_shape.json"
const JENNER := "res://data/voxels/jenner_shape.json"
const MODELS := [ATLAS, WOLVERINE, JENNER]


func _shared(a: Dictionary, b: Dictionary) -> int:
	var n := 0
	for cell: Vector3i in a:
		if b.has(cell):
			n += 1
	return n


func _source_part(source: Dictionary, part_name: String) -> Dictionary:
	for p: Dictionary in source["parts"]:
		if p["name"] == part_name:
			return p
	return {}


func _cells(m: VxModel, part_name: String) -> Dictionary:
	return m.part(part_name).get("cells", {})


func _has_parts(m: VxModel, names: Array) -> void:
	for n: String in names:
		check(not m.part(n).is_empty(), "%s lost part %s" % [m.id, n])


func _open_mouths(m: VxModel, loc: int, part_name: String, count: int) -> void:
	check_eq(m.muzzles[loc].size(), count, "%s %s ports" % [m.id, part_name])
	for muzzle: Vector3 in m.muzzles[loc]:
		var mouth := Vector3i(floori(muzzle.x), floori(muzzle.y), ceili(muzzle.z))
		check(not _cells(m, part_name).has(mouth), "%s bore blocked at %s" % [part_name, mouth])


func _x_span(cells: Dictionary) -> int:
	var lo := 999
	var hi := -999
	for c: Vector3i in cells:
		lo = mini(lo, c.x)
		hi = maxi(hi, c.x)
	return hi - lo + 1


func _row_span(m: VxModel, source: Dictionary, row_y: int) -> Dictionary:
	var lo := 999
	var hi := -999
	var seen := {}
	for p: Dictionary in source["parts"]:
		for c: Vector3i in _cells(m, p["name"]):
			if c.y == row_y:
				lo = mini(lo, c.x)
				hi = maxi(hi, c.x)
				seen[c.x] = true
	return {"count": seen.size(), "span": 0 if seen.is_empty() else hi - lo + 1}


func _poly_span_x(polygon: Array) -> int:
	var xs: Array = polygon.map(func(v: Array) -> int: return int(v[0]))
	return xs.max() - xs.min()


func test_shape_sources_are_coarse_valid_and_complete() -> void:
	for path: String in MODELS:
		var d: Dictionary = JsonFile.read(path)
		check_eq(int(d.get("subdivide", -1)), 1, "no subdivision in the shape gate: " + path)
		var lofts := 0
		for part: Dictionary in d["parts"]:
			for op: Dictionary in part.get("shapes", []):
				if op.has("loft"):
					lofts += 1
					check(op["loft"]["sections"].size() >= 2, "loft needs two profiles")
		check(lofts >= 12, "authored contours: " + path)
		var m := VxModel.from_dict(d)
		check(m.errors.is_empty(), "invalid shape %s: %s" % [path, m.errors])
		check(m.cell_count() > 1200 and m.cell_count() < 32000, "coarse budget %d" % m.cell_count())
		for loc in Location.COUNT:
			check(not m.parts_at(loc).is_empty(), "%s missing %s" % [m.id, Location.code(loc)])
	var preview := FileAccess.get_file_as_string("res://tools/capture_component_shapes.gd")
	for view in ["gallery_three_quarter", "gallery_front", "gallery_side",
			"gallery_rear_three_quarter", "gallery_top_down"]:
		check(preview.contains(view), "shape review angle " + view)


func test_loft_rasterization_tapers_and_interpolates() -> void:
	var box := {"materials": [{"name": "form", "color": "b5b9bc", "role": "armor"}],
		"parts": [{"name": "ct", "loc": "CT", "shapes": [{"loft": {"axis": "y", "sections": [
			{"at": 0, "polygon": [[-1, -1], [1, -1], [1, 1], [-1, 1]]},
			{"at": 4, "polygon": [[-4, -2], [4, -2], [4, 2], [-4, 2]]}]}, "mat": "form"}]}]}
	var coarse: Dictionary = VxModel.from_dict(box).part("ct")["cells"]
	check(coarse.has(Vector3i(0, 0, 0)) and coarse.has(Vector3i(3, 4, 0)), "loft ends")
	check(not coarse.has(Vector3i(3, 0, 0)), "loft tapers, not a box")
	var fine_src := {"id": "fine_taper", "voxel_size": 0.05, "subdivide": 2,
		"voxelize_lofts": true, "materials": [{"name": "armor", "color": "778899", "role": "armor"}],
		"parts": [{"name": "ct", "loc": "CT", "shapes": [{"loft": {"axis": "y", "sections": [
			{"at": 0, "polygon": [[-1.3, -1], [1.3, -1], [1.3, 1], [-1.3, 1]]},
			{"at": 4, "polygon": [[-5.3, -1], [5.3, -1], [5.3, 1], [-5.3, 1]]}]}, "mat": "armor"}]}]}
	var fine: Dictionary = VxModel.from_dict(fine_src).part("ct")["cells"]
	# Splitting coarse cells into eight identical cubes would fail this.
	check(fine.has(Vector3i(5, 3, 0)), "interpolated half-slice contour")
	check(not fine.has(Vector3i(5, 2, 0)), "taper not duplicated cells")


func test_atlas_shape() -> void:
	var src: Dictionary = JsonFile.read(ATLAS)
	var a := VxModel.from_dict(src)
	_has_parts(a, ["pelvis", "hd_cheek_left", "hd_cheek_right", "hd_neck_collar", "hd_jaw",
		"ll_hip_socket", "rl_hip_socket", "ll_ankle_collar", "rl_ankle_collar",
		"ct_lower_abdominal_armor", "lt_shoulder_ridge", "rt_shoulder_ridge",
		"ct_rear_left_radiator", "ct_rear_right_radiator", "ll_rear_hip_shield",
		"rl_rear_hip_shield", "hd_left_orbit_brow", "hd_right_orbit_brow",
		"ct_left_breast_plate", "ct_right_breast_plate", "ll_toe_inner", "rl_toe_outer",
		"ll_knee_guard", "ll_shin", "rl_shin", "ll_toe_outer", "la_finger_knuckles",
		"ra_finger_knuckles", "la_outer_thumb_pad", "ra_outer_thumb_pad",
		"lt_round_shoulder_band", "rt_round_shoulder_band", "hd_skull_recess",
		"hd_lower_mandible", "la_rotator_socket", "ra_rotator_socket", "lt_lrm_cradle",
		"ct_left_clavicle", "ct_right_clavicle", "ct_skull_well"])
	# Weapons: one AC/20 bore, ten open LRM mouths.
	_open_mouths(a, Location.RT, "rt_ac20_shroud", 1)
	_open_mouths(a, Location.LT, "lt_lrm20_rack", 10)
	check(_cells(a, "rt_ac20_shroud").has(Vector3i(9, 42, -19)), "AC/20 projects from the torso")
	check(_cells(a, "ll_hip_socket").has(Vector3i(-6, 30, 0)), "hip bridge in the junction")
	check(_cells(a, "pelvis_front_codpiece").has(Vector3i(0, 26, -6)), "codpiece meets the chest")
	# Head sunk between rounded shoulders, shallow torso.
	var crown: int = _source_part(src, "hd")["shapes"][0]["loft"]["sections"].back()["at"]
	var shoulder: Array = _source_part(src, "lt")["shapes"][0]["loft"]["sections"]
	var shoulder_y := -1
	for s: Dictionary in shoulder:
		for pt: Array in s["polygon"]:
			shoulder_y = maxi(shoulder_y, pt[1])
	check(shoulder_y > crown and shoulder_y <= crown + 4, "shoulders just above the skull")
	check(shoulder.size() >= 6, "six sculpted shoulder sections")
	check(shoulder[0]["polygon"][0][0] != shoulder[1]["polygon"][0][0], "no square shoulder wall")
	var cap: Array = shoulder[2]["polygon"]
	check(cap.filter(func(v: Array) -> bool: return int(v[1]) >= 55).size() >= 2, "crown not a spike")
	check(_poly_span_x(cap) >= 9, "broad shoulder shell")
	var top := _row_span(a, src, 54)
	check(top["count"] > 0 and top["count"] < 15, "no flat shoulder rooftops")
	check(_row_span(a, src, 50)["span"] >= 34, "broad chest arch")
	for part_name in ["ct", "lt", "hd"]:
		var lo := 999
		var hi := -999
		for shape: Dictionary in _source_part(src, part_name)["shapes"]:
			if not shape.has("loft"):
				continue
			for sec: Dictionary in shape["loft"]["sections"]:
				if shape["loft"]["axis"] == "z":
					lo = mini(lo, sec["at"])
					hi = maxi(hi, sec["at"])
				elif shape["loft"]["axis"] == "y":
					for xy: Array in sec["polygon"]:
						lo = mini(lo, xy[1])
						hi = maxi(hi, xy[1])
		check(hi - lo <= {"ct": 12, "lt": 16, "hd": 23}[part_name], "Atlas %s depth" % part_name)
	check(_shared(_cells(a, "ct"), _cells(a, "hd")) > 50, "skull recessed into the chest")
	for trim in ["lt_round_shoulder_underplate", "lt_round_shoulder_band"]:
		var shared := _shared(_cells(a, "lt"), _cells(a, trim))
		check(shared > 10 and shared < 315, trim + " anchored, not a second shell")
		check(_cells(a, trim).size() - shared > 38, trim + " exposed")
	# Arms: one gauntlet and one fist a side, mirrored, raised above the knee.
	var arm: Dictionary = _source_part(src, "la")
	check_eq(arm["shapes"].size(), 4, "upper arm, elbow, gauntlet, fist")
	for shape: Dictionary in arm["shapes"]:
		check(shape.has("loft"), "no stray box fingers in the arm")
	check(arm["shapes"][2]["loft"]["sections"].front()["at"] >= 30, "gauntlet height")
	check(arm["shapes"][3]["loft"]["sections"].front()["at"] >= 28, "fist height")
	check_eq(_source_part(src, "ra")["mirror"], "la", "right arm mirrors the left")
	check_eq(_source_part(src, "la_finger_knuckles")["shapes"].size(), 3, "three knuckles")
	check_eq(_source_part(src, "la_outer_thumb_pad")["shapes"].size(), 1, "one thumb")
	var la := _cells(a, "la")
	check_eq(la.size(), _cells(a, "ra").size(), "symmetric arms")
	var low_y := 999
	for c: Vector3i in la:
		low_y = mini(low_y, c.y)
	check(low_y >= 28, "arms don't hang to the knee")
	check(_shared(la, _cells(a, "la_rotator_socket")) > 25, "shoulder bearing attached")
	for p in [["la_knuckle_cuff", 12], ["la_finger_knuckles", 8], ["la_outer_thumb_pad", 10]]:
		var shared := _shared(la, _cells(a, p[0]))
		check(shared > p[1], p[0] + " meets the forearm")
	for p in ["la_knuckle_cuff", "la_outer_thumb_pad"]:
		check(_cells(a, p).size() - _shared(la, _cells(a, p)) > 8, p + " not buried")


func test_wolverine_shape() -> void:
	var src: Dictionary = JsonFile.read(WOLVERINE)
	var w := VxModel.from_dict(src)
	_has_parts(w, ["pelvis", "la_shoulder_yoke", "ra_shoulder_yoke", "ra_elbow_link",
		"ct_left_jump_exhaust", "ct_right_jump_exhaust", "ct_lower_reactor_spine",
		"ct_rear_jump_pack", "ra_integrated_hand", "la_finger_knuckles", "ct_wide_abdomen",
		"ct_lower_breastplate", "ra_grip_knuckles", "hd_angular_cheek_left",
		"hd_angular_cheek_right", "ra_compact_elbow_armor", "hd_neck_yoke", "ra_gun_grip_thumb"])
	_open_mouths(w, Location.LT, "lt_srm6", 6)
	for muzzle: Vector3 in w.muzzles[Location.LT]:
		check(is_equal_approx(muzzle.z, -15.5), "SRM muzzles on the open face")
	check_eq(w.muzzles[Location.RA].size(), 1, "one AC/5 muzzle")
	check(_shared(_cells(w, "lt"), _cells(w, "lt_srm6_inner_mount")) > 5, "launcher attached")
	var jet := _cells(w, "ct_left_jump_exhaust")
	check(jet.has(Vector3i(-5, 45, 11)) and not jet.has(Vector3i(-5, 45, 14)), "open jet nozzle")
	# The WVR-6R has ONE bent right gun arm: upper arm + one forward forearm.
	var ra: Array = _source_part(src, "ra")["shapes"]
	check_eq(ra.size(), 2, "one upper arm and one gun forearm")
	for shape: Dictionary in ra:
		check(shape.has("loft") and shape["loft"]["axis"] == "z", "no hanging second forearm")
		var front: int = int(shape["loft"]["sections"][0]["at"])
		check(front >= -15, "arm armor stops behind the AC/5")
	check(_source_part(src, "ra_integrated_hand")["shapes"][0]["loft"]["sections"][0]["at"] <= -20,
			"hand grips behind the shroud")
	check(_source_part(src, "ra_cannon_mount")["shapes"][0]["loft"]["sections"].size() >= 6,
			"stepped cannon mount")
	var upper := _cells(w, "ra")
	var mount := _cells(w, "ra_cannon_mount")
	var hand := _cells(w, "ra_integrated_hand")
	var gun := _cells(w, "ra_ac5_shroud")
	check(_shared(upper, mount) > 50 and _shared(upper, mount) < 340, "mount joins the arm")
	check(_shared(hand, mount) > 20 and _shared(hand, gun) > 20, "hand grips the AC/5")
	check(_shared(_cells(w, "ra_elbow_link"), upper) > 0, "elbow joins the upper arm")
	check(_cells(w, "ra_elbow_link").has(Vector3i(18, 38, -7)), "raised elbow")
	check(mount.has(Vector3i(18, 29, -19)) and mount.has(Vector3i(18, 38, -5)), "breech-elbow spar")
	check(_cells(w, "ra_ac5_shroud").has(Vector3i(16, 27, -28)), "cannon projects forward")
	var gun_front := 1000
	for c: Vector3i in gun:
		gun_front = mini(gun_front, c.z)
		check(c.x > 0, "AC/5 stays on the right")
	var fist_front := 1000
	var left_fist := false
	for c: Vector3i in _cells(w, "la"):
		fist_front = mini(fist_front, c.z)
		left_fist = left_fist or (c.x < 0 and c.y <= 23)
	check(left_fist, "left fist present")
	check(gun_front <= fist_front - 9, "gun reaches well past the fist")
	for c: Vector3i in upper:
		check(c.y >= 25, "no second right fist")
	# Broad waist, chest and feet.
	var waist := 0
	for s: Dictionary in _source_part(src, "ct")["shapes"][0]["loft"]["sections"]:
		if s["at"] == 36:
			waist = _poly_span_x(s["polygon"])
	check(waist >= 12 and waist <= 16, "broad waist")
	check(_row_span(w, src, 44)["span"] >= 39, "chest width")
	var boot: Array = _source_part(src, "ll_foot")["shapes"][0]["loft"]["sections"]
	check(_poly_span_x(boot[2]["polygon"]) >= 7 and _poly_span_x(boot[3]["polygon"]) >= 4, "boots")


func test_jenner_shape() -> void:
	var src: Dictionary = JsonFile.read(JENNER)
	var j := VxModel.from_dict(src)
	_has_parts(j, ["belly", "ll_hock_joint", "rl_hock_joint", "ct_belly_front_apron",
		"lt_rear_exhaust", "rt_rear_exhaust", "ll_hip_link", "rl_hip_link",
		"ll_rear_hock_brace", "rl_rear_hock_brace", "ct_rear_reactor_spine",
		"ll_front_ankle_link", "rl_front_ankle_link", "hd_chin_fairing", "la_pod_yoke",
		"ra_pod_yoke", "ll_tarsus", "rl_tarsus", "hd_disc_rim", "hd_disc_crown",
		"hd_front_windscreen", "hd_disc_lower_fairing", "hd_disc_neck_brace",
		"hd_left_disc_crescent", "hd_right_disc_crescent", "hd_top_glass_left",
		"hd_top_glass_right", "lt_disc_bridge", "rt_disc_bridge", "hd_rear_disc_saddle",
		"hd_left_disc_strut", "hd_right_disc_strut"])
	check(j.part("hd_forward_glass_strip").is_empty(), "old doubled glazing gone")
	check_eq(j.muzzles[Location.CT].size(), 4, "SRM-4")
	for loc in [Location.LA, Location.RA]:
		check_eq(j.muzzles[loc].size(), 2, "paired lasers")
		var side := "la_" if loc == Location.LA else "ra_"
		for i in 2:
			var m: Vector3 = j.muzzles[loc][i]
			var mouth := Vector3i(floori(m.x), floori(m.y), ceili(m.z))
			var part_name := side + ("laser_lower" if i == 0 else "laser_upper")
			check(not _cells(j, part_name).has(mouth), part_name + " open")
	check(_cells(j, "ll_hip_link").has(Vector3i(-6, 24, 0)), "hip link in the fuselage")
	check(_cells(j, "ll_rear_hock_brace").has(Vector3i(-7, 8, 10)), "hock brace behind the shin")
	check(_shared(_cells(j, "ll_shin"), _cells(j, "ll_hock_joint")) > 8, "reverse-bend hock")
	# A flat disc nose ahead of the lasers, about half the pod span.
	var disc := _cells(j, "hd")
	check(disc.has(Vector3i(0, 26, -36)), "disc nose ahead of the lasers")
	check_eq(_x_span(disc), 20, "disc diameter")
	var nose: Array = _source_part(src, "hd")["shapes"][0]["loft"]["sections"]
	check_eq(nose[0]["at"], -36, "nose section")
	check_eq(nose.back()["at"], -19, "disc stops short of mid-body")
	check(nose[1]["polygon"][0][0] < nose[0]["polygon"][0][0], "saucer flares behind the nose")
	for s: Dictionary in nose:
		if s["at"] == -31:
			var dia := _poly_span_x(s["polygon"])
			check(dia >= 16 and dia <= 20, "disc about half the pod span")
	check(_row_span(j, src, 27)["span"] >= 32, "side pods keep their width")
	var rim := _cells(j, "hd_disc_rim")
	check(rim.size() > 80, "rim present")
	check(_shared(disc, rim) > 20 and _shared(disc, rim) < 200, "rim is trim, not a second disc")


func test_high_resolution_models_follow_their_shapes() -> void:
	for chassis: String in ["atlas", "wolverine", "jenner"]:
		var raw := VxModel.load_file("res://data/voxels/%s_shape.json" % chassis)
		var m := VxModel.load_file("res://data/voxels/%s_voxel.json" % chassis)
		check(m.errors.is_empty(), "high-res model valid: " + chassis)
		check_eq(m.detail, 2, "twice the authored resolution")
		check_eq(m.parts.size(), raw.parts.size(), "same components")
		check(is_equal_approx(m.voxel_size * 2.0, raw.voxel_size), "same dimensions")
		check(m.cell_count() > raw.cell_count() * 5, "dense rasterization")
		check(m.cell_count() >= 100000 and m.cell_count() <= 200000, "high-res budget")
		for part: Dictionary in raw.parts:
			var fine: Dictionary = m.part(part["name"])
			check(not fine.is_empty() and fine["cells"].size() > 0, "fine " + part["name"])
			check(fine["pivot"].is_equal_approx(part["pivot"] * 2.0), "pivot " + part["name"])
		var source: Dictionary = JsonFile.read("res://data/voxels/%s_shape.json" % chassis)
		for p: Dictionary in source["parts"]:
			if not p.has("mirror"):
				continue
			var a := _cells(m, p["mirror"])
			var b := _cells(m, p["name"])
			check_eq(a.size(), b.size(), "mirrored cell count " + p["name"])
			if p.get("add", []).is_empty():
				for c: Vector3i in a:
					check(b.has(Vector3i(-c.x - 1, c.y, c.z)), "reflected cell in " + p["name"])
