extends Node3D
## Composition root for a battle: builds the rules objects and the views and
## wires signals between them. Keep logic out of here. The state comes from
## the force builder (BattleLaunch) or, if started directly, the default scenario.

const SCENARIO := "res://data/scenarios/test_skirmish.json"

var controller: GameController
var map_view: MapView
var units_layer: UnitsLayer
var rig: CameraRig
var gestures: TouchGestures
var hud: BattleHud
var movement: MovementInput
var attacks: AttackInput
var explainer: Explainer
var sheet_unit: Unit


func _ready() -> void:
	GameSettings.load_settings()
	var state := BattleLaunch.take()
	if state == null:
		state = ScenarioLoader.load_file(SCENARIO, TerrainDb.load_file(), UnitDb.load_dir())
	controller = GameController.new(state)
	explainer = Explainer.new(GameSettings.explain_level)
	add_child(BattleEnvironment.build())
	_build_views(state)
	_wire()
	hud.set_explain_label(GameSettings.explain_level)
	controller.start_turn()


func _build_views(state: GameState) -> void:
	map_view = MapView.new()
	add_child(map_view)
	map_view.build(state.map)
	units_layer = UnitsLayer.new()
	add_child(units_layer)
	units_layer.build(state)
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
	add_child(attacks)


func _wire() -> void:
	gestures.panned.connect(rig.pan)
	gestures.pinched.connect(rig.zoom)
	gestures.twisted.connect(rig.orbit)
	gestures.tilted.connect(func(px: float): rig.tilt(px * 0.006))
	gestures.tapped.connect(_on_tap)
	gestures.double_tapped.connect(_on_double_tap)
	hud.top_down_toggled.connect(rig.toggle_top_down)
	hud.mode_toggled.connect(movement.on_mode_toggled)
	hud.turn_left.connect(movement.on_turn.bind(-1))
	hud.turn_right.connect(movement.on_turn.bind(1))
	hud.confirm.connect(movement.on_confirm)
	hud.cancel.connect(movement.clear_selection)
	hud.attack_confirm.connect(attacks.on_confirm)
	hud.attack_skip.connect(attacks.on_skip)
	hud.log_toggled.connect(hud.log_view.cycle_size)
	hud.sheet_toggled.connect(_toggle_sheet)
	hud.explain_cycled.connect(_cycle_explain)
	hud.new_battle.connect(func(): get_tree().change_scene_to_file(BattleLaunch.MENU_SCENE))
	movement.unit_selected.connect(_focus_unit)
	attacks.attacker_selected.connect(_focus_unit)
	controller.event.connect(_on_event)


func _focus_unit(u: Unit) -> void:
	rig.focus(units_layer.view_of(u).position)
	sheet_unit = u
	_show_sheet_if_open()


func _on_tap(pos: Vector2) -> void:
	var c := HexPicker.pick(rig.camera, pos, controller.state.map)
	if c == Hex.INVALID:
		return
	var u := controller.state.unit_at(c)
	if u:
		sheet_unit = u
		_show_sheet_if_open()
	if not attacks.on_hex_tapped(c):
		movement.on_hex_tapped(c)


func _on_double_tap(pos: Vector2) -> void:
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
		hud.show_side(RecordSheetView.build(sheet_unit))


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
	hud.log_view.add_line(explainer.describe(e, s), bold)
	match e.type:
		GameEvent.UNIT_MOVED:
			var from: Vector3i = e.data["from"]
			units_layer.play_move(e.data["unit_id"], e.data["path"], Vector2i(from.x, from.y), from.z)
		GameEvent.DAMAGE, GameEvent.FALL, GameEvent.STAND, GameEvent.UNIT_DESTROYED, GameEvent.SHUTDOWN:
			units_layer.refresh_unit(e.data["unit_id"])
			_show_sheet_if_open()
		GameEvent.ACTIVE_SIDE, GameEvent.PHASE_CHANGED:
			_update_status()
			if e.type == GameEvent.ACTIVE_SIDE:
				attacks.begin.call_deferred()
		GameEvent.GAME_OVER:
			hud.show_game_over(Explainer.text(e, s, ExplainLevel.OFF))
			attacks.clear()
			movement.clear_selection()


func _update_status() -> void:
	var s := controller.state
	hud.set_status("Turn %d  ·  %s  ·  %s to act" % [s.turn, Phase.name_of(s.phase), Names.side(s.active_side())])
	if s.phase == Phase.Kind.MOVEMENT and GameSettings.explain_level != ExplainLevel.OFF:
		hud.set_tip("Tap one of your 'Mechs to plan its move.")
