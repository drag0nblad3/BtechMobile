class_name AttackPanel
extends RefCounted
## Side-panel content for choosing weapons (or punches/kicks) against a
## target. Each row shows the to-hit number, odds and why; impossible
## options are greyed out with the reason.


## options: [{key, label, to_hit: ToHit, extra: String}], selected: {key: true}.
## A row with a "mode" text also gets a button that calls on_mode(key).
static func build(title: String, options: Array, selected: Dictionary, level: int,
		on_toggle: Callable, on_mode: Callable = Callable(), forecast: String = "") -> Control:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 4)
	var head := Label.new()
	head.text = title
	head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_theme_font_size_override("font_size", 22)
	UiSkin.label(head, "heading")
	box.add_child(head)
	UiSkin.rule(box, UiSkin.CYAN)
	if not forecast.is_empty():
		var summary := UiKit.label(box, forecast, 16)
		summary.autowrap_mode = TextServer.AUTOWRAP_OFF
		summary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		summary.tooltip_text = "Estimated damage, chance of at least one hit, weapon heat and approximate end heat. Before armor and special effects."
		summary.name = "VolleyForecast"
		UiSkin.label(summary, "body")
		UiSkin.rule(box)
	for o: Dictionary in options:
		_add_row(box, o, selected, level, on_toggle, on_mode)
	return box


static func _add_row(box: VBoxContainer, o: Dictionary, selected: Dictionary, level: int,
		on_toggle: Callable, on_mode: Callable) -> void:
	var th: ToHit = o["to_hit"]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	box.add_child(row)
	var b := CheckButton.new()
	b.custom_minimum_size = Vector2(0, 46)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 18)
	UiSkin.button(b, "selected" if selected.has(o["key"]) else "subtle")
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var extra := String(o.get("extra", "")).strip_edges()
	if th.possible():
		b.text = "%s  %d+ (%s)" % [o["label"], th.target(), Names.pct(th.chance())]
		if extra.begins_with("(aimed at"):
			b.text += " ↗"
		elif o["key"] is String and not extra.is_empty():
			b.text += " · " + extra
		b.button_pressed = selected.has(o["key"])
		b.toggled.connect(func(on: bool): on_toggle.call(o["key"], on))
	else:
		b.text = "%s · unavailable" % o["label"]
		b.disabled = true
	row.add_child(b)
	var detail := VBoxContainer.new()
	detail.visible = false
	var reason := th.summary() if th.possible() else (th.impossible if th.impossible != "" else "Needs %d, impossible" % th.target())
	var description := extra
	if level != ExplainLevel.OFF or not th.possible():
		description += ("\n" if not description.is_empty() else "") + reason
	if o.has("mode"):
		description += ("\n" if not description.is_empty() else "") + "Mode: " + String(o["mode"])
	var why := UiKit.label(detail, description, 16)
	why.name = "WeaponModifiers"
	if not description.is_empty():
		var info := UiKit.button(row, "?", func(): detail.visible = not detail.visible, Vector2(44, 46), "subtle")
		info.tooltip_text = description
		info.name = "WeaponDetails"
	if o.has("mode") and on_mode.is_valid():
		var short_mode := String(o["mode"]).get_slice(" (", 0).get_slice(":", 0)
		var mb := UiKit.button(row, short_mode, func(): on_mode.call(o["key"]), Vector2(94, 46), "subtle")
		mb.clip_text = true
		mb.add_theme_font_size_override("font_size", 16)
		mb.tooltip_text = String(o["mode"]) + " · tap to change"
	box.add_child(detail)
