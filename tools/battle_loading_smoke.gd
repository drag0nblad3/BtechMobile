extends SceneTree
## Exercises staged loading on headless CI, with no guessed readiness delay.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	BattleLoading.force_staged = true
	GameSettings.load_settings()
	GameSettings.set_voxel_mechs(true)
	VxRenderCache.clear()
	var db := UnitDb.load_dir()
	var state := ScenarioLoader.load_file("res://data/scenarios/test_skirmish.json", TerrainDb.load_file(), db)
	# No rules changes during loading; leave one model in the reserve list.
	var reserve: Unit = state.units.pop_back()
	state.waiting.append(reserve)
	BattleLaunch.pending = state
	BattleLaunch.bot_sides = []
	var battle: Node = load(BattleLaunch.BATTLE_SCENE).instantiate()
	root.add_child(battle)
	if not _check(not battle.startup_complete and battle._loading != null, "loading shown before setup"):
		return
	var previous := 0.0
	var samples := {}
	while not battle.startup_complete:
		await process_frame
		if battle.startup_complete:
			break
		var loader: BattleLoading = battle._loading
		if not _check(loader.stage >= previous, "progress monotonic"):
			return
		previous = loader.stage
		samples[loader.status.text] = true
		if battle.controller != null and not _check(battle.controller.history.is_empty() or loader.stage >= 94.0, "no combat before final stage"):
			return
	if not _check(samples.size() >= 5 and battle.hud != null and battle.units_layer != null, "stages completed and HUD ready"):
		return
	if not _check(battle.preload_jobs > 0, "worker prepared real battle geometry"):
		return
	await process_frame
	if state.phase == Phase.Kind.MOVEMENT and not battle.controller.pending_units().is_empty():
		if not _check(battle.movement.selected != null and battle.controller.pending_units().has(battle.movement.selected), "first eligible mover auto-selected"):
			return
	var v: UnitView = battle.units_layer.view_of(reserve)
	if not _check(v != null and not v.visible and v._model == null, "reserve did not build expensive model"):
		return
	v.set_field_visible(true)
	if not _check(v.visible and v._model != null, "reveal materializes reserve view"):
		return
	print("battle loading smoke ok")
	quit(0)


func _check(ok: bool, message: String) -> bool:
	if not ok:
		printerr("BATTLE_LOADING_FAILED: ", message)
		quit(1)
	return ok
