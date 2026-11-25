extends SceneTree
## Integration smoke: save a real battle, resume it, then scrub the replay.

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	BattleLaunch.bot_sides = []
	BattleLaunch.load_autosave = false
	change_scene_to_file("res://scenes/main.tscn")
	await process_frame
	await process_frame
	var battle: Variant = current_scene
	if not _check(battle != null and battle.controller.state.turn == 1,
			"battle scene did not start"):
		return
	var map_view: MapView = battle.map_view
	var geo := map_view.geometry_builds
	var effects := map_view.effects_builds
	var buildings := map_view.buildings
	map_view.queue_refresh(false)
	map_view.queue_refresh(false)
	await process_frame
	if not _check(map_view.geometry_builds == geo and map_view.effects_builds == effects + 1
			and map_view.buildings == buildings, "smoke updates rebuilt static geometry or did not coalesce"):
		return
	map_view.queue_refresh(true)
	map_view.queue_refresh(false)
	await process_frame
	if not _check(map_view.geometry_builds == geo + 1 and map_view.effects_builds == effects + 2,
			"geometry refresh did not subsume effects"):
		return
	var log_view: CombatLogView = battle.hud.log_view
	await process_frame
	var flushes := log_view.flush_count
	for i in 12:
		log_view.add_line("Batch probe %d" % i)
	await process_frame
	if not _check(log_view.flush_count == flushes + 1 and log_view.text.text.contains("Batch probe 11"),
			"combat log did not retain and coalesce burst"):
		return
	var before: GameController = battle.controller
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
