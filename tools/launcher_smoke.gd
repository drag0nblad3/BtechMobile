extends SceneTree
## Headless navigation test: launcher -> voxel lab -> launcher -> battle menu.


func _initialize() -> void:
	call_deferred("_test_navigation")


func _test_navigation() -> void:
	change_scene_to_file("res://scenes/launcher.tscn")
	await process_frame
	await process_frame
	if not _check(current_scene is GameLauncher, "launcher did not load"):
		return
	var lab_button := current_scene.find_child("VoxelLabButton", true, false) as Button
	if not _check(lab_button != null, "voxel lab button missing"):
		return
	lab_button.pressed.emit()
	await process_frame
	await process_frame
	if not _check(current_scene is VoxelMechLab, "voxel lab route failed"):
		return
	var lab: VoxelMechLab = current_scene as VoxelMechLab
	if not _check(lab.mech != null and lab.mech.remaining_voxels() > 0,
			"voxel lab mech did not build"):
		return
	var back := lab.find_child("BackToLauncher", true, false) as Button
	if not _check(back != null, "return button missing"):
		return
	back.pressed.emit()
	await process_frame
	await process_frame
	if not _check(current_scene is GameLauncher, "return to launcher failed"):
		return
	var battle_button := current_scene.find_child("BattleButton", true, false) as Button
	if not _check(battle_button != null, "battle button missing"):
		return
	battle_button.pressed.emit()
	await process_frame
	await process_frame
	if not _check(current_scene is ForceBuilderScreen, "battle menu route failed"):
		return
	print("launcher navigation ok")
	quit(0)


func _check(ok: bool, message: String) -> bool:
	if not ok:
		printerr("launcher smoke failed: ", message)
		quit(1)
	return ok
