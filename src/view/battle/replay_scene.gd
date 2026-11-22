extends Node3D
## Read-only battle timeline: jump to any recorded state or play it forward.
## No GameController is created; replay cannot roll dice or affect a save.

var _frames: Array
var _index := 0
var _playing := false
var _clock := 0.0
var _db: UnitDb
var _terrain: TerrainDb
var _rig: CameraRig
var _map: MapView
var _units: UnitsLayer
var _objectives: Node3D
var _status: Label
var _play_button: Button
var _prev: Button
var _next: Button


## Deliberate Android Back navigation when automatic exit is disabled.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_tree().change_scene_to_file(BattleLaunch.MENU_SCENE)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key := event as InputEventKey
		if not key.pressed or key.echo or key.keycode != KEY_ESCAPE:
			return
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file(BattleLaunch.MENU_SCENE)


func _ready() -> void:
	_frames = BattleSave.load_replay()
	_db = UnitDb.load_dir()
	_terrain = TerrainDb.load_file()
	add_child(BattleEnvironment.build())
	_rig = CameraRig.new()
	add_child(_rig)
	var touch := TouchGestures.new()
	add_child(touch)
	touch.panned.connect(_rig.pan)
	touch.pinched.connect(_rig.zoom)
	touch.twisted.connect(_rig.orbit)
	touch.tilted.connect(func(px: float): _rig.tilt(px * 0.006))
	_make_hud()
	if not _frames.is_empty():
		_show_frame(clampi(BattleLaunch.replay_focus, 0, _frames.size() - 1))
		BattleLaunch.replay_focus = -1
	else:
		_status.text = "No recorded battle yet."


func _make_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -94
	layer.add_child(panel)
	var row := HBoxContainer.new()
	panel.add_child(row)
	_status = Label.new()
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.add_theme_font_size_override("font_size", 20)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(_status)
	_button(row, "|<", func(): _show_frame(0))
	_prev = _button(row, "<", func(): _show_frame(_index - 1))
	_play_button = _button(row, "Play", _toggle_play)
	_next = _button(row, ">", func(): _show_frame(_index + 1))
	_button(row, ">|", func(): _show_frame(_frames.size() - 1))
	_button(row, "Forensics", _open_forensics)
	_button(row, "Exit", func(): get_tree().change_scene_to_file(BattleLaunch.MENU_SCENE))


func _open_forensics() -> void:
	BattleLaunch.replay_focus = _index
	get_tree().change_scene_to_file("res://scenes/battle_forensics.tscn")


func _button(row: HBoxContainer, label: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(86, 64)
	button.pressed.connect(action)
	row.add_child(button)
	return button


func _show_frame(index: int) -> void:
	if index < 0 or index >= _frames.size():
		return
	_index = index
	var frame: Dictionary = _frames[index]
	var state := BattleRecorder.state_at(frame, _db, _terrain)
	if state == null:
		_playing = false
		_status.text = "Replay frame cannot be loaded."
		return
	if _map:
		_map.queue_free()
	if _units:
		_units.queue_free()
	if _objectives:
		_objectives.queue_free()
	_map = MapView.new()
	add_child(_map)
	_map.build(state.map)
	_units = UnitsLayer.new()
	add_child(_units)
	_units.build(state)
	_objectives = ObjectiveMarkers.build(state)
	add_child(_objectives)
	if index == 0:
		var bounds := HexLayout.map_bounds(state.map)
		_rig.bounds = bounds
		_rig.snap(bounds.get_center(), 22.0)
	_status.text = "Frame %d/%d · Turn %d · %s · %s" % [
			index + 1, _frames.size(), int(frame["turn"]),
			Phase.name_of(int(frame["phase"])), String(frame["text"])]
	_prev.disabled = index == 0
	_next.disabled = index == _frames.size() - 1
	if index == _frames.size() - 1:
		_playing = false
	_play_button.text = "Pause" if _playing else "Play"


func _toggle_play() -> void:
	if _frames.is_empty():
		return
	if _index == _frames.size() - 1:
		_show_frame(0)
	_playing = not _playing
	_clock = 0.0
	_play_button.text = "Pause" if _playing else "Play"


func _process(delta: float) -> void:
	if not _playing:
		return
	_clock += delta
	if _clock >= 1.0:
		_clock = 0.0
		_show_frame(_index + 1)
