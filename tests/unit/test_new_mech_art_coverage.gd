extends TestCase
## All recent sculpt sources must have detailed display counterparts, and
## visibly different official variants must not overwrite another's art.

func test_new_shape_sculpts_have_matching_unit_and_detail_manifest() -> void:
	var checked := 0
	for filename: String in DirAccess.get_files_at("res://data/voxels"):
		if not filename.ends_with("_shape.json"):
			continue
		var name := filename.trim_suffix("_shape.json")
		var raw: Variant = JsonFile.read("res://data/voxels/" + filename)
		if not (raw is Dictionary) or not bool(raw.get("exclusive_parts", false)):
			continue
		var rec := designs().get_def(str(raw.get("unit", "")))
		check(rec != null, name + " missing linked record sheet")
		if rec == null:
			continue
		check_eq(rec.sprite, name, name + " record sprite disagrees with art")
		var detail_path := "res://data/voxels/%s.json" % name
		if name == "rook":
			detail_path = "res://data/voxels/rook_nh1b.json"
		check(FileAccess.file_exists(detail_path), name + " missing high-detail manifest")
		if not FileAccess.file_exists(detail_path):
			continue
		var detail: Variant = JsonFile.read(detail_path)
		check(detail is Dictionary, name + " malformed display manifest")
		if not (detail is Dictionary):
			continue
		check_eq(str(detail.get("source", "")),
				"res://data/voxels/" + filename, name + " incorrect source")
		check(int(detail.get("subdivide", 0)) >= 2, name + " insufficient detail")
		checked += 1
	check(checked >= 88, "expected all 88 recently imported chassis to have art")


func test_rook_variants_keep_separate_weapon_geometry() -> void:
	var old := designs().get_def("rook_nh1b")
	var newer := designs().get_def("rook_nh3x")
	check(old != null and newer != null, "both Rook record sheets required")
	if old == null or newer == null:
		return
	check_eq(old.sprite, newer.sprite, "these two Rooks share a chassis")
	check_eq(UnitVoxels.model_path(old), "res://data/voxels/rook_nh1b.json")
	check_eq(UnitVoxels.model_path(newer), "res://data/voxels/rook.json")
	var model := VxModel.load_file(UnitVoxels.model_path(old))
	check(model.errors.is_empty(), "Rook NH-1B variant load errors")
	check_eq(model.unit_id, old.id, "wrong Rook record sheet linked to geometry")
