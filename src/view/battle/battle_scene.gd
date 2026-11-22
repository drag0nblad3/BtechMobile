extends Node3D
## Composition root for a battle: builds the rules objects and the views and
## wires signals between them. Keep logic out of here. The state comes from
## the force builder (BattleLaunch) or, if started directly, the default scenario.

const SCENARIO := "res://data/scenarios/test_skirmish.json"

var controller: GameController
var map_view: MapView
var fx := BattleFx.new()
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
var lessons: LessonCard
var training := -1  ## Training campaign mission index, -1 outside training.
var objectives: Node3D
var off_field: HiddenInput
var recorder := BattleRecorder.new()
var _last_autosave_turn := -1
var _tutorial_path := ""


func _ready() -> void:
	GameSettings.load_settings()
	var saved := {}
	if BattleLaunch.load_autosave:
		BattleLaunch.load_autosave = false
		saved = BattleSave.load_game()
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
	add_child(BattleEnvironment.build())
	_build_views(state)
	_wire()
	hud.set_explain_label(GameSettings.explain_level)
	hud.set_cinematic_label(GameSettings.cinematic_camera)
	if saved.is_empty():
		controller.start_turn()
	else:
		_resume_ui()


func _resume_ui() -> void:
	for f: Dictionary in recorder.frames.slice(maxi(0, recorder.frames.size() - 70)):
		if String(f.get("text", "")) != "":
			hud.log_view.add_line(String(f["text"]))
	_update_status()
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
	return ok


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


func _exit_to_menu() -> void:
	if not _autosave():
		hud.pause_menu.set_message("Save failed. The battle is still open.")
		return
	get_tree().paused = false
	BattleLaunch.open_training = training >= 0
	get_tree().change_scene_to_file(BattleLaunch.MENU_SCENE)


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


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and controller != null:
		_toggle_pause()
	elif what == NOTIFICATION_APPLICATION_PAUSED and controller != null:
		_autosave()


func _build_views(state: GameState) -> void:
	map_view = MapView.new()
	add_child(map_view)
	map_view.build(state.map)
	objectives = ObjectiveMarkers.build(state)
	add_child(objectives)
	units_layer = UnitsLayer.new()
	add_child(units_layer)
	units_layer.build(state, [0, 1].filter(func(side: int) -> bool: return not bots.bot_sides.has(side)))
	fx.setup(state, units_layer, map_view)
	add_child(fx)
	var highlighter := HexHighlighter.new()
	add_child(highlighter)
	highlighter.setup(state.map)
	var marker := FacingMarker.new()
	add_child(marker)
	rig = CameraRig.new()
	add_child(rig)
	var bounds := HexLayout.map_bounds(state.map)
	rig.bounds = bounds
	rig.snap(bounds.get_center(), 22.0)
	cinematic = CinematicDirector.new()
	add_child(cinematic)
	cinematic.setup(rig, units_layer)
	cinematic.set_enabled(GameSettings.cinematic_camera)
	gestures = TouchGestures.new()
	add_child(gestures)
	hud = BattleHud.new()
	add_child(hud)
	movement = MovementInput.new()
	movement.controller = controller
	movement.highlighter = highlighter
	movement.marker = marker
	movement.hud = hud
	movement.units_layer = units_layer
	add_child(movement)
	attacks = AttackInput.new()
	attacks.controller = controller
	attacks.hud = hud
	attacks.highlighter = highlighter
	attacks.bots = bots
	movement.bots = bots
	add_child(attacks)
	bots.units_layer = units_layer
	add_child(bots)
	var plates := Nameplates.new()
	add_child(plates)
	plates.setup(state, units_layer, func() -> Unit: return attacks.attacker if attacks.attacker else movement.selected)
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
	hud.exit_battle.connect(_exit_to_menu)
	hud.watch_replay.connect(_watch_replay)
	hud.battle_forensics.connect(_open_forensics)
	hud.new_battle.connect(func():
			BattleLaunch.open_training = training >= 0
			get_tree().change_scene_to_file(BattleLaunch.MENU_SCENE))
	movement.unit_selected.connect(_focus_unit)
	attacks.attacker_selected.connect(_focus_unit)
	controller.event.connect(_on_event)


func _focus_unit(u: Unit) -> void:
	cinematic.manual_input()
	rig.focus(units_layer.view_of(u).position)
	sheet_unit = u
	_show_sheet_if_open()


func _on_tap(pos: Vector2) -> void:
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
	var s := controller.state
	var bold := e.type in [GameEvent.TURN_STARTED, GameEvent.PHASE_CHANGED, GameEvent.UNIT_DESTROYED, GameEvent.GAME_OVER]
	var explanation := explainer.describe(e, s)
	hud.log_view.add_line(explanation, bold, CombatLogView.tone_for(e))
	hud.show_combat_event(e)
	recorder.record(e, s, explanation)
	if e.type == GameEvent.ACTIVE_SIDE and s.turn > _last_autosave_turn:
		_last_autosave_turn = s.turn
		_autosave.call_deferred()
	if e.type == GameEvent.GAME_OVER:
		_autosave.call_deferred()
		BattleSave.save_replay.call_deferred(recorder.frames)
	fx.play(e)
	if tutorial:
		lessons.add(tutorial.on_event(e, s))
	match e.type:
		GameEvent.UNIT_MOVED, GameEvent.DISPLACED:
			var from: Vector3i = e.data["from"]
			units_layer.play_move(e.data["unit_id"], e.data["path"], Vector2i(from.x, from.y),
				from.z, int(e.data.get("mode", MoveMode.Kind.WALK)))
		GameEvent.DAMAGE, GameEvent.FALL, GameEvent.STAND, GameEvent.WENT_PRONE, GameEvent.UNIT_DESTROYED, GameEvent.SHUTDOWN, GameEvent.TRANSPORT:
			units_layer.refresh_unit(e.data["unit_id"])
			_show_sheet_if_open()
		GameEvent.INITIATIVE, GameEvent.SCAN, GameEvent.OBJECTIVE:
			_rebuild_objectives()
		GameEvent.UNIT_REVEALED, GameEvent.COMBAT_DROP:
			units_layer.view_of(s.unit_by_id(e.data["unit_id"])).visible = true
			units_layer.refresh_unit(e.data["unit_id"])
		GameEvent.WAVE:
			for u in s.units:
				units_layer.view_of(u).visible = not s.hidden.has(u)
				units_layer.refresh_unit(u.id)
		GameEvent.UNIT_EXITED:
			units_layer.view_of(s.unit_by_id(e.data["unit_id"])).visible = false
			_show_sheet_if_open()
		GameEvent.ACTIVE_SIDE, GameEvent.PHASE_CHANGED:
			_update_status()
			if e.type == GameEvent.ACTIVE_SIDE:
				_rebuild_objectives()  # carried counters move with their 'Mechs
			if e.type == GameEvent.ACTIVE_SIDE:
				attacks.begin.call_deferred()
		GameEvent.BUILDING:
			if e.data["kind"] in ["collapsed", "bridge_collapsed", "fire", "smoke", "smoke_thins"]:
				map_view.rebuild()
		GameEvent.GAME_OVER:
			hud.show_game_over(Explainer.text(e, s, ExplainLevel.OFF), TrainingScreen.finish(training, s, bots.bot_sides, int(e.data.get("winner", -1))))
			attacks.clear()
			movement.clear_selection()
	cinematic.on_event(e)


func _rebuild_objectives() -> void:
	if controller.state.mission.def == null or controller.state.mission.def.objectives.is_empty() and objectives.get_child_count() == 0:
		return
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
		hud.set_tip("Tap one of your 'Mechs to plan its move.")

