extends SceneTree
## Integration smoke: save a real battle, resume it, then scrub the replay.

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	BattleLaunch.bot_sides = []
	BattleLaunch.load_autosave = false
	print("hit-fx smoke: before battle scene")
	change_scene_to_file("res://scenes/main.tscn")
	await process_frame
	await process_frame
	var battle: Variant = current_scene
	if not _check(battle != null and battle.controller.state.turn == 1,
			"battle scene did not start"):
		return
	print("hit-fx smoke: first battle loaded")
	var before: GameController = battle.controller
	if not _check(battle._autosave(), "could not save the live scene"):
		return
	print("hit-fx smoke: game saved")
	var last_turn := before.state.turn
	var last_phase := before.state.phase
	var last_rng := before.dice._rng.state
	var frames: Array = battle.recorder.frames.duplicate()
	if not _check(BattleSave.save_replay(frames), "could not archive replay"):
		return
	print("hit-fx smoke: replay archived")
	BattleLaunch.load_autosave = true
	change_scene_to_file("res://scenes/main.tscn")
	await process_frame
	await process_frame
	print("hit-fx smoke: resumed scene instanced")
	battle = current_scene
	if not _check(battle != null and battle.controller.state.turn == last_turn
			and battle.controller.state.phase == last_phase
			and battle.controller.dice._rng.state == last_rng,
			"resume changed turn, phase or dice"):
		return
	if not _check(battle.recorder.frames.size() == frames.size(),
			"resume lost recorded replay frames"):
		return
	print("hit-fx smoke: resume validated")
	change_scene_to_file("res://scenes/battle_replay.tscn")
	await process_frame
	await process_frame
	print("hit-fx smoke: replay scene instanced")
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
