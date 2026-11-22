extends TestCase
## Only source-format assertions here: don't allocate millions of voxels on CI.

func test_all_shape_studies_have_multiview_review() -> void:
	for file: String in DirAccess.get_files_at("res://data/voxels/"):
		if not file.ends_with("_shape.json"):
			continue
		var source: Dictionary = JsonFile.read("res://data/voxels/" + file)
		check_eq(int(source.get("art_view_passes", 0)), 50, file + " review count")
		check(source.get("art_view_revision", "").begins_with("50-side-rear-top"), file + " view focus")
		var hi := "res://data/voxels/" + file.trim_suffix("_shape.json") + ".json"
		if FileAccess.file_exists(hi):
			var detailed: Dictionary = JsonFile.read(hi)
			check_eq(int(detailed.get("art_view_passes", 0)), 50, hi + " review count")
			check_eq(source.get("unit"), detailed.get("unit"), hi + " unit")

func test_support_assets_keep_hard_fifty_thousand_cap() -> void:
	for file: String in DirAccess.get_files_at("res://data/voxels/assets/"):
		if not file.ends_with(".json"):
			continue
		var source: Dictionary = JsonFile.read("res://data/voxels/assets/" + file)
		check_eq(int(source.get("art_view_passes", 0)), 50, file + " review count")
		check(int(source.get("voxel_cap", 50000)) <= 50000, file + " hard cap")
