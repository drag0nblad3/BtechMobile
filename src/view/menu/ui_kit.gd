class_name UiKit
extends RefCounted
## Small helpers for phone-sized controls built in code.

const FONT := 24
const SMALL := 20


static func label(parent: Control, text: String, size: int = FONT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l


static func button(parent: Control, text: String, on_press: Callable,
		min_size: Vector2 = Vector2(0, 64)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", FONT)
	b.pressed.connect(on_press)
	parent.add_child(b)
	return b


static func panel(parent: Control) -> VBoxContainer:
	var p := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.1, 0.88)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(12)
	p.add_theme_stylebox_override("panel", style)
	parent.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	return v


static func clear(c: Node) -> void:
	for ch in c.get_children():
		ch.queue_free()
