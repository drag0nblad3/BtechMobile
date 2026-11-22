extends TestCase
## Whole-catalog source and 50k support-asset quality gate.

func test_all_shape_first_mechs_have_50_passes_and_matching_primary_contours() -> void:
	var seen := 0
	for filename: String in DirAccess.get_files_at("res://data/voxels"):
		if not filename.ends_with("_shape.json"):
			continue
		var id := filename.trim_suffix("_shape.json")
		var low: Dictionary = JsonFile.read("res://data/voxels/" + filename)
		check_eq(int(low.get("art_quality_passes", 0)), 50, id + " 50-pass source")
		seen += 1
		var high_path := "res://data/voxels/" + id + ".json"
		if not FileAccess.file_exists(high_path):
			continue
		var high: Dictionary = JsonFile.read(high_path)
		if high.has("source") and not high.has("parts"):
			continue
		check_eq(int(high.get("art_quality_passes", 0)), 50, id + " high LOD")
		var low_parts := {}
		for part: Dictionary in low.get("parts", []):
			low_parts[part["name"]] = part
		for part: Dictionary in high.get("parts", []):
			if part.has("mirror") or not low_parts.has(part["name"]):
				continue
			var a: Dictionary = low_parts[part["name"]]
			var a_shapes: Array = a.get("shapes", [])
			var b_shapes: Array = part.get("shapes", [])
			for i in mini(a_shapes.size(), b_shapes.size()):
				if a_shapes[i].has("loft") and b_shapes[i].has("loft"):
					check_eq(a_shapes[i]["loft"], b_shapes[i]["loft"],
						"%s %s low-high contour" % [id, part["name"]])
	check(seen >= 151, "151 shape-first BattleMech models must be covered")


func test_all_support_asset_recipes_keep_50000_voxel_limit() -> void:
	var seen := 0
	for filename: String in DirAccess.get_files_at("res://data/voxels/assets"):
		if not filename.ends_with(".json"):
			continue
		var d: Dictionary = JsonFile.read("res://data/voxels/assets/" + filename)
		check_eq(int(d.get("art_quality_passes", 0)), 50, filename + " pass count")
		check(int(d.get("voxel_cap", 50000)) <= 50000, filename + " declared cap")
		var m := VoxelAsset.model_from_dict(d)
		check(m.errors.is_empty(), "%s loader errors %s" % [filename, m.errors])
		check(m.cell_count() <= 50000, filename + " exceeds voxel budget")
		seen += 1
	check_eq(seen, 16, "all sixteen support archetypes")
