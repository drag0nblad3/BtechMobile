class_name BattlePauseMenu
extends Control
## Touch-friendly pause overlay; all game actions remain in BattleScene.

signal resumed
signal save_requested
signal exit_requested
signal voxel_toggled
signal shake_toggled

var _message: Label
var _voxel_button: Button
var _shake_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.02, 0.03, 0.83)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var scroll := UiKit.landscape_scroll(self)
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", UiSkin.panel_style(UiSkin.SURFACE, UiSkin.AMBER, 24, 14))
	scroll.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	var heading := Label.new()
	heading.text = "BATTLE PAUSED"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 32)
	UiSkin.label(heading, "heading")
	box.add_child(heading)
	UiSkin.rule(box)
	_message = Label.new()
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.add_theme_font_size_override("font_size", 21)
	UiSkin.label(_message, "muted")
	box.add_child(_message)
	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 24)
	box.add_child(split)
	var actions := VBoxContainer.new()
	actions.size_flags_horizontal = SIZE_EXPAND_FILL
	actions.add_theme_constant_override("separation", 12)
	split.add_child(actions)
	_add_button(actions, "Resume Battle", func(): resumed.emit(), "primary")
	_add_button(actions, "Save Battle", func(): save_requested.emit())
	_add_button(actions, "Save & Exit to Menu", func(): exit_requested.emit(), "subtle")
	var settings := VBoxContainer.new()
	settings.size_flags_horizontal = SIZE_EXPAND_FILL
	settings.add_theme_constant_override("separation", 12)
	split.add_child(settings)
	_voxel_button = _add_button(settings, "Voxel 'Mechs: On", func(): voxel_toggled.emit())
	_shake_button = _add_button(settings, "Camera shake: On", func(): shake_toggled.emit())
	var audio_settings := BattleAudioSettings.new()
	settings.add_child(audio_settings)


func set_message(value: String) -> void:
	_message.text = value


func set_voxel_label(enabled: bool) -> void:
	if _voxel_button != null:
		_voxel_button.text = "Voxel 'Mechs: On" if enabled else "Voxel 'Mechs: Off"


func set_shake_label(on: bool) -> void:
	if _shake_button != null:
		_shake_button.text = "Camera shake: On" if on else "Camera shake: Off"


func _add_button(parent: Control, caption: String, action: Callable, tone: String = "secondary") -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(0, 68)
	button.add_theme_font_size_override("font_size", 24)
	UiSkin.button(button, tone)
	button.pressed.connect(action)
	parent.add_child(button)
	return button
