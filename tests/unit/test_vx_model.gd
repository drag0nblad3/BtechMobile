extends TestCase
## Claude's text voxel format, record-sheet damage mapping and leg solve.

const PATH := "res://data/voxels/hunchback.json"


func test_hunchback_loads_with_every_location() -> void:
	var m := VxModel.load_file(PATH)
	check(m.errors.is_empty(), "errors: %s" % ", ".join(m.errors))
	for loc in Location.COUNT:
		check(not m.parts_at(loc).is_empty(), "no part for " + Location.code(loc))
	check(m.cell_count() > 20000 and m.cell_count() < 70000, "voxel budget: %d" % m.cell_count())


func test_mirror_flips_cells_and_location() -> void:
	var d: Dictionary = JsonFile.read(PATH)
	d["subdivide"] = 1  # compare authored cells, before bevels
	var m := VxModel.from_dict(d)
	var la := m.part("la")
	var ra := m.part("ra")
	check_eq(ra["loc"], Location.RA)
	check_eq(ra["cells"].size(), la["cells"].size())
	for c: Vector3i in la["cells"]:
		check(ra["cells"].has(Vector3i(-c.x - 1, c.y, c.z)), "mirror missing %s" % c)
		break
	check(m.part("rt")["cells"].size() > m.part("lt")["cells"].size(), "hunch adds to RT")


func test_bad_data_reports_errors() -> void:
	var m := VxModel.from_dict({"materials": [{"name": "a", "color": "fff"}],
			"parts": [{"name": "x", "loc": "ZZ", "shapes": [{"box": [[0, 0, 0], [1, 1, 1]], "mat": "nope"}]}]})
	check(m.errors.size() >= 3, "expected errors, got %s" % m.errors)


func test_damage_matches_record_sheet() -> void:
	var mech := VxMech.from_file(PATH)
	var u := Unit.new(1, designs().get_def("hunchback_hbk4g"), 0, Vector2i.ZERO, 0)
	var full := mech.voxel_count()
	Damage.apply(u, Location.CT, 13)  # half the CT front armor
	mech.show_unit(u)
	var half := full - mech.voxel_count()
	check(half > 0, "CT hit removed nothing")
	check(absi(half - mech.damage.order_size(Location.CT, "a") / 2) <= 1, "half the CT armor voxels gone")
	var again := VxMech.from_file(PATH)
	again.show_unit(u)
	check_eq(again.voxel_count(), mech.voxel_count(), "same sheet, same picture")
	var meshes := {}
	for key: String in mech.parts:
		meshes[key] = mech.parts[key].mesh
	mech.show_unit(u)
	for key: String in mech.parts:
		check(mech.parts[key].mesh == meshes[key], "unchanged record keeps mesh: " + key)
	mech.damage.show_location(Location.CT, 0.0, 0.0, 0.0, false)
	check_eq(mech.voxel_count(), full, "repair restores intact geometry")
	mech.free()
	again.free()


func test_destroyed_arm_drops() -> void:
	var mech := VxMech.from_file(PATH)
	var u := Unit.new(1, designs().get_def("hunchback_hbk4g"), 0, Vector2i.ZERO, 0)
	Damage.apply(u, Location.LA, 60)
	mech.show_unit(u)
	check(mech.lost.has(Location.LA), "LA should be lost")
	check(not mech.is_attached(mech.shoulders[0]), "left arm still attached")
	mech.free()


func test_leg_solve_reaches_foot() -> void:
	for i in 10:
		var f := VxGait.foot(i / 10.0, 0.42, 0.12)
		var a := VxGait.solve(f.x, 0.7 - f.y, 0.35, 0.4)
		var got := VxGait.ankle_of(a.x, a.y, 0.35, 0.4)
		check(got.distance_to(Vector2(f.x, 0.7 - f.y)) < 0.01, "ankle off at phase %d" % i)
		check(is_zero_approx(a.x + a.y + a.z), "foot not level")


func test_catapult_is_digitigrade_and_complete() -> void:
	var m := VxModel.load_file("res://data/voxels/catapult.json")
	check(m.errors.is_empty(), "errors: %s" % ", ".join(m.errors))
	check_eq(m.legs, "digitigrade")
	check_eq(m.muzzles[Location.LA].size(), 15, "every LRM-15 has its own muzzle")
	check_eq(m.muzzles[Location.RA].size(), 15, "mirrored LRM-15 needs fifteen muzzles")
	check(designs().get_def(m.unit_id) != null, "unit id must exist")
	var mech := VxMech.from_file("res://data/voxels/catapult.json")
	check(mech.hocks[0] != null and mech.hocks[1] != null, "hocks found")
	check(mech.tarsus > 0.0, "tarsus length")
	mech.free()


func test_reverse_knee_bends_backward() -> void:
	var a := VxGait.solve(0.0, 0.6, 0.45, 0.45, true)
	check(a.x < 0.0, "digitigrade thigh leans back")
	check(a.y > 0.0, "digitigrade knee bends the other way")
	var got := VxGait.ankle_of(a.x, a.y, 0.45, 0.45)
	check(got.distance_to(Vector2(0.0, 0.6)) < 0.01, "reaches target")


func test_subdivide_scales_grid() -> void:
	var d: Dictionary = JsonFile.read(PATH)
	d["subdivide"] = 1
	var coarse := VxModel.from_dict(d)
	var fine := VxModel.load_file(PATH)
	check_eq(fine.detail, 2)
	check(is_equal_approx(fine.voxel_size * 2.0, coarse.voxel_size), "voxel size halves")
	check_eq(fine.part("la")["pivot"], coarse.part("la")["pivot"] * 2.0)
	check(fine.cell_count() > coarse.cell_count() * 6, "about 8x cells after bevels")


func test_greedy_mesh_merges_faces() -> void:
	var mech := VxMech.from_file(PATH)
	var faces := 0
	for p: VxPart in mech.parts.values():
		faces += p.faces_before_merge
	check(mech.triangle_count() < faces, "merged %d tris vs %d faces" % [mech.triangle_count(), faces])
	mech.free()


func test_claude_catapult_launcher_holes_align_with_all_30_muzzles() -> void:
	# Check the authored (coarse) grid; subdivide would scale every coordinate.
	var d: Dictionary = JsonFile.read("res://data/voxels/catapult.json")
	d["subdivide"] = 1
	var m := VxModel.from_dict(d)
	check(m.errors.is_empty(), "Catapult JSON should load without errors")
	for loc in [Location.LA, Location.RA]:
		var name := "la" if loc == Location.LA else "ra"
		var p: Dictionary = m.part(name)
		var cells: Dictionary = p["cells"]
		var points: Array = m.muzzles[loc]
		check_eq(points.size(), VxVolley.MISSILES,
				"visual port count and missile salvo should match")
		var unique: Dictionary = {}
		for point: Vector3 in points:
			var x := floori(point.x)
			var y := floori(point.y)
			var opening := Vector3i(x, y, ceili(point.z))
			unique[opening] = true
			check(not cells.has(opening) and not cells.has(opening + Vector3i(0, 0, 1)),
					"missile must emerge through a real two-cell-deep opening: " + str(opening))
			check(cells.has(opening + Vector3i(0, 1, 0)),
					"each port should have armor separating it from the next row")
		check_eq(unique.size(), points.size(), "each muzzle needs a distinct open tube")
	var left: Dictionary = m.part("la")["cells"]
	var right: Dictionary = m.part("ra")["cells"]
	var left_torso: Dictionary = m.part("lt")["cells"]
	var right_torso: Dictionary = m.part("rt")["cells"]
	for c: Vector3i in left:
		check(not left_torso.has(c), "left pod should clear its parent torso")
	for c: Vector3i in right:
		check(not right_torso.has(c), "mirrored right pod should clear its parent")
	check_eq(left.size(), right.size(), "both racks should share the same shell")
	for c: Vector3i in left:
		check(right.has(Vector3i(-c.x - 1, c.y, c.z)),
				"right launcher geometry must mirror the left")

## The following tests check rig relationships and dimensionless silhouette
## properties. A proportional resculpt or a changed grid origin must still pass.

func test_mirror_inherits_the_reflected_parent() -> void:
	var m := VxModel.new()
	m._mat["frame"] = 0
	m.colors.append(Color.WHITE)
	m.roles.append("structure")
	for spec in [
		{"name": "ct", "loc": "CT"},
		{"name": "lt", "loc": "LT", "parent": "ct"},
		{"name": "rt", "mirror": "lt", "parent": "ct"},
		{"name": "left_detail", "loc": "LT", "parent": "lt"},
		{"name": "right_detail", "mirror": "left_detail"},
		{"name": "left_collar", "loc": "CT", "parent": "ct"},
		{"name": "right_collar", "mirror": "left_collar"},
		{"name": "manual", "mirror": "left_detail", "parent": "ct"}
	]:
		m._add_part(spec)
	check_eq(m.part("right_detail")["parent"], m.part("rt")["name"],
			"mirrored accessory must move with the reflected shoulder")
	check_eq(m.part("right_collar")["parent"], m.part("ct")["name"],
			"midline accessory stays attached to midline")
	check_eq(m.part("manual")["parent"], m.part("ct")["name"],
			"explicit parent overrides reflected default")


func test_cannon_arm_preserves_weapon_and_rig_without_source_part_counts() -> void:
	var d: Dictionary = JsonFile.read("res://data/voxels/wolverine_shape.json")
	var m := VxModel.from_dict(d)
	check(m.muzzles.has(Location.RA), "cannon muzzle is still present")
	check(not m.parts_at(Location.RA).is_empty(), "gun arm retains its damage location")
	var arm: Dictionary = m.part("ra")
	check(arm.has("pivot") and not arm.get("cells", {}).is_empty(),
			"gun arm remains articulated and occupied")
	# No coordinate or exact count of sculpt details is pinned here.
	for part: Dictionary in m.parts_at(Location.RA):
		if part["name"] != arm["name"]:
			check(part["parent"] != "", "weapon accessories must follow an arm joint")


func test_forward_disc_has_rounded_relative_width() -> void:
	var d: Dictionary = JsonFile.read("res://data/voxels/jenner_shape.json")
	var head: Dictionary = {}
	for part: Dictionary in d["parts"]:
		if part.get("name", "") == "hd":
			head = part
	var broadest := 0.0
	var leading_width := 0.0
	for shape: Dictionary in head.get("shapes", []):
		if not shape.has("loft") or shape["loft"].get("axis", "") != "z":
			continue
		var sections: Array = shape["loft"]["sections"]
		var max_width := 0.0
		for section: Dictionary in sections:
			max_width = maxf(max_width, _profile_width(section["polygon"]))
		if max_width > broadest:
			broadest = max_width
			leading_width = _profile_width(sections[0]["polygon"])
	check(broadest > 0.0 and leading_width / maxf(1.0, broadest) >= 0.45,
			"forward disc should not collapse to a narrow beak")


func _profile_width(points: Array) -> float:
	var low := INF
	var high := -INF
	for point: Array in points:
		low = minf(low, float(point[0]))
		high = maxf(high, float(point[0]))
	return high - low
