class_name BattlePauseMenu
extends Control
## Touch-friendly pause overlay; all game actions remain in BattleScene.

signal resumed
signal save_requested
signal exit_requested

var _message: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.02, 0.03, 0.83)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(470, 0)
	panel.add_theme_stylebox_override("panel", UiSkin.panel_style(UiSkin.SURFACE, UiSkin.AMBER, 24, 14))
	center.add_child(panel)
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
	var audio_settings := BattleAudioSettings.new()
	box.add_child(audio_settings)
	_add_button(box, "Resume Battle", func(): resumed.emit(), "primary")
	_add_button(box, "Save Battle", func(): save_requested.emit())
	_add_button(box, "Save & Exit to Menu", func(): exit_requested.emit(), "subtle")


func set_message(value: String) -> void:
	_message.text = value


func _add_button(parent: Control, caption: String, action: Callable, tone: String = "secondary") -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(0, 68)
	button.add_theme_font_size_override("font_size", 24)
	UiSkin.button(button, tone)
	button.pressed.connect(action)
	parent.add_child(button)
