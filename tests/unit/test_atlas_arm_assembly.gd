extends TestCase
## Atlas AS7-D lower-arm silhouette guard: one gauntlet + one glove per side.
## The original source mistakenly stacked second finger/thumb solids inside the arm.

const ATLAS := "res://data/voxels/atlas_shape.json"


func _shared(a: Dictionary, b: Dictionary) -> int:
	var count := 0
	for cell: Vector3i in a:
		if b.has(cell):
			count += 1
	return count


func _part_source(parts: Array, name: String) -> Dictionary:
	for part: Dictionary in parts:
		if part.get("name", "") == name:
			return part
	return {}


func test_atlas_arm_is_one_raised_gauntlet_and_one_fist_per_side() -> void:
	var source: Dictionary = JsonFile.read(ATLAS)
	check_eq(int(source.get("subdivide", -1)), 1, "Arm modeling must stay in shape stage")
	var arm: Dictionary = _part_source(source.get("parts", []), "la")
	var right_arm: Dictionary = _part_source(source.get("parts", []), "ra")
	var fingers: Dictionary = _part_source(source.get("parts", []), "la_finger_knuckles")
	var thumb: Dictionary = _part_source(source.get("parts", []), "la_outer_thumb_pad")
	check_eq(arm.get("shapes", []).size(), 4,
			"Atlas left arm should have upper arm, elbow, gauntlet, one fist")
	check_eq(right_arm.get("mirror", ""), "la",
			"Atlas right arm must mirror the cleaned left-arm assembly")
	for shape: Dictionary in arm.get("shapes", []):
		check(shape.has("loft"), "Duplicate box fingers/thumbs returned inside Atlas arm")
	check_eq(fingers.get("shapes", []).size(), 3,
			"Atlas fist has exactly three separate knuckle blocks, not an extra thumb")
	check_eq(thumb.get("shapes", []).size(), 1,
			"Atlas must have one integrated outer thumb, not two")
	var profiles: Array = arm["shapes"][2]["loft"]["sections"]
	check(profiles.front()["at"] >= 30,
			"Atlas gauntlet starts too low near its knee")
	check(arm["shapes"][3]["loft"]["sections"].front()["at"] >= 28,
			"Atlas fist drooped to the knee again")


func test_atlas_arms_have_connected_and_visible_wrist_components() -> void:
	var model := VxModel.load_file(ATLAS)
	check(model.errors.is_empty(), "Atlas arm geometry malformed")
	var arm: Dictionary = model.part("la")["cells"]
	var right_arm: Dictionary = model.part("ra")["cells"]
	var socket: Dictionary = model.part("la_rotator_socket")["cells"]
	var cuff: Dictionary = model.part("la_knuckle_cuff")["cells"]
	var fingers: Dictionary = model.part("la_finger_knuckles")["cells"]
	var thumb: Dictionary = model.part("la_outer_thumb_pad")["cells"]
	check_eq(arm.size(), right_arm.size(),
			"Left and right Atlas arms should have symmetric authoring geometry")
	check(_shared(arm, socket) > 25,
			"Atlas shoulder bearing is disconnected")
	check(_shared(arm, cuff) > 10 and cuff.size() - _shared(arm, cuff) > 10,
			"Atlas wrist collar is buried or no longer attached")
	check(_shared(arm, fingers) > 6,
			"Atlas knuckle blocks float below the raised fist")
	check(_shared(arm, thumb) > 8 and thumb.size() - _shared(arm, thumb) > 8,
			"Atlas thumb is buried or floats off to the side")
	var min_y := 999
	for cell: Vector3i in arm:
		min_y = mini(min_y, cell.y)
	check(min_y >= 28,
			"Atlas base-arm profile has returned to the knee-length pose")
