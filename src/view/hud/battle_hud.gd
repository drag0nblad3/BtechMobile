class_name BattleHud
extends CanvasLayer
## Phone-sized on-screen controls. Emits intents; owns no game logic.

signal mode_toggled
signal turn_left
signal turn_right
signal confirm
signal cancel
signal top_down_toggled

const FONT_SIZE := 26
const BUTTON_SIZE := Vector2(150, 72)
const MARGIN := 18

var status: Label
var info: Label
var move_bar: HBoxContainer
var mode_button: Button


func _ready() -> void:
	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var safe := _safe_area_insets()
	for side in ["left", "right", "top", "bottom"]:
		root.add_theme_constant_override("margin_" + side, MARGIN + safe[side])
	add_child(root)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(col)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(top)
	status = _label(top)
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(top, "Map View", top_down_toggled)
	info = _label(col)
	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(spacer)
	move_bar = HBoxContainer.new()
	move_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	move_bar.add_theme_constant_override("separation", 12)
	col.add_child(move_bar)
	mode_button = _button(move_bar, "Walk", mode_toggled)
	_button(move_bar, "◀ Turn", turn_left)
	_button(move_bar, "Turn ▶", turn_right)
	_button(move_bar, "Cancel", cancel)
	_button(move_bar, "Confirm", confirm)
	show_move_controls(false)


func set_status(text: String) -> void:
	status.text = text


func set_info(text: String) -> void:
	info.text = text


func set_mode_label(text: String) -> void:
	mode_button.text = text


func show_move_controls(visible_: bool) -> void:
	move_bar.visible = visible_


func _label(parent: Control) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", FONT_SIZE)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _button(parent: Control, text: String, sig: Signal) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = BUTTON_SIZE
	b.add_theme_font_size_override("font_size", FONT_SIZE)
	b.pressed.connect(func(): sig.emit())
	parent.add_child(b)
	return b


## Insets (in HUD pixels) that keep controls clear of notches, camera cutouts and
## gesture bars on phones. All zero on desktop.
func _safe_area_insets() -> Dictionary:
	var out := {"left": 0, "right": 0, "top": 0, "bottom": 0}
	if not OS.has_feature("mobile"):
		return out
	var screen := Vector2(DisplayServer.screen_get_size())
	var safe := Rect2(DisplayServer.get_display_safe_area())
	if screen.x <= 0.0 or screen.y <= 0.0 or safe.size.x <= 0.0:
		return out
	var to_hud := get_viewport().get_visible_rect().size / screen
	out["left"] = ceili(safe.position.x * to_hud.x)
	out["top"] = ceili(safe.position.y * to_hud.y)
	out["right"] = ceili((screen.x - safe.end.x) * to_hud.x)
	out["bottom"] = ceili((screen.y - safe.end.y) * to_hud.y)
	return out
