extends TestCase
## Source-level rig and silhouette geometry checks for the eleventh twenty.

const SHAPE_ONLY := ["atlas", "jenner"]
const PAIRED := [
	"akuma", "albatross", "argus", "caesar", "chimera", "crockett",
	"devastator", "emperor", "excalibur", "falconer", "firebee", "flea",
	"grizzly", "gunslinger", "havoc", "hel", "helios", "hellspawn"
]
const PRIMARY := ["ct", "lt", "la", "ll_shin"]
const NEIGHBORS := [
	Vector3i.LEFT, Vector3i.RIGHT, Vector3i.UP, Vector3i.DOWN,
	Vector3i.FORWARD, Vector3i.BACK
]


func _recipe(chassis: String, suffix: String) -> Dictionary:
	return JsonFile.read("res://data/voxels/%s%s.json" % [chassis, suffix])


func _part(data: Dictionary, name: String) -> Dictionary:
	for p: Dictionary in data.get("parts", []):
		if p.get("name", "") == name:
			return p
	return {}


func _loft(part: Dictionary) -> Dictionary:
	for shape: Dictionary in part.get("shapes", []):
		if shape.has("loft"):
			return shape["loft"]
	return {}


func _model(chassis: String) -> VxModel:
	var d := _recipe(chassis, "_shape")
	d["subdivide"] = 1
	return VxModel.from_dict(d)


func test_two_quality_tiers_keep_same_anatomical_lofts() -> void:
	for chassis: String in PAIRED:
		var shape := _recipe(chassis, "_shape")
		var high := _recipe(chassis, "")
		check_eq(shape["unit"], high["unit"], "wrong model pair %s" % chassis)
		check_eq(shape["legs"], high["legs"], "changed leg rig %s" % chassis)
		for name: String in PRIMARY:
			var a := _loft(_part(shape, name))
			var b := _loft(_part(high, name))
			check(not a.is_empty() and not b.is_empty(), "missing loft %s/%s" % [
					chassis, name])
			check(a == b, "mismatched sculpt volumes %s/%s" % [chassis, name])


func test_all_refined_models_keep_animated_hit_locations() -> void:
	for chassis: String in SHAPE_ONLY + PAIRED:
		var m := _model(chassis)
		check(m.errors.is_empty(), "load errors %s: %s" % [chassis, m.errors])
		for loc in Location.COUNT:
			check(not m.parts_at(loc).is_empty(), "missing location %s in %s" % [
					Location.code(loc), chassis])


func test_jenner_forward_disc_has_a_broad_supported_neck() -> void:
	var model := _model("jenner")
	var head: Dictionary = model.part("hd")
	var torso: Dictionary = model.part("ct")
	var supported := {}
	var backed := {}
	for cell: Vector3i in head["cells"]:
		for side: Vector3i in NEIGHBORS:
			if torso["cells"].has(cell + side):
				supported[cell] = true
				if head["cells"].has(cell - side):
					backed[cell] = true
				break
	check(supported.size() >= 4, "Jenner forward disc has no broad torso contact")
	check(backed.size() >= 2, "Jenner head connector has no internal depth")


func test_atlas_fists_are_real_components_in_both_mirrored_arms() -> void:
	var model := _model("atlas")
	for name: String in ["la", "ra"]:
		var arm: Dictionary = model.part(name)
		check(not arm.is_empty(), "missing Atlas arm %s" % name)
		if arm.is_empty():
			continue
		var cells: Dictionary = arm["cells"]
		check(cells.size() > 40, "Atlas %s lost its fist/arm volume" % name)


func test_digitigrade_scouts_keep_reverse_joint_profiles() -> void:
	for chassis: String in ["flea", "chimera", "hellspawn"]:
		check_eq(_recipe(chassis, "_shape")["legs"], "digitigrade",
				"digitigrade type changed %s" % chassis)
