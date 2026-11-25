class_name UiSkin
extends RefCounted
## Shared visual tokens for the tactical console UI; presentation only.

const BACKGROUND := Color("#07131e")
const SURFACE := Color("#0d1c2a")
const SURFACE_HIGH := Color("#162a39")
const BORDER := Color("#365063")
const TEXT := Color("#edf4f7")
const MUTED := Color("#a9bfcb")
const CYAN := Color("#72d2d6")
const AMBER := Color("#f0be70")
const RED := Color("#f28a7b")
const GREEN := Color("#9cddba")


static func backdrop(parent: Control) -> void:
	var bg := ColorRect.new()
	bg.color = BACKGROUND
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bar := ColorRect.new()
	bar.color = AMBER.darkened(0.2)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(bar)
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = 3


static func panel_style(fill: Color = SURFACE, edge: Color = BORDER,
		pad: int = 12, radius: int = 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = edge
	s.set_border_width_all(1)
	s.border_width_left = 3
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(pad)
	return s


static func panel(panel_node: PanelContainer, tone: String = "regular") -> void:
	var edge := AMBER if tone == "focus" else CYAN if tone == "info" else BORDER
	panel_node.add_theme_stylebox_override("panel", panel_style(SURFACE, edge))


static func label(l: Label, tone: String = "body") -> void:
	l.add_theme_color_override("font_color", AMBER if tone == "heading" else CYAN if tone == "section" else MUTED if tone == "muted" else TEXT)


static func button(b: Button, tone: String = "secondary") -> void:
	var edge := AMBER if tone == "primary" else RED if tone == "danger" else CYAN if tone == "selected" else BORDER
	var base := Color("#55402b") if tone == "primary" else Color("#4b2c31") if tone == "danger" else Color("#17404b") if tone == "selected" else SURFACE_HIGH
	if tone == "subtle":
		base = SURFACE
	var normal := panel_style(base, edge, 8, 7)
	var hover := panel_style(base.lightened(0.15), edge.lightened(0.17), 8, 7)
	var pressed := panel_style(base.darkened(0.23), edge, 8, 7)
	var disabled := panel_style(Color("#101b25"), Color("#263847"), 8, 7)
	var focus := panel_style(Color(0.0, 0.0, 0.0, 0.0), CYAN, 8, 7)
	focus.set_border_width_all(2)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("disabled", disabled)
	b.add_theme_stylebox_override("focus", focus)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(key, TEXT)
	b.add_theme_color_override("font_disabled_color", Color("#748795"))


static func list_control(items: ItemList) -> void:
	items.add_theme_stylebox_override("panel", panel_style(SURFACE_HIGH, BORDER, 8))
	items.add_theme_stylebox_override("selected", panel_style(Color("#1c4350"), CYAN, 6, 5))
	items.add_theme_stylebox_override("selected_focus", panel_style(Color("#24515d"), CYAN, 6, 5))
	items.add_theme_color_override("font_color", TEXT)
	items.add_theme_color_override("font_selected_color", TEXT)


static func rule(parent: Control, color: Color = AMBER) -> void:
	var line := ColorRect.new()
	line.color = color
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.custom_minimum_size.y = 2.0
	parent.add_child(line)
