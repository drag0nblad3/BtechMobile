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
	if lab.stress_start_button == null or lab.stress_stop_button == null \
			or lab.stress_count_button == null:
		_fail("Missing start/stop stress buttons or 20/60 selector")
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
	# Exercise 60-model UI configuration without allocating 60 high-res meshes
	# in CI; load only three, then verify STOP cancels even during spawning.
	lab.stress_count_button.pressed.emit()
	if lab.stress_count != VoxelStressTest.LARGE_TARGET_COUNT \
			or lab.stress_count_button.text != "COUNT: 60":
		_fail("Stress count toggle did not select 60 mechs")
		return
	lab.stress_start_button.pressed.emit()
	if lab._stress == null or lab._stress.target_count != 60 \
			or not lab.stress_count_button.disabled:
		_fail("60-mode did not start or count selection changed during loading")
		return
	if not is_equal_approx(lab._distance, 52.0):
		_fail("60-mode needs wider camera fit")
		return
	for i in 3:
		await process_frame
	if lab._stress.models.size() <= 0 or lab._stress.models.size() >= 60:
		_fail("60-mode should spawn progressively, not all at once")
		return
	lab.stress_stop_button.pressed.emit()
	if lab._stress != null or lab.stress_count_button.disabled:
		_fail("STOP should cancel large-model loading and restore selector")
		return
	lab.stress_count_button.pressed.emit()
	if lab.stress_count != VoxelStressTest.TARGET_COUNT:
		_fail("Stress count toggle did not return to 20")
		return
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
	# Deterministically cover the severed-limb path even when random pings
	# only crater armor. Headless SceneTree tests have no current_scene.
	var detached := false
	for model: VoxelMech in stress.models:
		for key: String in model.sockets:
			var joint: Node3D = model.sockets[key]
			if not is_instance_valid(joint) or joint.get_parent() != model._upper:
				continue
			var original_debris := model.debris.size()
			model.detach(key)
			if model.debris.size() != original_debris + 1:
				_fail("Detaching an articulated limb must create wreckage")
				return
			var wreck: RigidBody3D = model.debris[-1]
			if not wreck.is_inside_tree() or wreck.get_parent() == null:
				_fail("Detached limb wreckage must have a valid scene parent")
				return
			detached = true
			break
		if detached:
			break
	if not detached:
		_fail("No attached shoulder joint could be detached in stress scene")
		return
	await process_frame
	if not lab.info.text.contains("FPS") or not lab.info.text.contains("hits"):
		_fail("Live FPS and damage stats are not displayed")
		return
	lab.stress_stop_button.pressed.emit()
	if lab._stress != null or not lab.mech.visible:
		_fail("Stop did not clear the stress targets and restore lab")
		return
	if lab.stress_start_button.disabled or lab.stress_count_button.disabled:
		_fail("Stress test and count selector must be available after stop")
		return
	print("voxel stress smoke ok: 20 high-detail models, random hits and FPS HUD")
	lab.queue_free()
	quit(0)


func _fail(message: String) -> void:
	printerr("VOXEL_STRESS_SMOKE_FAILED: ", message)
	quit(1)
