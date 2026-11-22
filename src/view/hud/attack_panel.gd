class_name AttackPanel
extends RefCounted
## Side-panel content for choosing weapons (or punches/kicks) against a
## target. Each row shows the to-hit number, odds and why; impossible
## options are greyed out with the reason.


## options: [{key, label, to_hit: ToHit, extra: String}], selected: {key: true}.
## A row with a "mode" text also gets a button that calls on_mode(key).
static func build(title: String, options: Array, selected: Dictionary, level: int,
		on_toggle: Callable, on_mode: Callable = Callable()) -> Control:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var head := Label.new()
	head.text = title
	head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_theme_font_size_override("font_size", 22)
	UiSkin.label(head, "heading")
	box.add_child(head)
	UiSkin.rule(box, UiSkin.CYAN)
	var heat := 0
	var expected := 0.0
	for o: Dictionary in options:
		if selected.has(o["key"]) and o["to_hit"].possible():
			heat += int(o.get("heat", 0))
			expected += float(o.get("expected", 0.0))
	if options.any(func(o: Dictionary) -> bool: return o.has("heat")):
		var volley := Label.new()
		volley.text = "SELECTED VOLLEY  ·  +%d heat  ·  ~%.1f expected damage" % [heat, expected]
		volley.add_theme_font_size_override("font_size", 17)
		UiSkin.label(volley, "section")
		box.add_child(volley)
	for o: Dictionary in options:
		var th: ToHit = o["to_hit"]
		var b := CheckButton.new()
		b.custom_minimum_size = Vector2(0, 52)
		b.add_theme_font_size_override("font_size", 19)
		UiSkin.button(b, "selected" if selected.has(o["key"]) else "subtle")
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if th.possible():
			b.text = "%s  %d+ (%s)%s" % [o["label"], th.target(), Names.pct(th.chance()), o.get("extra", "")]
			b.button_pressed = selected.has(o["key"])
			b.toggled.connect(func(on: bool): on_toggle.call(o["key"], on))
		else:
			b.text = "%s: %s" % [o["label"], th.impossible if th.impossible != "" else "needs %d, impossible" % th.target()]
			b.disabled = true
		box.add_child(b)
		if o.has("mode") and on_mode.is_valid():
			var mb := Button.new()
			mb.text = "   Mode: %s (tap to change)" % o["mode"]
			mb.custom_minimum_size = Vector2(0, 48)
			mb.add_theme_font_size_override("font_size", 18)
			mb.alignment = HORIZONTAL_ALIGNMENT_LEFT
			UiSkin.button(mb, "subtle")
			mb.pressed.connect(func(): on_mode.call(o["key"]))
			box.add_child(mb)
		if th.possible() and level != ExplainLevel.OFF:
			var why := Label.new()
			why.text = "   " + th.summary()
			why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			why.add_theme_font_size_override("font_size", 16)
			UiSkin.label(why, "muted")
			box.add_child(why)
	return box
