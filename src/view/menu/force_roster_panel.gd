class_name ForceRosterPanel
extends RefCounted
## The selected army and its budget stay visible as catalog choices change.

var frame: PanelContainer
var _select: Button
var _summary: Label
var _budget: ProgressBar
var _rows: VBoxContainer
var _side := 0
var _remove: Callable


func build(parent: Control, side: int, on_select: Callable,
		on_remove: Callable) -> void:
	_side = side
	_remove = on_remove
	frame = PanelContainer.new()
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_stretch_ratio = 1.0
	parent.add_child(frame)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	frame.add_child(box)
	_select = UiKit.button(box, "", on_select, Vector2(0, 52), "subtle")
	_select.add_theme_font_size_override("font_size", 19)
	_summary = UiKit.label(box, "", 17)
	UiSkin.label(_summary, "muted")
	_budget = ProgressBar.new()
	_budget.show_percentage = false
	_budget.custom_minimum_size.y = 12
	box.add_child(_budget)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 120
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 5)
	scroll.add_child(_rows)


func refresh(builder: ForceBuilder, db: UnitDb, active: bool) -> void:
	UiSkin.panel(frame, "focus" if active else "regular")
	_select.text = ("%s  ● ADD HERE" if active else "%s  • SELECT") % Names.side(_side).to_upper()
	UiSkin.button(_select, "selected" if active else "subtle")
	var mechs := builder.mech_ids(_side).size()
	var support := builder.asset_ids(_side).size()
	var spent := builder.bv(_side)
	_summary.text = "%d/%d 'Mechs  ·  %d/%d support\n%d / %d BV  ·  %d remaining" % [
		mechs, builder.max_units(_side), support, ForceBuilder.MAX_ASSETS,
		spent, builder.budget, builder.budget - spent]
	_budget.min_value = 0
	_budget.max_value = builder.budget
	_budget.value = spent
	_budget.add_theme_stylebox_override("background", UiSkin.panel_style(UiSkin.SURFACE_HIGH, UiSkin.BORDER, 0, 3))
	_budget.add_theme_stylebox_override("fill", UiSkin.panel_style(
		UiSkin.RED if spent > builder.budget else UiSkin.CYAN, UiSkin.BORDER, 0, 3))
	UiKit.clear(_rows)
	var roster: Array = builder.rosters[_side]
	if roster.is_empty():
		UiSkin.label(UiKit.label(_rows, "No units yet. Choose one from the catalog.", 16), "muted")
	for i in roster.size():
		var idx := i
		var d: UnitDef = db.get_def(roster[i])
		var row := HBoxContainer.new()
		_rows.add_child(row)
		var name := UiKit.label(row, d.display_name(), 17)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name.max_lines_visible = 2
		UiSkin.label(name)
		var remove := UiKit.button(row, "×", func(): _remove.call(_side, idx),
			Vector2(44, 45), "subtle")
		remove.name = "RemoveUnit"
		remove.tooltip_text = "Remove %s from %s" % [d.display_name(), Names.side(_side)]
		remove.add_theme_font_size_override("font_size", 24)
