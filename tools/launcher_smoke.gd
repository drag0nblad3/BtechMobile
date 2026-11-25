extends SceneTree
## Headless navigation test: launcher -> battle menu -> launcher -> quick battle.
## Developer labs are tested directly, not exposed on the player launcher.


func _initialize() -> void:
	call_deferred("_test_navigation")


func _test_navigation() -> void:
	change_scene_to_file("res://scenes/launcher.tscn")
	await process_frame
	await process_frame
	if not _check(current_scene is GameLauncher, "launcher did not load"):
		return
	if not _check(current_scene.find_child("VoxelLabButton", true, false) == null
			and current_scene.find_child("VxShowcaseButton", true, false) == null,
			"developer labs should not occupy the player launcher"):
		return
	for name: String in ["TrainingButton", "CampaignButton", "MapCampaignButton",
			"TechnicalReadoutButton", "SaveSlotsButton"]:
		var launcher := current_scene as GameLauncher
		(launcher.find_child(name, true, false) as Button).pressed.emit()
		await process_frame
		await process_frame
		if not _check(current_scene == launcher and is_instance_valid(launcher._overlay),
				name + " did not open directly"):
			return
		var overlay := launcher._overlay
		var back := overlay.find_child("MenuBack", true, false) as Button
		if not _check(back != null and back.is_visible_in_tree() and not launcher._menu.visible,
				name + " missing Back or underlying menu still visible"):
			return
		back.pressed.emit()
		await process_frame
		await process_frame
		if not _check(not is_instance_valid(launcher._overlay) and launcher._menu.visible,
				name + " Back did not restore launcher"):
			return
	var battle_button := current_scene.find_child("BattleButton", true, false) as Button
	if not _check(battle_button != null, "battle button missing"):
		return
	battle_button.pressed.emit()
	await process_frame
	await process_frame
	if not _check(current_scene is ForceBuilderScreen, "battle menu route failed"):
		return
	var builder_back := current_scene.find_child("MenuBack", true, false) as Button
	if not _check(builder_back != null, "force builder Back missing"):
		return
	builder_back.pressed.emit()
	await process_frame
	await process_frame
	if not _check(current_scene is GameLauncher, "force builder Back route failed"):
		return
	var quick := current_scene.find_child("QuickBattleButton", true, false) as Button
	if not _check(quick != null and current_scene.find_child("TrainingButton", true, false) != null,
			"training or quick battle button missing"):
		return
	quick.pressed.emit()
	await process_frame
	await process_frame
	var path := String(current_scene.get_script().resource_path) if current_scene else ""
	if not _check(path.ends_with("battle_scene.gd"), "quick battle route failed"):
		return
	var sides: Array = current_scene.controller.state.units.map(func(u: Unit) -> int: return u.side)
	if not _check(sides.count(0) == 4 and sides.count(1) == 4, "quick battle forces wrong"):
		return
	print("launcher navigation ok")
	quit(0)


func _check(ok: bool, message: String) -> bool:
	if not ok:
		printerr("launcher smoke failed: ", message)
		quit(1)
	return ok
