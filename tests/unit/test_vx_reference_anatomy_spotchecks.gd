extends TestCase
## Named silhouette regressions not expressible as a generic sculpt profile.

const DIRECTIONS := [
	Vector3i.LEFT, Vector3i.RIGHT, Vector3i.UP, Vector3i.DOWN,
	Vector3i.FORWARD, Vector3i.BACK
]


func _source_model(chassis: String) -> VxModel:
	var raw: Dictionary = JsonFile.read("res://data/voxels/%s_shape.json" % chassis)
	raw["subdivide"] = 1
	return VxModel.from_dict(raw)


func test_jenner_head_disc_has_broad_structural_neck_contact() -> void:
	var model := _source_model("jenner")
	check(model.errors.is_empty(), "Jenner must remain loadable")
	var head: Dictionary = model.part("hd")
	var torso: Dictionary = model.part("ct")
	if head.is_empty() or torso.is_empty():
		check(false, "Jenner requires a head and central torso")
		return
	var supported := {}
	var backed := {}
	for cell: Vector3i in head["cells"]:
		for direction: Vector3i in DIRECTIONS:
			if torso["cells"].has(cell + direction):
				supported[cell] = true
				if head["cells"].has(cell - direction):
					backed[cell] = true
				break
	check(supported.size() >= 4, "Jenner disc needs broad neck contact")
	check(backed.size() >= 2, "Jenner disc connector needs solid internal depth")


func test_atlas_keeps_both_real_fist_volumes() -> void:
	var model := _source_model("atlas")
	check(model.errors.is_empty(), "Atlas must remain loadable")
	for side: String in ["la", "ra"]:
		var arm: Dictionary = model.part(side)
		check(not arm.is_empty(), "Atlas lost %s arm" % side)
		if arm.is_empty():
			continue
		check(arm["cells"].size() > 40,
				"Atlas %s needs a real fist and forearm, not a decorative piece" % side)
