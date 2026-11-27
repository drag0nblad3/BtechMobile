extends TestCase
## All recent sculpt sources must have detailed display counterparts, and
## visibly different official variants must not overwrite another's art.

func test_new_shape_sculpts_have_matching_unit_and_detail_manifest() -> void:
	var checked := 0
	for filename: String in VxRecipeStore.files("res://data/voxels"):
		if not filename.ends_with("_shape.json"):
			continue
		var name := filename.trim_suffix("_shape.json")
		var raw: Variant = VxRecipeStore.read("res://data/voxels/" + filename)
		if not (raw is Dictionary) or not bool(raw.get("exclusive_parts", false)):
			continue
		# Review-campaign source sculpts are covered by their existing tests.
		# This test only covers the newly imported unrevised cohort.
		if raw.has("art_quality_passes") or raw.has("shape_review_50"):
			continue
		var rec := designs().get_def(str(raw.get("unit", "")))
		check(rec != null, name + " missing linked record sheet")
		if rec == null:
			continue
		var expected_sprite := "wolf_trap_tora" if name == "wolf_trap" else name
		check_eq(rec.sprite, expected_sprite, name + " record sprite disagrees with art")
		var detail_path := "res://data/voxels/%s.json" % name
		if name == "rook":
			detail_path = "res://data/voxels/rook_nh1b.json"
		check(VxRecipeStore.exists(detail_path), name + " missing high-detail manifest")
		if not VxRecipeStore.exists(detail_path):
			continue
		var detail: Variant = VxRecipeStore.read(detail_path)
		check(detail is Dictionary, name + " malformed display manifest")
		if not (detail is Dictionary):
			continue
		check_eq(str(detail.get("source", "")),
				"res://data/voxels/" + filename, name + " incorrect source")
		check(int(detail.get("subdivide", 0)) >= 2, name + " insufficient detail")
		checked += 1
	check_eq(checked, 88, "expected all 88 imported chassis sources and display manifests")
	check(VxRecipeStore.exists("res://data/voxels/wolf_trap_tora.json"),
			"Wolf Trap source requires sprite-compatible manifest")


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


func test_wolf_trap_sprite_resolves_to_its_real_new_voxel_sculpt() -> void:
	var trap := designs().get_def("wolf_trap_tora_wft1")
	check(trap != null, "official Wolf Trap WFT-1 record sheet")
	if trap == null:
		return
	check_eq(UnitVoxels.model_path(trap), "res://data/voxels/wolf_trap_tora.json")
	var model := VxModel.load_file(UnitVoxels.model_path(trap))
	check(model.errors.is_empty(), "Wolf Trap Tora rig parses")
	check_eq(model.unit_id, trap.id, "correct mounted weapon record sheet")
