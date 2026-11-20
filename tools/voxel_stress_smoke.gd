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
	if lab.zoom_in_button == null or lab.zoom_out_button == null or lab.zoom_reset_button == null:
		_fail("Missing touch-sized zoom and fit controls")
		return
	var initial_distance := lab._distance
	lab.zoom_in_button.pressed.emit()
	if lab._distance >= initial_distance:
		_fail("Zoom + should move the camera toward the mechs")
		return
	lab.zoom_out_button.pressed.emit()
	lab.zoom_reset_button.pressed.emit()
	if not is_equal_approx(lab._distance, initial_distance):
		_fail("Fit view must return to the solo camera distance")
		return
	# Simulate a real two-touch pinch spread without tapping a mech.
	var finger0 := InputEventScreenTouch.new()
	finger0.index = 0
	finger0.pressed = true
	finger0.position = Vector2(200, 300)
	lab._unhandled_input(finger0)
	var finger1 := InputEventScreenTouch.new()
	finger1.index = 1
	finger1.pressed = true
	finger1.position = Vector2(350, 300)
	lab._unhandled_input(finger1)
	var pinch := InputEventScreenDrag.new()
	pinch.index = 1
	pinch.position = Vector2(450, 300)
	pinch.relative = Vector2(100, 0)
	lab._unhandled_input(pinch)
	if lab._distance >= initial_distance or not lab._touch_cancel_tap:
		_fail("Spreading two fingers must zoom in without firing")
		return
	for index in [0, 1]:
		var release := InputEventScreenTouch.new()
		release.index = index
		release.pressed = false
		release.position = Vector2(200, 300) if index == 0 else Vector2(450, 300)
		lab._unhandled_input(release)
	if not lab._touches.is_empty():
		_fail("Pinch touch state must clear after both fingers release")
		return
	lab.zoom_reset_button.pressed.emit()
	lab.stress_start_button.pressed.emit()
	if lab._stress == null:
		_fail("Start button did not create stress controller")
		return
	var stress: VoxelStressTest = lab._stress
	if not is_equal_approx(lab._distance, 31.5):
		_fail("Stress test must initially fit the bigger hangar in frame")
		return
	lab.zoom_out_button.pressed.emit()
	if lab._distance <= 31.5:
		_fail("Zoom - must work in stress mode")
		return
	lab.zoom_reset_button.pressed.emit()
	var expected := VoxelStressTest.highest_voxel_profile(lab.profiles,
			lab._catalog_counts)
	if stress.profile.get("id") != expected.get("id"):
		_fail("Did not choose highest-voxel model (" + str(expected.get("name")) + ")")
		return
	for i in 25:
		await process_frame
	if stress.models.size() != VoxelStressTest.TARGET_COUNT:
		_fail("Only %d stress models spawned" % stress.models.size())
		return
	if stress.original_voxels < 20 * 50000:
		_fail("Stress objects are missing genuine high-detail voxel meshes")
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
