extends TestCase
## Shape-stage ownership audit: deliberate joints may interpenetrate,
## but duplicate full-body shells and a second Wolverine forearm may not.

const ATLAS := "res://data/voxels/atlas_shape.json"
const WOLVERINE := "res://data/voxels/wolverine_shape.json"
const JENNER := "res://data/voxels/jenner_shape.json"


func _shared(a: Dictionary, b: Dictionary) -> int:
	var count := 0
	for cell: Vector3i in a:
		if b.has(cell):
			count += 1
	return count


func test_atlas_shoulder_trim_has_exposed_surface() -> void:
	var m := VxModel.load_file(ATLAS)
	check(m.errors.is_empty(), "Atlas silhouette invalid")
	var shoulder: Dictionary = m.part("lt")["cells"]
	for trim in ["lt_round_shoulder_underplate", "lt_round_shoulder_band"]:
		var cells: Dictionary = m.part(trim)["cells"]
		var shared := _shared(shoulder, cells)
		check(cells.size() - shared > 38, "Atlas " + trim + " is buried inside the old shell")
		check(shared < 390, "Atlas " + trim + " is another nearly whole overlapping shoulder")
	check(not m.part("ct_skull_well").is_empty(), "keep intentional recessed skull support")


func test_wolverine_has_single_cannon_arm_not_two_buried_arms() -> void:
	var d: Dictionary = JsonFile.read(WOLVERINE)
	var ra: Dictionary = {}
	for part: Dictionary in d["parts"]:
		if part["name"] == "ra":
			ra = part
	check_eq(ra.get("shapes", []).size(), 2, "upper arm plus one bent cannon forearm")
	var m := VxModel.from_dict(d)
	check(m.errors.is_empty(), "Wolverine silhouette invalid")
	var arm: Dictionary = m.part("ra")["cells"]
	var spar: Dictionary = m.part("ra_cannon_mount")["cells"]
	var hand: Dictionary = m.part("ra_integrated_hand")["cells"]
	var gun: Dictionary = m.part("ra_ac5_shroud")["cells"]
	check(_shared(arm, spar) > 20, "upper arm lost its bent cannon bridge")
	check(_shared(arm, spar) < 420, "cannon bridge buried in a second giant forearm")
	check(_shared(hand, spar) > 8, "hand disconnected from gun-bearing bridge")
	check(_shared(hand, gun) > 8, "hand disconnected from cannon")
	check(spar.has(Vector3i(18, 29, -19)), "breech landmark lost")
	check(spar.has(Vector3i(18, 38, -5)), "elbow landmark lost")


func test_jenner_disc_edges_are_trim_not_a_duplicate_saucer() -> void:
	var d: Dictionary = JsonFile.read(JENNER)
	var m := VxModel.from_dict(d)
	check(m.errors.is_empty(), "Jenner silhouette invalid")
	check(m.part("hd_forward_glass_strip").is_empty(), "old doubled glazing remains")
	var disc: Dictionary = m.part("hd")["cells"]
	var rim: Dictionary = m.part("hd_disc_rim")["cells"]
	check(_shared(disc, rim) < 300, "a second entire saucer occupies the primary head")
	check(rim.size() > 80, "disc edge lost after reducing overlapping bulk")
	check(disc.has(Vector3i(0, 26, -36)), "forward disc nose lost")
	check(not m.part("hd_front_windscreen").is_empty(), "main windscreen must remain")
