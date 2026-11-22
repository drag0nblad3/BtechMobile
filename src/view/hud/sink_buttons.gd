class_name SinkButtons
extends RefCounted
## Record-sheet buttons to switch heat sinks off or back on at the End Phase
## (HeatSinkSwitch). They send "sinks:<n>" through the sheet's request callback.
## Also the stealth armor switch (Stealth), which sends "stealth:on" / "stealth:off".


static func row(u: Unit, on_request: Callable) -> Control:
	var box := HBoxContainer.new()
	var planned := HeatSinkSwitch.planned(u)
	var l := Label.new()
	l.text = "Sinks off at End Phase: %d" % planned
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 19)
	box.add_child(l)
	for step: int in [-1, 1]:
		var b := Button.new()
		b.text = "Switch one on" if step < 0 else "Switch one off"
		b.disabled = HeatSinkSwitch.problem(u, planned + step) != ""
		b.custom_minimum_size = Vector2(0, 58)
		b.add_theme_font_size_override("font_size", 19)
		b.pressed.connect(func() -> void: on_request.call("sinks:%d" % (planned + step)))
		box.add_child(b)
	return box


## Stealth armor on/off from the next End Phase, or null without stealth armor.
static func stealth_row(u: Unit, on_request: Callable) -> Control:
	if Stealth.problem(u) != "":
		return null
	var off := Stealth.planned_off(u)
	var b := Button.new()
	b.text = "Stealth armor %s at End Phase: switch it %s" % ["off" if off else "on", "on" if off else "off"]
	b.custom_minimum_size = Vector2(0, 58)
	b.add_theme_font_size_override("font_size", 19)
	b.pressed.connect(func() -> void: on_request.call("stealth:" + ("on" if off else "off")))
	return b
