extends SceneTree
## Scene-level smoke of cinematic gameplay toggle and forensic replay links.

var _old_cine := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	GameSettings.load_settings()
	_old_cine = GameSettings.cinematic_camera
	GameSettings.set_cinematic_camera(false)
	BattleLaunch.bot_sides = []
	BattleLaunch.load_autosave = false
	change_scene_to_file(BattleLaunch.BATTLE_SCENE)
	await process_frame
	await process_frame
	var battle: Variant = current_scene
	if not _check(battle != null and battle.cinematic != null,
			"battle camera not initialized"):
		return
	var original: Dictionary = battle.rig.capture_pose()
	var turn: int = battle.controller.state.turn
	var phase: int = battle.controller.state.phase
	var rng: int = battle.controller.dice._rng.state
	battle._toggle_cinematic()
	if not _check(battle.cinematic.enabled and GameSettings.cinematic_camera,
			"cinematic mode did not toggle on"):
		return
	var a: Unit = battle.controller.state.units[0]
	var b: Unit = battle.controller.state.units[1]
	battle.cinematic.on_event(GameEvent.new(GameEvent.WEAPON_FIRED, {
			"attacker_id": a.id, "target_id": b.id, "hit": true}))
	if not _check(battle.rig.capture_pose() != original,
			"cinematic action did not frame the combat"):
		return
	battle.cinematic.manual_input()
	if not _check(battle.cinematic._manual > 0, "manual input did not suspend camera"):
		return
	battle._toggle_cinematic()
	if not _check(not battle.cinematic.enabled and battle.rig.capture_pose() == original,
			"tactical camera not restored"):
		return
	if not _check(battle.controller.state.turn == turn and battle.controller.state.phase == phase
			and battle.controller.dice._rng.state == rng, "camera affected combat state or dice"):
		return
	battle.recorder.record(GameEvent.new(GameEvent.WEAPON_FIRED,
			{"attacker_id": a.id, "target_id": b.id, "need": 7, "roll": 9, "hit": true}),
			battle.controller.state, "Atlas fired at Jenner")
	if not _check(BattleSave.save_replay(battle.recorder.frames),
			"could not archive telemetry"):
		return
	change_scene_to_file("res://scenes/battle_forensics.tscn")
	await process_frame
	await process_frame
	var academy: Variant = current_scene
	if not _check(academy != null and academy._report["summary"]["attacks"] >= 1,
			"forensics could not read stored attacks"):
		return
	academy._on_timeline(academy._report["timeline"].size() - 1)
	var chosen: int = academy._selected_frame
	academy._open_replay()
	await process_frame
	await process_frame
	var replay: Variant = current_scene
	if not _check(replay != null and replay._index == chosen,
			"forensics did not open the requested replay frame"):
		return
	_finish()


func _finish() -> void:
	GameSettings.set_cinematic_camera(_old_cine)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BattleSave.REPLAY_PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BattleSave.SAVE_PATH))
	print("academy cinematic forensic smoke ok")
	quit(0)


func _check(ok: bool, why: String) -> bool:
	if not ok:
		GameSettings.set_cinematic_camera(_old_cine)
		printerr("academy smoke failed: ", why)
		quit(1)
	return ok
