extends SceneTree
## Non-rendering integration test for the live 20-model stress button.
## Uses real 2x Jenner voxel data and real randomized crater erosion.

func _initialize() -> void:
	call_deferred("_check_stress")


func _check_stress() -> void:
	change_scene_to_file("res://scenes/voxel_mech_lab.tscn")
	await process_frame
	await process_frame
	if not _require(current_scene is VoxelMechLab, "lab scene did not load"):
		return
	var lab := current_scene as VoxelMechLab
	var button := lab.find_child("StressTestButton", true, false) as Button
	if not _require(button != null, "stress button missing"):
		return
	lab.stress_render_surfaces = false
	button.pressed.emit()
	if not _require(lab.stress_test != null and lab.mech == null,
			"single mech must be replaced with stress population"):
		return
	var profile := lab.stress_test.profile
	var best_count := int(lab._catalog_counts[str(profile["id"])])
	for value in lab._catalog_counts.values():
		if not _require(best_count >= int(value),
				"stress must select the highest occupied voxel model"):
			return
	for i in (VoxelStressTest.MECH_COUNT + 4):
		await process_frame
	var test: VoxelStressTest = lab.stress_test
	if not _require(test.running and test.models.size() == 20,
			"must create 20 real high-detail chassis before shooting"):
		return
	if not _require(test.original_voxels == best_count * 20,
			"population voxel count mismatch"):
		return
	for model in test.models:
		if not _require(model.profile_id == str(profile["id"]) and
				model.render_surfaces == false and model.initial_voxels() == best_count,
				"one stress mech has incorrect profile or detail"):
			return
	var removed := 0
	for n in 6:
		removed += test.hit_random_mech()
	if not _require(removed > 0 and test.successful_hits > 0 and
			test.removed_voxels == removed,
			"random pings must remove real voxels from stress mechs"):
		return
	if not _require(test.progress_text().contains("FPS") and
			test.progress_text().contains("20 x ") and
			test.progress_text().contains("Hits "),
			"stress HUD must expose FPS, model count and shot totals"):
		return
	var hit_count := test.successful_hits
	button.pressed.emit()
	await process_frame
	if not _require(lab.stress_test == null and lab.mech != null and
			lab.mech.remaining_voxels() > 0,
			"stop button must release all stress mechs and restore the solo lab"):
		return
	if not _require(button.text == "STRESS TEST x20" and
			not lab.chassis_selector.disabled,
			"lab controls must return after stop"):
		return
	print("VOXEL_STRESS_SMOKE_OK|%s|models=20|voxels=%d|hits=%d|removed=%d" % [
			profile["id"], best_count * 20, hit_count, removed])
	quit(0)


func _require(condition: bool, message: String) -> bool:
	if not condition:
		printerr("Voxel stress smoke failed: ", message)
		quit(1)
	return condition
