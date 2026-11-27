extends TestCase
## Recognizability additions must be sculpted, attached geometry rather than
## loose emission voxels or decorations that cannot follow the articulated rig.


func test_six_reference_signature_recipes_load_at_both_detail_levels() -> void:
	for chassis: String in ["cyclops", "thunderbolt", "firestarter",
			"phoenix_hawk", "hel", "ymir"]:
		var shape_name := "res://data/voxels/%s_shape.json" % chassis
		var final_name := "res://data/voxels/%s.json" % chassis
		var source: Dictionary = VxRecipeStore.read(shape_name)
		var detailed: Dictionary = VxRecipeStore.read(final_name)
		check(not String(source.get("silhouette_signature_revision", "")).is_empty(),
				"%s has an authored silhouette correction" % chassis)
		check_eq(source.get("silhouette_signature_revision", ""),
				detailed.get("silhouette_signature_revision", ""),
				"%s has matching coarse and detailed signature geometry" % chassis)
		for path: String in [shape_name, final_name]:
			var m := VxModel.load_file(path)
			check(m.errors.is_empty(), "%s loads without geometry errors" % path)
			check(m.cell_count() > 0, "%s has visible geometry" % path)


func test_signature_weapon_mounts_physically_touch_their_parent_assembly() -> void:
	# Uses physical adjacency, not a fixed pivot coordinate or voxel count.
	for chassis: String in ["hel", "ymir"]:
		var m := VxModel.load_file("res://data/voxels/%s_shape.json" % chassis)
		var count := 0
		for part: Dictionary in m.parts:
			var name: String = part.get("name", "")
			if not name.contains("_signature_"):
				continue
			count += 1
			var parent_name: String = part.get("parent", "")
			var parent: Dictionary = m.part(parent_name)
			check(not parent.is_empty(),
					"%s %s uses a real named rig parent" % [chassis, name])
			if parent.is_empty():
				continue
			check(not part["cells"].is_empty(),
					"%s %s contains real geometry" % [chassis, name])
			check(VxIntegrity._touch(part["cells"], parent["cells"]),
					"%s %s is supported and moves with the correct parent" % [chassis, name])
		check(count > 0, "%s has a specific, not generic, weapon mount" % chassis)
