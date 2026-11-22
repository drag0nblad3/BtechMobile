extends TestCase
## Front view is the primary shape approval projection for passes 276-295.
## These guards operate on the existing shape-stage voxel occupancy only to
## measure source contours, not to change the geometry or its subdivision.

const ATLAS := "res://data/voxels/atlas_shape.json"
const WOLVERINE := "res://data/voxels/wolverine_shape.json"
const JENNER := "res://data/voxels/jenner_shape.json"


func _band(model: VxModel, data: Dictionary, row_y: int) -> Dictionary:
	var minimum := 999
	var maximum := -999
	var seen := {}
	for part: Dictionary in data["parts"]:
		var cells: Dictionary = model.part(part["name"])["cells"]
		for cell: Vector3i in cells:
			if cell.y == row_y:
				minimum = mini(minimum, cell.x)
				maximum = maxi(maximum, cell.x)
				seen[cell.x] = true
	if seen.is_empty():
		return {"count": 0, "span": 0}
	return {"count": seen.size(), "span": maximum - minimum + 1}


func _shared(a: Dictionary, b: Dictionary) -> int:
	var count := 0
	for k: Vector3i in a:
		if b.has(k):
			count += 1
	return count


func test_front_silhouette_stage_is_still_geometry_only() -> void:
	for path: String in [ATLAS, WOLVERINE, JENNER]:
		var source: Dictionary = JsonFile.read(path)
		check_eq(int(source.get("subdivide", -1)), 1,
				"Front silhouette must pass review before any voxel subdivision")
		var model := VxModel.from_dict(source)
		check(model.errors.is_empty(),
				"Invalid authored loft after front contour passes: " + path)


func test_atlas_round_shoulders_have_an_arch_not_square_column_tops() -> void:
	var source: Dictionary = JsonFile.read(ATLAS)
	var a := VxModel.from_dict(source)
	var top := _band(a, source, 54)
	var chest := _band(a, source, 50)
	check(top["count"] > 0 and top["count"] < 15,
			"Atlas shoulder crest went back to two flat full-width rooftops")
	check(chest["span"] >= 34,
			"Atlas chest and shoulders no longer form the broad crescent arch")
	var lt: Dictionary = a.part("lt")["cells"]
	var head: Dictionary = a.part("hd")["cells"]
	check(_shared(a.part("ct")["cells"], head) > 50,
			"Atlas skull floated out of its chest recess")
	check(_shared(a.part("la")["cells"],
			a.part("la_rotator_socket")["cells"]) > 20,
			"Atlas short fist/forearm no longer connects to its shoulder bearing")
	check(a.part("la")["cells"].size() == a.part("ra")["cells"].size(),
			"Atlas lower arms accidentally lost their mirrored silhouette")


func test_wolverine_front_has_chest_width_but_only_one_cannon_arm() -> void:
	var source: Dictionary = JsonFile.read(WOLVERINE)
	var w := VxModel.from_dict(source)
	check(_band(w, source, 44)["span"] >= 39,
			"Wolverine shoulder/chest width collapsed in front view")
	var right_arm_shape_count := -1
	for p: Dictionary in source["parts"]:
		if p["name"] == "ra":
			right_arm_shape_count = p["shapes"].size()
	check_eq(right_arm_shape_count, 2,
			"Wolverine must retain one upper arm and ONE diagonal gun forearm")
	var mount: Dictionary = w.part("ra_cannon_mount")["cells"]
	var hand: Dictionary = w.part("ra_integrated_hand")["cells"]
	var gun: Dictionary = w.part("ra_ac5_shroud")["cells"]
	check(_shared(mount, w.part("ra")["cells"]) > 25,
			"Wolverine arm disconnected from cannon mount")
	check(_shared(mount, hand) > 20 and _shared(gun, hand) > 20,
			"Wolverine hand stopped gripping its same AC5 gun")
	check_eq(w.muzzles[Location.LT].size(), 6,
			"Wolverine shoulder launcher changed or lost missile ports")


func test_jenner_front_disc_keeps_width_without_tall_block_head() -> void:
	var source: Dictionary = JsonFile.read(JENNER)
	var j := VxModel.from_dict(source)
	var disc: Dictionary = j.part("hd")["cells"]
	var min_x := 999
	var max_x := -999
	for cell: Vector3i in disc:
		min_x = mini(min_x, cell.x)
		max_x = maxi(max_x, cell.x)
	check_eq(max_x - min_x + 1, 20,
			"Jenner saucer diameter no longer matches its plastic sculpt")
	check(disc.has(Vector3i(0, 26, -36)),
			"Jenner forward disc nose is missing")
	check(_band(j, source, 27)["span"] >= 32,
			"Jenner side pods collapsed into the narrow main body")
	check(_shared(disc, j.part("hd_disc_rim")["cells"]) > 20,
			"Jenner saucer rim disconnected from cockpit")
	check(_shared(j.part("ll_shin")["cells"],
			j.part("ll_hock_joint")["cells"]) > 8,
			"Jenner shin lost the digitigrade hock bend")
	check(j.part("ll_rear_hock_brace")["cells"].has(Vector3i(-7, 8, 10)),
			"Jenner rear hock brace no longer has its load-bearing landmark")
