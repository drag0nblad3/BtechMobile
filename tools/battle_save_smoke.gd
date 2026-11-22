extends SceneTree
## Integration smoke: save a real battle, resume it, then scrub the replay.

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("battle save smoke trace: initializing")
	BattleLaunch.bot_sides = []
	BattleLaunch.load_autosave = false
	print("battle save smoke trace: opening battle")
	change_scene_to_file("res://scenes/main.tscn")
	await process_frame
	await process_frame
	print("battle save smoke trace: battle opened")
	var battle: Variant = current_scene
	if not _check(battle != null and battle.get_script() != null and battle.controller.state.turn == 1,
			"battle scene did not start"):
		return
	var before: GameController = battle.controller
	print("battle save smoke trace: saving battle")
	if not _check(battle._autosave(), "could not save the live scene"):
		return
	var last_turn := before.state.turn
	var last_phase := before.state.phase
	var last_rng := before.dice._rng.state
	var frames: Array = battle.recorder.frames.duplicate()
	if not _check(BattleSave.save_replay(frames), "could not archive replay"):
		return
	BattleLaunch.load_autosave = true
	change_scene_to_file("res://scenes/main.tscn")
	await process_frame
	await process_frame
	battle = current_scene
	if not _check(battle != null and battle.controller.state.turn == last_turn
			and battle.controller.state.phase == last_phase
			and battle.controller.dice._rng.state == last_rng,
			"resume changed turn, phase or dice"):
		return
	if not _check(battle.recorder.frames.size() == frames.size(),
			"resume lost recorded replay frames"):
		return
	print("battle save smoke trace: opening replay")
	change_scene_to_file("res://scenes/battle_replay.tscn")
	await process_frame
	await process_frame
	var player: Variant = current_scene
	if not _check(player != null and player._frames.size() == frames.size(),
			"replay scene failed to load"):
		return
	player._show_frame(player._frames.size() - 1)
	player._show_frame(0)
	if not _check(player._index == 0, "replay did not rewind"):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BattleSave.SAVE_PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BattleSave.REPLAY_PATH))
	print("battle save replay smoke ok")
	quit(0)


func _check(ok: bool, reason: String) -> bool:
	if not ok:
		printerr("battle save replay smoke failed: ", reason)
		quit(1)
	return ok
