extends TestCase
## Source-geometry guards for direct FRONT silhouette modeling cycles 276-295.
## These inspect authored contour sections, not post-voxel decorative detail.

const ATLAS := "res://data/voxels/atlas_shape.json"
const WOLVERINE := "res://data/voxels/wolverine_shape.json"
const JENNER := "res://data/voxels/jenner_shape.json"


func _part(source: Dictionary, part_name: String) -> Dictionary:
	for p: Dictionary in source["parts"]:
		if p["name"] == part_name:
			return p
	return {}


func _span_x(polygon: Array) -> int:
	var min_x := 1000
	var max_x := -1000
	for xy: Array in polygon:
		min_x = mini(min_x, int(xy[0]))
		max_x = maxi(max_x, int(xy[0]))
	return max_x - min_x


func test_front_silhouette_remains_unsubdivided_geometry() -> void:
	for path in [ATLAS, WOLVERINE, JENNER]:
		var source: Dictionary = JsonFile.read(path)
		check_eq(int(source.get("subdivide", -1)), 1,
				"Approve front geometry before voxel density: " + path)
		var model := VxModel.from_dict(source)
		check(model.errors.is_empty(), "Malformed authored silhouette: " + path)


func test_atlas_shoulder_is_wide_rounded_crown_not_point_or_flat_box() -> void:
	var a: Dictionary = JsonFile.read(ATLAS)
	var shoulder: Dictionary = _part(a, "lt")
	var cap: Array = shoulder["shapes"][0]["loft"]["sections"][2]["polygon"]
	var top_width_count := 0
	for xy: Array in cap:
		if int(xy[1]) >= 55:
			top_width_count += 1
	check(top_width_count >= 2,
			"Atlas shoulder crown became a pointed spike in front view")
	check(_span_x(cap) >= 9,
			"Atlas shoulder dome lost its characteristic broad shell")
	check_eq(_part(a, "ra")["mirror"], "la",
			"Preserve repaired matching Atlas forearms and single fists")
	var model := VxModel.load_file(ATLAS)
	var left_arm: Dictionary = model.part("la")["cells"]
	var low_y := 999
	for v: Vector3i in left_arm:
		low_y = mini(low_y, v.y)
	check(low_y >= 28, "Atlas lower arms once again descend to knee-level")
	check(model.part("rt_ac20_shroud")["cells"].has(Vector3i(9, 42, -19)),
			"Atlas torso weapon landmark moved during shoulder work")


func test_wolverine_keeps_broad_feet_and_one_connected_cannon_arm() -> void:
	var w: Dictionary = JsonFile.read(WOLVERINE)
	var boot: Array = _part(w, "ll_foot")["shapes"][0]["loft"]["sections"]
	check(_span_x(boot[2]["polygon"]) >= 7,
			"Wolverine front-view feet became narrow triangular wedges")
	check(_span_x(boot[3]["polygon"]) >= 4,
			"Wolverine ankle boot tapers too abruptly")
	check_eq(_part(w, "ra")["shapes"].size(), 2,
			"Wolverine must have one upper arm and one bent gun forearm")
	var m := VxModel.from_dict(w)
	var hand: Dictionary = m.part("ra_integrated_hand")["cells"]
	var cannon: Dictionary = m.part("ra_ac5_shroud")["cells"]
	var grips := false
	for v: Vector3i in hand:
		if cannon.has(v):
			grips = true
			break
	check(grips, "Gun-bearing Wolverine hand detached in front-silhouette work")


func test_jenner_front_disc_protrudes_under_wide_hull_and_hocks_remain() -> void:
	var j := VxModel.load_file(JENNER)
	var disc: Dictionary = j.part("hd")["cells"]
	check(disc.has(Vector3i(0, 26, -36)),
			"Jenner's defining protruding disc nose is gone")
	var lo := 999
	var hi := -999
	for p: Vector3i in disc:
		lo = mini(lo, p.x)
		hi = maxi(hi, p.x)
	check_eq(hi - lo + 1, 20,
			"Jenner frontal disc diameter changed")
	check(j.part("ll_rear_hock_brace")["cells"].has(Vector3i(-7, 8, 10)),
			"Jenner reverse-bend rear hock connection disappeared")
