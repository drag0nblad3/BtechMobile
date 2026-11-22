extends Control
## Tactical Academy's first tool: forensic analysis of real combat telemetry.
## Selecting a finding jumps to the closest available replay checkpoint.

const MAX_TIMELINE := 500

var _frames: Array = []
var _report: Dictionary = {}
var _selected_frame := -1
var _inspect: Button
var _detail: Label
var _moments: ItemList
var _timeline: ItemList


## Deliberate Android Back navigation when automatic exit is disabled.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_tree().change_scene_to_file(BattleLaunch.MENU_SCENE)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key := event as InputEventKey
		if not key.pressed or key.echo or key.keycode != KEY_ESCAPE:
			return
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file(BattleLaunch.MENU_SCENE)


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	_frames = BattleSave.load_replay()
	var labels := {}
	if not _frames.is_empty():
		var db := UnitDb.load_dir()
		var terrain := TerrainDb.load_file()
		var state := BattleRecorder.state_at(_frames.back(), db, terrain)
		if state != null:
			for u: Unit in state.all_units():
				labels[str(u.id)] = {"name": u.def.display_name(), "side": u.side}
	_report = BattleForensics.analyze(_frames, labels)
	_build_ui()


func _build_ui() -> void:
	UiSkin.backdrop(self)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	margin.add_child(col)
	var header := HBoxContainer.new()
	col.add_child(header)
	var title := _label(header, "TACTICAL ACADEMY  /  BATTLE FORENSICS", 28)
	UiSkin.label(title, "heading")
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	_button(header, "Replay", _open_replay)
	_button(header, "Menu", func(): get_tree().change_scene_to_file(BattleLaunch.MENU_SCENE))
	var s: Dictionary = _report["summary"]
	var recorded := int(s["events"])
	var overview := ""
	if _frames.is_empty():
		overview = "No recorded battle. Finish or archive a battle to analyze it."
	elif recorded == 0:
		overview = "This replay predates forensic telemetry. Play a new battle to collect attack and damage statistics."
	else:
		overview = "%d actions  ·  %d hits  ·  %.1f expected hits (2d6 odds)  ·  %d logged damage  ·  %d wrecks  ·  %d failed piloting rolls" % [
				int(s["attacks"]), int(s["hits"]), float(s["expected_hits"]),
				int(s["damage"]), int(s["kills"]), int(s["psr_failures"])]
	UiSkin.rule(col)
	_label(col, overview, 21)
	var split := HBoxContainer.new()
	split.size_flags_vertical = SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 14)
	col.add_child(split)
	var left := _panel(split, 0.45)
	_label(left, "DECISIVE MOMENTS  /  tap to inspect", 22)
	_moments = ItemList.new()
	_moments.size_flags_vertical = SIZE_EXPAND_FILL
	_moments.add_theme_font_size_override("font_size", 19)
	UiSkin.list_control(_moments)
	left.add_child(_moments)
	var insights: Array = _report["moments"]
	for m: Dictionary in insights.slice(0, 120):
		_moments.add_item("T%d · %s — %s" % [int(m["turn"]), m["title"], m["detail"]])
	if insights.is_empty():
		_moments.add_item("No decisive-event markers available")
	_moments.item_selected.connect(_on_moment)
	_label(left, "UNIT PERFORMANCE", 22)
	var stat_scroll := ScrollContainer.new()
	stat_scroll.custom_minimum_size.y = 175
	stat_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	left.add_child(stat_scroll)
	var unit_stats := VBoxContainer.new()
	unit_stats.size_flags_horizontal = SIZE_EXPAND_FILL
	stat_scroll.add_child(unit_stats)
	for u: Dictionary in _report["units"]:
		var attacks := int(u["attacks"])
		var accuracy := 100.0 * float(u["hits"]) / float(attacks) if attacks > 0 else 0.0
		var side := "Side %d" % int(u["side"]) if int(u["side"]) >= 0 else "Unknown side"
		var info := "%s · %s\n%d/%d hits (%.0f%%, expected %.1f) · dealt %d / received %d damage\nPeak heat %d · criticals %d · failed PSRs %d" % [
				String(u["name"]), side, int(u["hits"]), attacks, accuracy,
				float(u["expected_hits"]), int(u["damage_dealt"]),
				int(u["damage_taken"]), int(u["heat_peak"]),
				int(u["criticals_taken"]), int(u["psr_failures"])]
		var stat_line := _label(unit_stats, info, 18)
		stat_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if _report["units"].is_empty():
		_label(unit_stats, "No unit statistics recorded.", 18)
	var right := _panel(split, 0.55)
	var timeline: Array = _report["timeline"]
	_label(right, "EVENT LEDGER  /  %d of %d recorded events" % [mini(MAX_TIMELINE, timeline.size()), timeline.size()], 22)
	_timeline = ItemList.new()
	_timeline.size_flags_vertical = SIZE_EXPAND_FILL
	_timeline.add_theme_font_size_override("font_size", 19)
	UiSkin.list_control(_timeline)
	right.add_child(_timeline)
	for e: Dictionary in timeline.slice(0, MAX_TIMELINE):
		_timeline.add_item("T%d · %s" % [int(e["turn"]), String(e["text"])])
	_timeline.item_selected.connect(_on_timeline)
	_detail = _label(right, "Select a moment or event to inspect its replay checkpoint.", 18)
	_detail.custom_minimum_size.y = 50
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_inspect = _button(right, "Inspect in replay", _open_replay)
	UiSkin.button(_inspect, "primary")
	_inspect.disabled = true
	_label(col, "Analysis uses recorded outcomes, not speculative causes. Unframed events jump to the nearest later state; damage totals reflect logged events.", 16)


func _panel(parent: HBoxContainer, share: float) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = share
	UiSkin.panel(panel, "info")
	parent.add_child(panel)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	panel.add_child(inner)
	return inner


func _label(parent: Control, value: String, size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	UiSkin.label(label, "section" if size >= 22 else "muted" if size <= 18 else "body")
	parent.add_child(label)
	return label


func _button(parent: Control, value: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = value
	b.custom_minimum_size = Vector2(138, 57)
	b.add_theme_font_size_override("font_size", 19)
	UiSkin.button(b)
	b.pressed.connect(action)
	parent.add_child(b)
	return b


func _on_moment(index: int) -> void:
	var moments: Array = _report["moments"]
	if index >= moments.size():
		return
	var m: Dictionary = moments[index]
	_select_frame(int(m["frame"]), String(m["detail"]))


func _on_timeline(index: int) -> void:
	var timeline: Array = _report["timeline"]
	if index >= timeline.size():
		return
	var e: Dictionary = timeline[index]
	_select_frame(int(e["frame"]), String(e["text"]))


func _select_frame(index: int, detail: String) -> void:
	_selected_frame = index
	_inspect.disabled = false
	_detail.text = "Replay checkpoint %d/%d · %s" % [
			index + 1, _frames.size(), detail]


func _open_replay() -> void:
	if _selected_frame >= 0:
		BattleLaunch.replay_focus = _selected_frame
	get_tree().change_scene_to_file("res://scenes/battle_replay.tscn")
