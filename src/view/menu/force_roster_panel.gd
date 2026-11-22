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
var _templates: MenuButton
var _choose_template: Callable
var _builder: ForceBuilder


func build(parent: Control, side: int, on_select: Callable,
		on_remove: Callable, on_template: Callable) -> void:
	_side = side
	_remove = on_remove
	_choose_template = on_template
	frame = PanelContainer.new()
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_stretch_ratio = 1.0
	parent.add_child(frame)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	frame.add_child(box)
	_select = UiKit.button(box, "", on_select, Vector2(0, 52), "subtle")
	_select.add_theme_font_size_override("font_size", 19)
	_templates = MenuButton.new()
	_templates.name = "StarterFormations"
	_templates.text = "LOAD FORMATION  ▾"
	_templates.tooltip_text = "Browse ready-made lances and Clan stars by BV tier."
	_templates.custom_minimum_size.y = 48
	_templates.add_theme_font_size_override("font_size", 16)
	UiSkin.button(_templates, "subtle")
	box.add_child(_templates)
	var popup := _templates.get_popup()
	popup.add_theme_font_size_override("font_size", 19)
	_templates.about_to_popup.connect(_populate_templates)
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


## Keep the menu short on mobile: first choose a BV tier, then a role.
## Cost labels are computed with this roster's current pilot skill.
func _populate_templates() -> void:
	var popup := _templates.get_popup()
	popup.clear()
	for child in popup.get_children():
		if child is PopupMenu:
			popup.remove_child(child)
			child.queue_free()
	var forms := StarterFormations.all()
	for tier: int in ForceBuilder.BUDGETS:
		var matches: Array[int] = []
		for i in forms.size():
			if int(forms[i].get("recommended_bv", 0)) == tier:
				matches.append(i)
		if matches.is_empty():
			continue
		var menu := PopupMenu.new()
		menu.name = "BV%d" % tier
		menu.add_theme_font_size_override("font_size", 18)
		popup.add_child(menu)
		popup.add_submenu_node_item("%d BV  ·  %d formations" % [
			tier, matches.size()], menu)
		for i in matches:
			var form: Dictionary = forms[i]
			var preview: Dictionary = StarterFormations.plan(_builder, _side, form)
			var cost := int(preview.get("cost", 0))
			var short_type := "Star" if form["kind"] == "star" else "Lance"
			var caption := "%s  ·  %s  ·  %d BV" % [
				form["name"], short_type, cost]
			menu.add_item(caption, i)
			if not bool(preview.get("ok", false)):
				menu.set_item_disabled(menu.get_item_count() - 1, true)
		menu.id_pressed.connect(func(index: int): _choose_template.call(_side, index))


func refresh(builder: ForceBuilder, db: UnitDb, active: bool) -> void:
	_builder = builder
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
			Vector2(52, 50), "subtle")
		remove.name = "RemoveUnit"
		remove.tooltip_text = "Remove %s from %s" % [d.display_name(), Names.side(_side)]
		remove.add_theme_font_size_override("font_size", 24)
