extends Node3D
## Composition root for a battle: loads data, builds the rules objects and
## the views, and wires signals between them. Keep logic out of here.

const SCENARIO := "res://data/scenarios/test_skirmish.json"
const SIDE_NAMES := ["Red", "Blue", "Yellow", "Green"]

var controller: GameController
var map_view: MapView
var units_layer: UnitsLayer
var rig: CameraRig
var gestures: TouchGestures
var hud: BattleHud
var movement: MovementInput


func _ready() -> void:
	var state := ScenarioLoader.load_file(SCENARIO, TerrainDb.load_file(), UnitDb.load_dir())
	controller = GameController.new(state)
	add_child(BattleEnvironment.build())
	_build_views(state)
	_wire()
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
	movement.unit_selected.connect(func(u: Unit):
			rig.focus(units_layer.view_of(u).position))
	controller.event.connect(_on_event)


func _on_tap(pos: Vector2) -> void:
	var c := HexPicker.pick(rig.camera, pos, controller.state.map)
	if c != Hex.INVALID:
		movement.on_hex_tapped(c)


func _on_double_tap(pos: Vector2) -> void:
	var c := HexPicker.pick(rig.camera, pos, controller.state.map)
	if c != Hex.INVALID:
		rig.focus(HexLayout.tile_top(controller.state.map.get_tile(c)))


func _on_event(e: GameEvent) -> void:
	match e.type:
		GameEvent.UNIT_MOVED:
			var from: Vector3i = e.data["from"]
			units_layer.play_move(e.data["unit_id"], e.data["path"],
					Vector2i(from.x, from.y), from.z)
		GameEvent.ACTIVE_SIDE, GameEvent.PHASE_CHANGED:
			_update_status()
			# Until the attack UI lands, every 'Mech holds fire.
			if e.type == GameEvent.ACTIVE_SIDE and controller.state.phase != Phase.Kind.MOVEMENT:
				_hold_fire.call_deferred()


func _update_status() -> void:
	var s := controller.state
	var side := s.active_side()
	var who: String = SIDE_NAMES[side] if side >= 0 and side < SIDE_NAMES.size() else "?"
	hud.set_status("Turn %d  ·  %s  ·  %s to move" % [s.turn, Phase.name_of(s.phase), who])


func _hold_fire() -> void:
	var p := controller.pending_units()
	if p.is_empty():
		return
	if controller.state.phase == Phase.Kind.WEAPON_ATTACK:
		controller.declare_fire(p[0], [])
	elif controller.state.phase == Phase.Kind.PHYSICAL_ATTACK:
		controller.declare_physical(p[0], [])
