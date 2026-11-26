extends Node3D
## Composition root for a battle: builds the rules objects and the views and
## wires signals between them. Keep logic out of here. The state comes from
## the force builder (BattleLaunch) or, if started directly, the default scenario.

const SCENARIO := "res://data/scenarios/test_skirmish.json"

var controller: GameController
var map_view: MapView
var fx := BattleFx.new()
var audio := BattleAudio.new()
var atmosphere := BattleAtmosphere.new()
var scars := BattleScars.new()
var aim_guides := BattleAimOverlay.new()
var units_layer: UnitsLayer
var rig: CameraRig
var cinematic: CinematicDirector
var gestures: TouchGestures
var hud: BattleHud
var movement: MovementInput
var attacks: AttackInput
var explainer: Explainer
var sheet_unit: Unit
var bots: BotDriver
var tutorial: Tutorial
var practice: TrainingPractice
var lessons: LessonCard
var training := -1  ## Training campaign mission index, -1 outside training.
var in_campaign := false  ## A campaign company battle (CampaignStore).
var in_map_campaign := false  ## A map campaign meeting (MapCampaignStore).
var objectives: Node3D
var off_field: HiddenInput
var recorder := BattleRecorder.new()
var undo_input := UndoInput.new()  ## Training: take back your last move.
var _last_autosave_turn := -1
var _autosave_pending := false
var _sheet_refresh_pending := false
var _objectives_refresh_pending := false
var _tutorial_path := ""
var startup_complete := false
var _auto_move_pending := false
var _auto_selecting := false
var _loading: BattleLoading
var preload_jobs := 0


func _ready() -> void:
	CrashMonitor.battle_active = true
	CrashMonitor.note("BATTLE", "scene entered")
	_loading = BattleLoading.new()
	add_child(_loading)
	await _loading.step("Loading battle data and deployment orders", 10.0)
	GameSettings.load_settings()
	# On Android do not retain previous battles' high-density meshes during
	# the next deployment's peak CPU/GPU allocation.
	if OS.get_name() == "Android":
		VxRenderCache.clear()
	var saved := {}
	if BattleLaunch.load_autosave:
		BattleLaunch.load_autosave = false
		saved = BattleSave.load_game()
	if not BattleLaunch.restore_snapshot.is_empty():
		saved = BattleSave.restore(BattleLaunch.restore_snapshot, UnitDb.load_dir(), TerrainDb.load_file())
		BattleLaunch.restore_snapshot = {}
	var state: GameState
	if saved.is_empty():
		state = BattleLaunch.take()
		if state == null:
			state = ScenarioLoader.load_file(SCENARIO, TerrainDb.load_file(), UnitDb.load_dir())
		controller = GameController.new(state)
		recorder.begin(state)
	else:
		BattleLaunch.pending = null
		controller = saved["controller"]
		state = controller.state
		recorder.frames = saved["frames"]
	var design_ids: Array = state.all_units().map(func(u: Unit) -> String: return u.def.id)
	CrashMonitor.note("BATTLE_MAP", "%s %dx%d | units=%s | voxels=%s cinematic=%s" % [
		state.map.name, state.map.width, state.map.height, str(design_ids), GameSettings.voxel_mechs, GameSettings.cinematic_camera])
	await _loading.step("Preparing mission and command systems", 18.0)
	bots = BotDriver.new()
	bots.controller = controller
	bots.bot_sides = saved["bots"] if not saved.is_empty() else BattleLaunch.take_bots()
	bots.skill = int(saved["skill"]) if not saved.is_empty() \
			else (BattleLaunch.bot_level if BattleLaunch.bot_level >= 0 else GameSettings.ai_level)
	BattleLaunch.bot_level = -1
	explainer = Explainer.new(GameSettings.explain_level)
	_tutorial_path = String(saved.get("tutorial", BattleLaunch.tutorial_path))
	BattleLaunch.tutorial_path = ""
	if _tutorial_path != "":
		tutorial = Tutorial.from_scenario(_tutorial_path)
		lessons = LessonCard.new()
		add_child(lessons)
		bots.lessons = lessons
	training = int(saved["training"]) if not saved.is_empty() else BattleLaunch.training_mission
	BattleLaunch.training_mission = -1
	if saved.is_empty() and not BattleLaunch.campaign:
		CampaignStore.drop_pending()  # its autosave is about to be replaced
	in_campaign = not CampaignStore.pending_roster().is_empty()
	BattleLaunch.campaign = false
	if saved.is_empty() and not BattleLaunch.map_campaign:
		MapCampaignStore.drop_pending()
	in_map_campaign = not MapCampaignStore.pending().is_empty()
	BattleLaunch.map_campaign = false
	if training >= 0:
		var campaign := TrainingCampaign.load_file()
		if training < campaign.missions.size():
			practice = TrainingPractice.from_mission(campaign.missions[training])
			if not saved.is_empty():
				var player_side := 0 if not bots.bot_sides.has(0) else 1
				practice.restore(recorder.frames, state, player_side)
	add_child(BattleEnvironment.build(state.conditions))
	await _build_views(state)
	_wire()
	hud.set_explain_label(GameSettings.explain_level)
	hud.set_cinematic_label(GameSettings.cinematic_camera)
	hud.pause_menu.set_voxel_label(GameSettings.voxel_mechs)
	hud.pause_menu.set_shake_label(GameSettings.camera_shake)
	await _loading.step("Finalizing deployment and initiative", 94.0)
	if saved.is_empty():
		controller.start_turn()
		_look_at_mine()
		cinematic.introduce(state)
	else:
		_resume_ui()
	# Keep the cover through the initial deferred autosave and first render.
	await _loading.step("Battle ready", 100.0)
	startup_complete = true
	CrashMonitor.note("BATTLE_READY", "turn=%d phase=%d" % [state.turn, state.phase])
	_loading.hide()
	_loading.queue_free()
	bots.set_process(true)


func _exit_tree() -> void:
	CrashMonitor.battle_active = false
	CrashMonitor.note("BATTLE", "scene exited")


func _resume_ui() -> void:
	for f: Dictionary in recorder.frames.slice(maxi(0, recorder.frames.size() - 70)):
		if String(f.get("text", "")) != "":
			hud.log_view.add_line(String(f["text"]))
	_update_status()
	_auto_move_pending = true
	_look_at_my_turn.call_deferred()
	if controller.state.game_over:
		hud.show_game_over("Battle finished")
	elif controller.state.point_blank.is_empty() and controller.state.phase in [Phase.Kind.WEAPON_ATTACK, Phase.Kind.PHYSICAL_ATTACK]:
		attacks.begin.call_deferred()


func _autosave() -> bool:
	if controller == null:
		return false
	var ok := BattleSave.save_game(controller, bots.bot_sides, bots.skill,
			training, recorder.frames, _tutorial_path)
	if not ok:
		push_warning("Battle autosave could not be written.")
	else:
		_autosave_pending = false
	return ok


## Collapse several synchronous end-of-turn events into one durable write.
func _queue_autosave() -> void:
	if _autosave_pending:
		return
	_autosave_pending = true
	_flush_autosave.call_deferred()


func _flush_autosave() -> void:
	if not _autosave_pending:
		return
	_autosave_pending = false
	_autosave()


func _save_battle() -> void:
	var saved := _autosave()
	hud.set_tip("Battle saved." if saved else "Save failed.")
	if hud.pause_menu.visible:
		hud.pause_menu.set_message("Battle saved." if saved else "Save failed; battle is still open.")


func _toggle_pause() -> void:
	var opening := not hud.pause_menu.visible
	hud.pause_menu.visible = opening
	if opening:
		hud.pause_menu.set_message("The battle is stopped until you resume.")
	get_tree().paused = opening
	audio.set_paused(opening)
	atmosphere.set_paused(opening)


func _exit_to_menu() -> void:
	if not _autosave():
		hud.pause_menu.set_message("Save failed. The battle is still open.")
		return
	get_tree().paused = false
	BattleLaunch.open_training = training >= 0
	BattleLaunch.open_campaign = in_campaign
	BattleLaunch.open_map_campaign = in_map_campaign
	get_tree().change_scene_to_file("res://scenes/launcher.tscn" if training >= 0 or in_campaign or in_map_campaign else BattleLaunch.MENU_SCENE)


func _watch_replay() -> void:
	if recorder.frames.is_empty():
		return
	if not controller.state.game_over:
		_autosave()
	if BattleSave.save_replay(recorder.frames):
		get_tree().change_scene_to_file("res://scenes/battle_replay.tscn")
	else:
		hud.set_tip("Could not save the replay.")


func _open_forensics() -> void:
	if BattleSave.save_replay(recorder.frames):
		get_tree().change_scene_to_file("res://scenes/battle_forensics.tscn")
	else:
		hud.set_tip("Could not archive battle for analysis.")


func _input(_event: InputEvent) -> void:
	if not startup_complete:
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if not startup_complete:
		return
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and controller != null:
		_toggle_pause()
	elif what == NOTIFICATION_APPLICATION_PAUSED and controller != null:
		_autosave()


func _build_views(state: GameState) -> void:
	var see_hidden := [0, 1].filter(func(side: int) -> bool: return not bots.bot_sides.has(side))
	var roster := state.all_units()
	var queue := VxBuildQueue.new()
	add_child(queue)
	if BattleLoading.staged():
		var paths: Array[String] = []
		for u: Unit in roster:
			if not UnitsLayer.on_field(state, u, see_hidden):
				continue
			var path := UnitVoxels.startup_path(u.def)
			if not path.is_empty() and not paths.has(path):
				paths.append(path)
		queue.begin(paths)
	map_view = MapView.new()
	add_child(map_view)
	await map_view.build_staged(state.map, _loading.step)
	map_view.set_conditions(state.conditions)
	await _loading.step("Placing mission objectives", 48.0)
	objectives = ObjectiveMarkers.build(state)
	add_child(objectives)
	units_layer = UnitsLayer.new()
	add_child(units_layer)
	for i in roster.size():
		await _loading.step("Preparing unit %d of %d" % [i + 1, roster.size()],
				50.0 + 34.0 * float(i) / maxf(1.0, roster.size()))
		var u: Unit = roster[i]
		var prepared := {}
		if UnitsLayer.on_field(state, u, see_hidden):
			prepared = await queue.take(UnitVoxels.startup_path(u.def))
		CrashMonitor.note("MODEL", "building unit=%d design=%s" % [u.id, u.def.id])
		units_layer.build_one(state, u, see_hidden, true, prepared)
	preload_jobs = queue.jobs_completed
	queue.queue_free()
	await _loading.step("Restoring battlefield history and effects", 84.0)
	add_child(scars)
	scars.setup(state, units_layer, recorder.frames)
	fx.setup(state, units_layer, map_view)
	fx.scars = scars
	add_child(fx)
	add_child(audio)
	audio.setup(state)
	await _loading.step("Setting up tactical controls", 90.0)
	var highlighter := HexHighlighter.new()
	add_child(highlighter)
	highlighter.setup(state.map)
	add_child(aim_guides)
	aim_guides.setup(state)
	var marker := FacingMarker.new()
	add_child(marker)
	rig = CameraRig.new()
	add_child(rig)
	var bounds := HexLayout.map_bounds(state.map)
	rig.bounds = bounds
	rig.snap(bounds.get_center(), 22.0)
	var weather := get_node_or_null("Environment/BattleWeather") as BattleWeather
	if weather != null:
		weather.setup(state.conditions, rig.camera, units_layer)
	fx.attach_camera(rig)
	cinematic = CinematicDirector.new()
	add_child(cinematic)
	cinematic.setup(rig, units_layer)
	cinematic.set_enabled(GameSettings.cinematic_camera)
	fx.attacks.visual_event.connect(audio.on_event)
	fx.attacks.visual_event.connect(atmosphere.on_event)
	fx.attacks.visual_event.connect(cinematic.on_event)
	gestures = TouchGestures.new()
	add_child(gestures)
	hud = BattleHud.new()
	add_child(hud)
	audio.attach_ui(hud)
	add_child(atmosphere)
	atmosphere.setup(hud, audio, state, bots.bot_sides)
	movement = MovementInput.new()
	movement.controller = controller
	movement.highlighter = highlighter
	movement.aim_guide = aim_guides
	movement.marker = marker
	movement.hud = hud
	movement.units_layer = units_layer
	add_child(movement)
	attacks = AttackInput.new()
	attacks.controller = controller
	attacks.hud = hud
	attacks.highlighter = highlighter
	attacks.aim_guide = aim_guides
	attacks.bots = bots
	attacks.units_layer = units_layer
	movement.bots = bots
	add_child(attacks)
	bots.units_layer = units_layer
	add_child(bots)
	bots.set_process(false)
	var plates := Nameplates.new()
	add_child(plates)
	plates.setup(state, units_layer, func() -> Unit: return attacks.attacker if attacks.attacker else movement.selected)
	controller.event.connect(plates.invalidate)
	units_layer.busy_changed.connect(plates.invalidate)
	off_field = HiddenInput.new()
	off_field.controller = controller
	off_field.hud = hud
	off_field.bots = bots
	add_child(off_field)
	var transport := TransportInput.new()
	add_child(transport)
	transport.setup(controller, movement, hud)


func _wire() -> void:
	gestures.panned.connect(func(d: Vector2): cinematic.manual_input(); rig.pan(d))
	gestures.pinched.connect(func(f: float): cinematic.manual_input(); rig.zoom(f))
	gestures.twisted.connect(func(a: float): cinematic.manual_input(); rig.orbit(a))
	gestures.tilted.connect(func(px: float): cinematic.manual_input(); rig.tilt(px * 0.006))
	gestures.tapped.connect(_on_tap)
	gestures.double_tapped.connect(_on_double_tap)
	hud.top_down_toggled.connect(func(): cinematic.manual_input(); rig.toggle_top_down())
	hud.cinematic_toggled.connect(_toggle_cinematic)
	hud.mode_toggled.connect(movement.on_mode_toggled)
	hud.intel_cycled.connect(movement.cycle_intel)
	hud.turn_left.connect(movement.on_turn.bind(-1))
	hud.turn_right.connect(movement.on_turn.bind(1))
	hud.confirm.connect(movement.on_confirm)
	hud.cancel.connect(movement.clear_selection)
	hud.charge.connect(movement.on_charge)
	hud.prone.connect(movement.on_prone)
	hud.smash.connect(movement.on_smash)
	hud.masc.connect(movement.on_masc)
	hud.supercharger.connect(movement.on_masc.bind(true))
	hud.leave.connect(movement.on_leave)
	hud.attack_confirm.connect(attacks.on_confirm)
	hud.attack_skip.connect(attacks.on_skip)
	hud.twist_left.connect(attacks.on_twist.bind(-1))
	hud.twist_right.connect(attacks.on_twist.bind(1))
	hud.flip_arms.connect(attacks.on_flip)
	hud.log_toggled.connect(hud.log_view.cycle_size)
	hud.sheet_toggled.connect(_toggle_sheet)
	hud.explain_cycled.connect(_cycle_explain)
	hud.save_battle.connect(_save_battle)
	hud.pause_toggled.connect(_toggle_pause)
	hud.pause_menu.voxel_toggled.connect(_toggle_voxels)
	hud.pause_menu.shake_toggled.connect(_toggle_shake)
	hud.next_unit.connect(_next_unit)
	undo_input.setup(self)
	hud.hint.connect(func(): movement.on_hint() if controller.state.phase == Phase.Kind.MOVEMENT else attacks.on_hint())
	hud.exit_battle.connect(_exit_to_menu)
	hud.watch_replay.connect(_watch_replay)
	hud.battle_forensics.connect(_open_forensics)
	hud.new_battle.connect(func():
			BattleLaunch.open_training = training >= 0
			BattleLaunch.open_campaign = in_campaign
			BattleLaunch.open_map_campaign = in_map_campaign
			get_tree().change_scene_to_file("res://scenes/launcher.tscn" if training >= 0 or in_campaign or in_map_campaign else BattleLaunch.MENU_SCENE))
	units_layer.busy_changed.connect(func(busy: bool):
		if not busy and _auto_move_pending:
			_look_at_my_turn.call_deferred())
	movement.unit_selected.connect(_focus_unit)
	attacks.attacker_selected.connect(_focus_unit)
	attacks.target_chosen.connect(_frame_attack)
	controller.event.connect(_on_event)


func _focus_unit(u: Unit) -> void:
	if not _auto_selecting:
		cinematic.manual_input()
	if not _auto_selecting or not cinematic.enabled:
		rig.focus(units_layer.view_of(u).position)
	sheet_unit = u
	_show_sheet_if_open()


## Keep attacker and target in view beside the weapons panel.
func _frame_attack(a: Unit, t: Unit) -> void:
	cinematic.manual_input()
	var frame := CameraFraming.beside_panel(rig.camera, rig.distance(), units_layer.view_of(a).position,
			units_layer.view_of(t).position, get_viewport().get_visible_rect().size)
	rig.set_distance(frame["distance"])
	rig.focus(frame["focus"])


## Next button: select the next unit still to act, or just look at the next one.
func _next_unit() -> void:
	if units_layer.attack_playing:
		return
	var current: Unit = movement.selected if movement.selected else attacks.attacker if attacks.attacker else sheet_unit
	var u := UnitCycler.after(UnitCycler.candidates(controller, bots.bot_sides), current)
	if u == null:
		return
	if attacks.active() and controller.pending_units().has(u):
		attacks._select(u)
	elif controller.state.phase == Phase.Kind.MOVEMENT and not bots.is_bot_turn() \
			and controller.pending_units().has(u):
		movement.select(u)
	else:
		_focus_unit(u)


## Start a battle looking at the player's own force, not the map centre.
func _look_at_mine() -> void:
	var mine := UnitCycler.candidates(controller, bots.bot_sides)
	if not mine.is_empty():
		rig.focus(units_layer.view_of(mine[0]).position)


## On the player's movement turn, bring their next 'Mech on screen.
func _look_at_my_turn() -> void:
	if not _auto_move_pending:
		return
	var s := controller.state
	if bots.is_bot_turn() or s.game_over or s.phase != Phase.Kind.MOVEMENT:
		_auto_move_pending = false
		return
	if units_layer.is_busy():
		return  # Retry after the presentation finishes.
	_auto_move_pending = false
	if movement.selected != null or not s.point_blank.is_empty():
		return
	for u: Unit in controller.pending_units():
		var view := units_layer.view_of(u)
		if view == null or not view.visible or s.hidden.has(u) or s.reserves.has(u):
			continue
		_auto_selecting = true
		movement.select(u)
		_auto_selecting = false
		break


func _on_tap(pos: Vector2) -> void:
	if not startup_complete or units_layer.attack_playing:
		return
	cinematic.manual_input()
	var c := HexPicker.pick(rig.camera, pos, controller.state.map)
	if c == Hex.INVALID:
		return
	if off_field.on_hex_tapped(c):
		return
	var u := controller.state.unit_at(c)
	if u:
		sheet_unit = u
		_show_sheet_if_open()
	if not attacks.on_hex_tapped(c):
		movement.on_hex_tapped(c)
	if u == null and movement.selected == null and attacks.attacker == null:
		hud.set_info(TerrainText.describe(controller.state.map.get_tile(c), GameSettings.explain_level))


func _on_double_tap(pos: Vector2) -> void:
	cinematic.manual_input()
	var c := HexPicker.pick(rig.camera, pos, controller.state.map)
	if c != Hex.INVALID:
		rig.focus(HexLayout.tile_top(controller.state.map.get_tile(c)))


func _toggle_voxels() -> void:
	GameSettings.set_voxel_mechs(not GameSettings.voxel_mechs)
	units_layer.reload_looks()
	hud.pause_menu.set_voxel_label(GameSettings.voxel_mechs)
	hud.pause_menu.set_message("Voxel models enabled." if GameSettings.voxel_mechs else "Sprites and placeholders enabled.")


func _toggle_shake() -> void:
	GameSettings.set_camera_shake(not GameSettings.camera_shake)
	hud.pause_menu.set_shake_label(GameSettings.camera_shake)


func _toggle_sheet() -> void:
	hud.sheet_open = not hud.sheet_open
	if hud.sheet_open and sheet_unit == null and not controller.state.units.is_empty():
		sheet_unit = controller.state.units[0]
	if hud.sheet_open:
		_show_sheet_if_open()
	else:
		hud.show_side(null)
		attacks._refresh()


func _show_sheet_if_open() -> void:
	if hud.sheet_open and sheet_unit:
		var power := func(want: String) -> void:
			if want.begins_with("sinks:"):
				controller.request_sinks_off(sheet_unit, int(want.substr(6)))
			elif want.begins_with("stealth:"):
				controller.request_stealth(sheet_unit, want == "stealth:on")
			elif want.begins_with("intuition:"):
				controller.request_intuition(sheet_unit, want == "intuition:on")
			else:
				controller.request_power(sheet_unit, want)
			_show_sheet_if_open()
		hud.show_side(RecordSheetView.build(sheet_unit, Callable() if bots.bot_sides.has(sheet_unit.side) else power))


func _toggle_cinematic() -> void:
	GameSettings.set_cinematic_camera(not GameSettings.cinematic_camera)
	cinematic.set_enabled(GameSettings.cinematic_camera)
	hud.set_cinematic_label(GameSettings.cinematic_camera)
	hud.set_tip("Cinematic camera follows major actions; drag to take control." if GameSettings.cinematic_camera else "Tactical camera restored.")


func _cycle_explain() -> void:
	GameSettings.set_explain_level(ExplainLevel.next(GameSettings.explain_level))
	explainer.level = GameSettings.explain_level
	hud.set_explain_label(explainer.level)
	hud.log_view.add_line("Explanations: " + ExplainLevel.name_of(explainer.level), true)
	if attacks.attacker:
		attacks._refresh()


func _on_event(e: GameEvent) -> void:
	if e.type in [GameEvent.TURN_STARTED, GameEvent.PHASE_CHANGED, GameEvent.UNIT_MOVED,
			GameEvent.FIRE_DECLARED, GameEvent.WEAPON_FIRED, GameEvent.UNIT_DESTROYED, GameEvent.GAME_OVER]:
		CrashMonitor.note("GAME_EVENT", "%s turn=%d phase=%d" % [e.type, controller.state.turn, controller.state.phase])
	var s := controller.state
	var bold := e.type in [GameEvent.TURN_STARTED, GameEvent.PHASE_CHANGED, GameEvent.UNIT_DESTROYED, GameEvent.GAME_OVER]
	var explanation := explainer.describe(e, s)
	hud.log_view.add_line(explanation, bold, CombatLogView.tone_for(e))
	hud.show_combat_event(e)
	hud.roll_feed.add_event(e, s)
	recorder.record(e, s, explanation)
	undo_input.refresh()
	if practice != null:
		var player_side := 0 if not bots.bot_sides.has(0) else 1
		var checks := practice.observe(e, s, player_side)
		if not checks.is_empty():
			hud.set_tip("Training %d/%d: %s" % [
					practice.completed_count(), practice.goals.size(), checks[checks.size() - 1]])
	if e.type == GameEvent.ACTIVE_SIDE and s.turn > _last_autosave_turn:
		_last_autosave_turn = s.turn
		_queue_autosave()
	if e.type == GameEvent.GAME_OVER:
		_queue_autosave()
		BattleSave.save_replay.call_deferred(recorder.frames)
	var deferred_visual := fx.play(e)
	if not deferred_visual:
		audio.on_event(e)
		atmosphere.on_event(e)
	if tutorial:
		lessons.add(tutorial.on_event(e, s))
	match e.type:
		GameEvent.UNIT_MOVED, GameEvent.DISPLACED:
			var from: Vector3i = e.data["from"]
			units_layer.play_move(e.data["unit_id"], e.data["path"], Vector2i(from.x, from.y), from.z,
				int(e.data.get("mode", -1)))
		GameEvent.DAMAGE, GameEvent.FALL, GameEvent.STAND, GameEvent.WENT_PRONE, GameEvent.UNIT_DESTROYED, GameEvent.SHUTDOWN, GameEvent.TRANSPORT:
			if not deferred_visual:
				units_layer.refresh_unit(e.data["unit_id"])
				units_layer.react(e)
			_queue_sheet_refresh(int(e.data["unit_id"]))
		GameEvent.CRITICAL, GameEvent.HULL_BREACH, GameEvent.AMMO_EXPLOSION, GameEvent.PILOT_HIT, GameEvent.HEAT, GameEvent.CONSCIOUSNESS, GameEvent.HEAT_SINKS_SWITCHED, GameEvent.STEALTH:
			_queue_sheet_refresh(int(e.data["unit_id"]))
		GameEvent.PHYSICAL:
			if not deferred_visual:
				units_layer.react(e)
		GameEvent.INITIATIVE, GameEvent.SCAN, GameEvent.OBJECTIVE, GameEvent.MINEFIELD:
			_queue_objectives_refresh()
		GameEvent.UNIT_REVEALED, GameEvent.COMBAT_DROP:
			units_layer.view_of(s.unit_by_id(e.data["unit_id"])).set_field_visible(true)
			units_layer.refresh_unit(e.data["unit_id"])
		GameEvent.WAVE:
			# Waves emits its roll before placing the arriving units.
			if e.data.get("arrived", false):
				_refresh_arrivals.call_deferred()
		GameEvent.UNIT_EXITED:
			units_layer.view_of(s.unit_by_id(e.data["unit_id"])).set_field_visible(false)
			_queue_sheet_refresh(int(e.data["unit_id"]))
		GameEvent.ACTIVE_SIDE, GameEvent.PHASE_CHANGED:
			if e.type == GameEvent.PHASE_CHANGED:
				attacks.clear()
				if s.phase != Phase.Kind.MOVEMENT and movement.selected != null:
					movement.clear_selection()
			_update_status()
			if e.type == GameEvent.ACTIVE_SIDE:
				_queue_objectives_refresh()  # carried counters move with their 'Mechs
			if e.type == GameEvent.ACTIVE_SIDE:
				attacks.begin.call_deferred()
				_auto_move_pending = true
				_look_at_my_turn.call_deferred()
		GameEvent.BUILDING:
			if e.data["kind"] in ["collapsed", "bridge_collapsed", "flattened"]:
				map_view.queue_refresh(true)
			elif e.data["kind"] in ["fire", "smoke", "smoke_thins", "inferno", "fire_out"]:
				map_view.queue_refresh(false)
		GameEvent.GAME_OVER:
			var after := TrainingScreen.finish(training, s, bots.bot_sides, int(e.data.get("winner", -1)), practice)
			if in_campaign:
				after = CampaignStore.finish(s, 0, int(e.data.get("winner", -1)), recorder.frames)
			if in_map_campaign:
				after = MapCampaignStore.finish(s, int(e.data.get("winner", -1)), recorder.frames)
			attacks.clear()
			movement.clear_selection()
			_show_results(Explainer.text(e, s, ExplainLevel.OFF), after)
	if not deferred_visual:
		scars.on_event(e)
		cinematic.on_event(e)


## Wait for the existing presentation queue, not the rules or campaign writeback.
func _show_results(result: String, after: String) -> void:
	while units_layer.is_busy():
		await units_layer.busy_changed
	var detail := BattleResultSummary.describe(controller.state, recorder.frames, bots.bot_sides)
	if not after.is_empty():
		detail += "\n\n" + after
	hud.show_game_over(result, detail)


func _queue_sheet_refresh(id: int) -> void:
	if not hud.sheet_open or sheet_unit == null or sheet_unit.id != id or _sheet_refresh_pending:
		return
	_sheet_refresh_pending = true
	_flush_sheet_refresh.call_deferred()


func _flush_sheet_refresh() -> void:
	_sheet_refresh_pending = false
	_show_sheet_if_open()


func _refresh_arrivals() -> void:
	for u: Unit in controller.state.units:
		var v := units_layer.view_of(u)
		if v != null and not v.field_visible and not controller.state.mission.exited.has(u.id):
			v.set_field_visible(true)
			v.snap_to_state()


func _queue_objectives_refresh() -> void:
	if not _objectives_refresh_pending:
		_objectives_refresh_pending = true
		_flush_objectives_refresh.call_deferred()


func _flush_objectives_refresh() -> void:
	_objectives_refresh_pending = false
	_rebuild_objectives()


func _rebuild_objectives() -> void:
	var no_obj: bool = controller.state.mission.def == null or controller.state.mission.def.objectives.is_empty()
	if no_obj and controller.state.minefields.is_empty() and objectives.get_child_count() == 0:
		return
	remove_child(objectives)
	objectives.queue_free()
	objectives = ObjectiveMarkers.build(controller.state)
	add_child(objectives)


func _update_status() -> void:
	var s := controller.state
	hud.set_status("Turn %d  ·  %s  ·  %s to act%s" % [s.turn, Phase.name_of(s.phase), Names.side(s.active_side()),
			MissionText.status(s)])
	hud.set_phase(s.phase)
	if bots.is_bot_turn():
		hud.set_tip("The computer is thinking. Its reasons appear in the log." if GameSettings.explain_level != ExplainLevel.OFF else "")
	elif s.phase == Phase.Kind.MOVEMENT and GameSettings.explain_level != ExplainLevel.OFF:
		hud.set_tip("Select a unit or tap a highlighted destination.")

