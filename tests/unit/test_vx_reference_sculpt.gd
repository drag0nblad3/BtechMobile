extends TestCase
## Regression gates for distinct, hand-authored JSON chassis.
## Counts are final VxModel occupied cells after subdivision and beveling.

const FILES := [
	"res://data/voxels/atlas.json",
	"res://data/voxels/wolverine.json",
	"res://data/voxels/jenner.json",
]


func test_reference_chassis_have_100k_to_150k_real_voxels() -> void:
	for path: String in FILES:
		var model := VxModel.load_file(path)
		check(model.errors.is_empty(), "invalid %s: %s" % [path, model.errors])
		var count := model.cell_count()
		check(count >= 100000 and count <= 150000,
				"%s voxel count %d outside 100k..150k" % [model.id, count])
		check(model.parts.size() >= 12, "%s must use separately rigged parts" % model.id)
		for loc in Location.COUNT:
			check(not model.parts_at(loc).is_empty(),
					"%s lacks hit location %s" % [model.id, Location.code(loc)])


func test_articulated_parts_never_share_cells() -> void:
	for path: String in FILES:
		var model := VxModel.load_file(path)
		var owner := {}
		for part: Dictionary in model.parts:
			for c: Vector3i in part["cells"]:
				check(not owner.has(c), "%s: overlapping %s and %s at %s" %
						[model.id, owner.get(c, ""), part["name"], c])
				owner[c] = part["name"]


func test_authored_muzzle_openings_are_not_painted_over() -> void:
	for path: String in FILES:
		var d: Dictionary = JsonFile.read(path)
		d["subdivide"] = 1
		var model := VxModel.from_dict(d)
		check(model.errors.is_empty(), "coarse model invalid: %s" % path)
		for loc: int in model.muzzles:
			var part_cells: Dictionary = model.parts_at(loc)[0]["cells"]
			for muzzle: Vector3 in model.muzzles[loc]:
				# z is forward-negative; the opening starts at the next whole cell.
				var port := Vector3i(floori(muzzle.x), floori(muzzle.y), ceili(muzzle.z))
				check(not part_cells.has(port),
						"%s blocked %s muzzle at %s" % [model.id, Location.code(loc), port])


func test_individual_silhouettes_preserve_reference_proportions() -> void:
	for path in [FILES[0], FILES[1]]:
		var model := VxModel.load_file(path)
		var xmin := 999999
		var xmax := -999999
		var ymin := 999999
		var ymax := -999999
		for part: Dictionary in model.parts:
			for c: Vector3i in part["cells"]:
				xmin = mini(xmin, c.x)
				xmax = maxi(xmax, c.x)
				ymin = mini(ymin, c.y)
				ymax = maxi(ymax, c.y)
		check((xmax - xmin + 1) * 5 < (ymax - ymin + 1) * 4,
				"%s became broad/squat again" % model.id)
	var jenner := VxModel.load_file(FILES[2])
	check_eq(jenner.legs, "digitigrade")
	check(not jenner.can_punch, "Jenner has weapon nacelles, not fists")
	check(jenner.part("ll_tarsus")["joint"] == "hock", "reverse-knee hock missing")
	check(jenner.part("rl_tarsus")["joint"] == "hock", "other hock missing")
	var nose := 999999
	var torso := 999999
	for c: Vector3i in jenner.part("hd")["cells"]:
		nose = mini(nose, c.z)
	for c: Vector3i in jenner.part("ct")["cells"]:
		torso = mini(torso, c.z)
	check(nose < torso - 10 * jenner.detail, "Jenner cockpit must project far beyond torso")


func test_weapons_have_chassis_specific_openings() -> void:
	var atlas := VxModel.load_file(FILES[0])
	check_eq(atlas.muzzles[Location.LT].size(), 20, "Atlas LRM-20 tube array")
	check_eq(atlas.muzzles[Location.RT].size(), 1, "Atlas RT autocannon bore")
	var wolverine := VxModel.load_file(FILES[1])
	check_eq(wolverine.muzzles[Location.LT].size(), 6, "Wolverine SRM6")
	check_eq(wolverine.muzzles[Location.RA].size(), 1, "Wolverine right-arm AC5")
	var jenner := VxModel.load_file(FILES[2])
	check_eq(jenner.muzzles[Location.CT].size(), 4, "Jenner SRM4")
	check_eq(jenner.muzzles[Location.LA].size(), 2, "left laser pair")
	check_eq(jenner.muzzles[Location.RA].size(), 2, "right laser pair")


func test_reference_mechs_can_build_damageable_animated_rigs() -> void:
	for path: String in FILES:
		var mech := VxMech.from_file(path)
		check(mech.model.errors.is_empty(), "build errors for %s" % path)
		check(mech.voxel_count() >= 100000, "mesh lost authored cells: %s" % path)
		check(mech.triangle_count() > 0, "no rendered triangles: %s" % path)
		check(mech.hips[0] != null and mech.hips[1] != null, "no hips: %s" % path)
		check(mech.knees[0] != null and mech.knees[1] != null, "no knees: %s" % path)
		check(mech.ankles[0] != null and mech.ankles[1] != null, "no ankles: %s" % path)
		if mech.model.legs == "digitigrade":
			check(mech.hocks[0] != null and mech.hocks[1] != null, "digitigrade hocks: %s" % path)
		mech.free()
