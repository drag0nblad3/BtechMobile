class_name UiKit
extends RefCounted
## Small helpers for phone-sized controls built in code.

const FONT := 24
const SMALL := 20


static func label(parent: Control, text: String, size: int = FONT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	UiSkin.label(l, "heading" if size >= 30 else "section" if size >= 25 else "muted" if size <= SMALL else "body")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l


static func button(parent: Control, text: String, on_press: Callable,
		min_size: Vector2 = Vector2(0, 64), tone: String = "secondary") -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", FONT)
	UiSkin.button(b, tone)
	b.pressed.connect(on_press)
	parent.add_child(b)
	return b


static func panel(parent: Control) -> VBoxContainer:
	var p := PanelContainer.new()
	UiSkin.panel(p)
	parent.add_child(p)
	if parent is ScrollContainer:
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	return v


static func clear(c: Node) -> void:
	for ch in c.get_children():
		c.remove_child(ch)
		ch.queue_free()


## Width-filling landscape layout with vertical overflow fallback.
static func landscape_scroll(parent: Control, inset: int = 24) -> ScrollContainer:
	var margin := MarginContainer.new()
	parent.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, inset)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	margin.add_child(scroll)
	return scroll


## Fixed navigation bar; content can scroll independently in both dimensions
## when a genuine minimum width (e.g. the region map) exceeds the viewport.
static func screen_body(parent: Control, title: String, back: Callable,
		inset: int = 20) -> VBoxContainer:
	var margin := MarginContainer.new()
	parent.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, inset)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)
	var head := HBoxContainer.new()
	layout.add_child(head)
	var back_button := button(head, "BACK", back, Vector2(132, 56), "subtle")
	back_button.name = "MenuBack"
	var heading := label(head, title, 28)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.autowrap_mode = TextServer.AUTOWRAP_OFF
	heading.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	UiSkin.rule(layout)
	var scroll := ScrollContainer.new()
	scroll.name = "ScreenScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	layout.add_child(scroll)
	var body := panel(scroll)
	body.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return body


static func close_overlay(screen: Control) -> void:
	screen.hide()
	screen.queue_free()
