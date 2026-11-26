extends SceneTree
## Full quick-battle path with actual frame submission, camera-only input and
## selected unit labels. No player or bot actions after deployment.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	GameSettings.load_settings()
	GameSettings.voxel_mechs = true
	var rng := RandomNumberGenerator.new()
	rng.seed = 368
	var state := QuickBattle.build(UnitDb.load_dir(), rng)
	if not _check(state != null and state.units.size() >= 8, "quick battle roster"):
		return
	BattleLaunch.pending = state
	BattleLaunch.bot_sides = []
	var battle: Node = load(BattleLaunch.BATTLE_SCENE).instantiate()
	root.add_child(battle)
	while not battle.startup_complete:
		await process_frame
	for i in 4:
		await process_frame
	var before: int = battle.controller.history.size()
	var initial_turn: int = state.turn
	var initial_phase: int = state.phase
	var plates: Nameplates = null
	for child in battle.get_children():
		if child is Nameplates:
			plates = child
	if not _check(plates != null and battle.movement.selected != null, "auto-selected mover and plates"):
		return
	var origin: Vector3 = battle.units_layer.view_of(battle.movement.selected).global_position
	battle.rig.snap(origin, 12.0)
	# Sweep close-up, wide, orbit, pan and tilt. Do not click or confirm moves.
	for i in 90:
		if i % 5 == 0:
			battle.gestures.twisted.emit(0.31)
			battle.gestures.pinched.emit(1.35 if i % 20 < 10 else 0.74)
			battle.gestures.tilted.emit(22.0 if i % 20 < 10 else -22.0)
			battle.gestures.panned.emit(Vector2(36, -12) if i % 20 < 10 else Vector2(-36, 12))
		await process_frame
		if not _check(battle.rig.camera.global_position.is_finite(), "finite camera transform"):
			return
	if not _check(state.turn == initial_turn and state.phase == initial_phase and battle.controller.history.size() == before, "camera must not issue a game action"):
		return
	if not _check(plates._overlay._cards.size() > 0, "rendered retained nameplates"):
		return
	print("quick battle camera smoke ok")
	quit(0)


func _check(ok: bool, reason: String) -> bool:
	if not ok:
		printerr("QUICK_CAMERA_FAILED: ", reason)
		quit(1)
	return ok
