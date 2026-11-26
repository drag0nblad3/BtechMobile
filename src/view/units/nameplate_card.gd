class_name NameplateCard
extends Control
## Retained canvas geometry: no per-frame text shaping or draw-string commands.

const NAME_SIZE := 19
const DETAIL_SIZE := 15
const PAD := 7.0
var extent := Vector2.ZERO
var _content: Dictionary = {}
var _panel: Panel
var _lines: Array[Label] = []
var _leader: Line2D
var _dot: ColorRect


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_leader = Line2D.new()
	_leader.width = 1.5
	_leader.antialiased = false
	_leader.z_index = -1
	add_child(_leader)
	_dot = ColorRect.new()
	_dot.size = Vector2(4, 4)
	_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dot.z_index = -1
	add_child(_dot)
	_panel = Panel.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	for i in 3:
		var label := Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", NAME_SIZE if i == 0 else DETAIL_SIZE)
		_panel.add_child(label)
		_lines.append(label)
	hide_card()


func set_content(data: Dictionary) -> void:
	if _content == data:
		return
	_content = data.duplicate()
	var tint: Color = data["tint"]
	var style := UiSkin.panel_style(Color("#091722eb"), tint, 0, 3)
	_panel.add_theme_stylebox_override("panel", style)
	_lines[0].text = data["name"]
	_lines[1].text = data["health"]
	_lines[2].text = data["attack"]
	_lines[0].add_theme_color_override("font_color", tint)
	_lines[1].add_theme_color_override("font_color", data["health_color"])
	_lines[2].add_theme_color_override("font_color", UiSkin.AMBER)
	_lines[2].visible = not _lines[2].text.is_empty()
	var width := 0.0
	for label in _lines:
		width = maxf(width, label.get_minimum_size().x)
	extent = Vector2(ceilf(width) + PAD * 2.0, 66.0 if _lines[2].visible else 48.0)
	_panel.size = extent
	for i in 3:
		_lines[i].position = Vector2(PAD, [0, 21, 39][i])
		_lines[i].size = Vector2(extent.x - PAD * 2.0, 23)
	_leader.default_color = Color(tint, 0.8)
	_dot.color = tint


func place(actual: Rect2, preferred: Rect2, anchor: Vector2, selected: bool) -> void:
	visible = true
	position = actual.position
	_panel.z_index = 2 if selected else 1
	var local := anchor - actual.position
	var end := Vector2(clampf(local.x, 0.0, extent.x), clampf(local.y, 0.0, extent.y))
	var displaced := actual.position.distance_to(preferred.position) >= 12.0 and local.distance_to(end) >= 2.0
	_leader.visible = displaced
	_dot.visible = displaced
	if displaced:
		_leader.points = PackedVector2Array([local, end])
		_dot.position = local - Vector2(2, 2)


func hide_card() -> void:
	visible = false
