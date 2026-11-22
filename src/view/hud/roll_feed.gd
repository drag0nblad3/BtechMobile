class_name RollFeed
extends VBoxContainer
## Top-right stack of recent dice rolls (RollText lines). Each line fades
## after a few seconds; only the newest MAX_LINES stay. Display only.

const MAX_LINES := 6
const LIFETIME := 5.0
const WIDTH := 470.0
const TONES := {"good": UiSkin.GREEN, "bad": UiSkin.RED, "warn": UiSkin.AMBER, "info": UiSkin.MUTED}


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	custom_minimum_size.x = WIDTH
	add_theme_constant_override("separation", 3)


## Show the event's roll line, if it has one.
func add_event(e: GameEvent, s: GameState) -> void:
	var line := RollText.line(e, s)
	if not line.is_empty():
		add_line(String(line["text"]), String(line.get("tone", "info")))


func add_line(text: String, tone: String) -> void:
	var hue: Color = TONES.get(tone, UiSkin.MUTED)
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", UiSkin.panel_style(Color("#0a1824dd"), hue.darkened(0.35), 6, 3))
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", hue)
	panel.add_child(label)
	add_child(panel)
	while get_child_count() > MAX_LINES:
		var old := get_child(0)
		remove_child(old)
		old.queue_free()
	var fade := panel.create_tween()
	fade.tween_interval(LIFETIME)
	fade.tween_property(panel, "modulate:a", 0.0, 0.6)
	fade.tween_callback(panel.queue_free)
