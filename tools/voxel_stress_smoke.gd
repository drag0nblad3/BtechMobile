extends SceneTree
## True twenty-model integration smoke (headless, no screenshot or fake mesh).
## Validates the Voxel Mech Lab button, 20 real high-detail meshes, random
## damage, live stats and cleanup. This is not an Android FPS benchmark.

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var lab: VoxelMechLab = load("res://scenes/voxel_mech_lab.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	if lab.stress_start_button == null or lab.stress_stop_button == null:
		_fail("Missing start/stop stress test buttons")
		return
	if lab.stress_start_button.name != "StressTestButton":
		_fail("Stress button needs a stable UI identifier")
		return
	lab.stress_start_button.pressed.emit()
	if lab._stress == null:
		_fail("Start button did not create stress controller")
		return
	var stress: VoxelStressTest = lab._stress
	var highest := VoxelStressTest.highest_voxel_profile(lab.profiles, lab._catalog_counts)
	if stress.profile.get("id") != highest.get("id"):
		_fail("Did not choose highest-voxel model (%s)" % highest.get("id"))
		return
	for i in 25:
		await process_frame
	if stress.models.size() != VoxelStressTest.TARGET_COUNT:
		_fail("Only %d stress models spawned" % stress.models.size())
		return
	var selected_count := int(lab._catalog_counts.get(str(highest.get("id")), 0))
	if stress.original_voxels != 20 * selected_count:
		_fail("Stress objects do not match full high-detail model voxel counts")
		return
	var unique: Dictionary = {}
	for model in stress.models:
		if not model.is_inside_tree():
			_fail("Stress model is not in the active scene")
			return
		if model.parts["torso"].get_node_or_null("Surface") == null:
			_fail("Stress model uses count-only fake geometry")
			return
		unique[model.position] = true
	if unique.size() != 20:
		_fail("Stress targets overlap")
		return
	var hits := 0
	for i in 5:
		if stress.ping_random_model() > 0:
			hits += 1
	if hits <= 0 or stress.voxels_removed <= 0:
		_fail("Automatic random damage did not remove any voxels")
		return
	await process_frame
	if not lab.info.text.contains("FPS") or not lab.info.text.contains("hits"):
		_fail("Live FPS and damage stats are not displayed")
		return
	lab.stress_stop_button.pressed.emit()
	if lab._stress != null or not lab.mech.visible:
		_fail("Stop did not clear the stress targets and restore lab")
		return
	if lab.stress_start_button.disabled:
		_fail("Stress test cannot be restarted")
		return
	print("voxel stress smoke ok: 20 high-detail models, random hits and FPS HUD")
	lab.queue_free()
	quit(0)


func _fail(message: String) -> void:
	printerr("VOXEL_STRESS_SMOKE_FAILED: ", message)
	quit(1)
