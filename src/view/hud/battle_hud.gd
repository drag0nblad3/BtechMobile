class_name BattleHud
extends CanvasLayer
## Phone-sized on-screen controls. Emits intents; owns no game logic.
## Layout: status + toggles on top, info and advice under them, combat log
## bottom left, a side panel on the right (record sheet or attack choices),
## and the action bar for the current phase at the bottom.

signal mode_toggled
signal turn_left
signal turn_right
signal confirm
signal cancel
signal charge
signal prone
signal smash
signal masc
signal supercharger
signal leave  ## Move off the battlefield where the mission allows.
signal cinematic_toggled
signal top_down_toggled
signal sheet_toggled
signal log_toggled
signal explain_cycled
signal attack_confirm
signal attack_skip
signal twist_left
signal twist_right
signal flip_arms
signal new_battle
signal save_battle
signal watch_replay
signal battle_forensics
signal pause_toggled
signal exit_battle
signal next_unit  ## Go to the next of your units (camera + selection).
signal undo_move  ## Training: take back your last move.
signal hint  ## Ask what the computer would do in your place (Hint).

const FONT_SIZE := 24
const BUTTON_SIZE := Vector2(140, 60)
const MARGIN := 18

const PHASE_TAGS := ["INIT", "MOVE", "FIRE", "MELEE", "HEAT", "END"]

var _phase_cells: Array[PanelContainer] = []
var _event_panel: PanelContainer
var _event_label: Label
var _event_tween: Tween
var status: Label
var info: Label
var tip: Label
var _tip_panel: PanelContainer
var move_bar: HBoxContainer
var attack_bar: HBoxContainer
var mode_button: Button
var charge_button: Button
var smash_button: Button
var masc_button: Button
var sc_button: Button
var explain_button: Button
var cinematic_button: Button
var undo_button: Button  ## Training only, while a move can be taken back.
var attack_button: Button
var skip_button: Button
var twist_buttons: Array[Button] = []
var flip_button: Button
var side_panel: PanelContainer
var side_box: VBoxContainer
var log_view: CombatLogView
var game_over_box: VBoxContainer
var game_over_detail: Label  ## Training debrief under the result.
var leave_button: Button
var prone_button: Button
var more_button: MenuButton
var _tools_menu: MenuButton
var perf_readout: BattlePerfReadout
var pause_menu: BattlePauseMenu
var roll_feed: RollFeed  ## Recent dice rolls, top right.
var _move_actions: Array[Button] = []
var game_over_label: Label
var sheet_open := false  ## Side panel shows the record sheet, not attack choices.


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var safe := SafeArea.insets(get_viewport())
	for side in ["left", "right", "top", "bottom"]:
		root.add_theme_constant_override("margin_" + side, MARGIN + safe[side])
	add_child(root)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(col)
	var status_panel := PanelContainer.new()
	status_panel.add_theme_stylebox_override("panel", UiSkin.panel_style(Color("#112b39"), UiSkin.CYAN, 7, 7))
	col.add_child(status_panel)
	var heading := _row(status_panel)
	var prefix := _label(heading, 17)
	prefix.text = "COMMAND  /"
	UiSkin.label(prefix, "section")
	status = _label(heading, 21)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiSkin.label(status, "heading")
	_event_panel = PanelContainer.new()
	_event_panel.visible = false
	_event_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.add_child(_event_panel)
	_event_label = _label(_event_panel, 19)
	_event_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_event_panel.custom_minimum_size.x = 170
	# The phase timeline sits at the right of the status row (one row, not
	# two), leaving more of a 720 px screen for the map.
	var phase_strip := HBoxContainer.new()
	phase_strip.add_theme_constant_override("separation", 4)
	phase_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.add_child(phase_strip)
	for tag in PHASE_TAGS:
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(70, 0)
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		phase_strip.add_child(cell)
		_phase_cells.append(cell)
		var stage := _label(cell, 14)
		stage.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stage.text = tag
		stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_phase(Phase.Kind.INITIATIVE)
	# Give the full battle status its own line: seven 140px buttons and a
	# turn/mission label cannot fit side by side at 1280x720 on a phone.
	var shortcuts := _row(col)
	shortcuts.add_theme_constant_override("separation", 6)
	_button(shortcuts, "Pause", pause_toggled)
	_button(shortcuts, "Log", log_toggled)
	_button(shortcuts, "Sheet", sheet_toggled)
	_button(shortcuts, "Next ▸", next_unit).tooltip_text = "Go to your next unit"
	explain_button = _button(shortcuts, "Explain", explain_cycled)
	cinematic_button = _button(shortcuts, "Cine: Off", cinematic_toggled)
	undo_button = _button(shortcuts, "Undo move", undo_move)
	undo_button.tooltip_text = "Training: take back your last move (no dice rolled since)"
	_tools_menu = MenuButton.new()
	_tools_menu.text = "More ▾"
	_tools_menu.tooltip_text = "Save, replay and camera options"
	shortcuts.add_child(_tools_menu)
	UiSkin.button(_tools_menu, "subtle")
	var popup := _tools_menu.get_popup()
	popup.add_item("Save battle", 0)
	popup.add_item("Watch replay", 1)
	popup.add_item("Top-down map", 2)
	popup.add_item("Battle analysis", 3)
	popup.add_item("Performance overlay", 4)
	popup.id_pressed.connect(_on_tool_action)
	for b in shortcuts.get_children():
		if b is Button:
			b.custom_minimum_size = Vector2(100, 46)
			b.add_theme_font_size_override("font_size", 17)
	UiSkin.button(shortcuts.get_child(0) as Button, "primary")
	info = _label(col, 22)
	UiSkin.label(info, "section")
	info.visible = false  # No empty advice row over the battlefield.
	var middle := _row(col)
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var left := VBoxContainer.new()
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.add_child(left)
	_tip_panel = PanelContainer.new()
	_tip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_tip_panel.add_theme_stylebox_override("panel", UiSkin.panel_style(Color("#0a1824cc"), UiSkin.BORDER, 8, 7))
	left.add_child(_tip_panel)
	_tip_panel.visible = false
	tip = _label(_tip_panel, 20)
	UiSkin.label(tip, "muted")
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.custom_minimum_size.x = 420
	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(spacer)
	log_view = CombatLogView.new()
	left.add_child(log_view)
	_build_side_panel(middle)
	_build_game_over(middle)
	# A compact main bar plus a menu for the less-common movement actions.
	var action_store := Control.new()
	action_store.visible = false
	add_child(action_store)
	move_bar = _bar(col)
	mode_button = _button(move_bar, "Walk", mode_toggled)
	_button(move_bar, "◀ Turn", turn_left)
	_button(move_bar, "Turn ▶", turn_right)
	more_button = MenuButton.new()
	more_button.text = "Actions"
	more_button.tooltip_text = "Prone, charge, equipment and mission actions"
	more_button.custom_minimum_size = BUTTON_SIZE
	more_button.add_theme_font_size_override("font_size", FONT_SIZE)
	UiSkin.button(more_button, "subtle")
	move_bar.add_child(more_button)
	more_button.get_popup().add_theme_stylebox_override("panel", UiSkin.panel_style())
	more_button.get_popup().add_theme_font_size_override("font_size", 20)
	more_button.about_to_popup.connect(_populate_move_menu)
	more_button.get_popup().id_pressed.connect(_on_move_action)
	charge_button = _button(action_store, "Charge", charge)
	smash_button = _button(action_store, "Smash in", smash)
	masc_button = _button(action_store, "MASC", masc)
	sc_button = _button(action_store, "Supercharger", supercharger)
	leave_button = _button(action_store, "Leave map", leave)
	prone_button = _button(action_store, "Prone", prone)
	_move_actions = [prone_button, charge_button, smash_button, masc_button, sc_button, leave_button]
	for b in _move_actions:
		b.visible = false
	_button(move_bar, "Hint", hint).tooltip_text = "What would an Elite computer player do here?"
	_button(move_bar, "Cancel", cancel)
	UiSkin.button(_button(move_bar, "Confirm", confirm), "primary")
	refresh_move_actions()
	attack_bar = _bar(col)
	twist_buttons = [_button(attack_bar, "◀ Twist", twist_left), _button(attack_bar, "Twist ▶", twist_right)]
	flip_button = _button(attack_bar, "Flip arms", flip_arms)
	flip_button.visible = false
	_button(attack_bar, "Hint", hint).tooltip_text = "What would an Elite computer player do here?"
	skip_button = _button(attack_bar, "Hold Fire", attack_skip)
	attack_button = _button(attack_bar, "Fire", attack_confirm)
	UiSkin.button(attack_button, "danger")
	show_move_controls(false)
	show_attack_controls(false)
	roll_feed = RollFeed.new()
	roll_feed.offset_right = -(MARGIN + safe["right"])
	roll_feed.offset_top = 100 + safe["top"]
	add_child(roll_feed)
	pause_menu = BattlePauseMenu.new()
	pause_menu.visible = false
	add_child(pause_menu)
	pause_menu.resumed.connect(func(): pause_toggled.emit())
	pause_menu.save_requested.connect(func(): save_battle.emit())
	pause_menu.exit_requested.connect(func(): exit_battle.emit())
	perf_readout = BattlePerfReadout.new()
	add_child(perf_readout)
	perf_readout.visible = false


func _on_tool_action(id: int) -> void:
	match id:
		0: save_battle.emit()
		1: watch_replay.emit()
		2: top_down_toggled.emit()
		3: battle_forensics.emit()
		4: perf_readout.visible = not perf_readout.visible


## Refresh the Actions button from the same eligibility flags MovementInput sets.
func refresh_move_actions() -> void:
	if more_button == null:
		return
	var available := false
	for b in _move_actions:
		if b.visible:
			available = true
			break
	more_button.disabled = not available


func _populate_move_menu() -> void:
	var popup := more_button.get_popup()
	popup.clear()
	for i in _move_actions.size():
		if _move_actions[i].visible:
			popup.add_item(_move_actions[i].text, i)


func _on_move_action(id: int) -> void:
	if id >= 0 and id < _move_actions.size() and _move_actions[id].visible:
		_move_actions[id].pressed.emit()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key := event as InputEventKey
		if not key.pressed or key.echo or key.keycode != KEY_ESCAPE:
			return
		get_viewport().set_input_as_handled()
		pause_toggled.emit()


func _build_side_panel(parent: Control) -> void:
	side_panel = PanelContainer.new()
	side_panel.custom_minimum_size = Vector2(470, 0)
	side_panel.add_theme_stylebox_override("panel",
		UiSkin.panel_style(Color("#0d1c2ae8"), UiSkin.CYAN, 12))
	parent.add_child(side_panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side_panel.add_child(scroll)
	side_box = VBoxContainer.new()
	side_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(side_box)
	side_panel.visible = false


func _build_game_over(parent: Control) -> void:
	game_over_box = VBoxContainer.new()
	game_over_box.visible = false
	parent.add_child(game_over_box)
	game_over_label = _label(game_over_box, 34)
	UiSkin.label(game_over_label, "heading")
	game_over_detail = _label(game_over_box, FONT_SIZE)
	game_over_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	game_over_detail.custom_minimum_size.x = 760  # training debriefs run long
	UiSkin.button(_button(game_over_box, "Analyze Battle", battle_forensics), "primary")
	_button(game_over_box, "New Battle", new_battle)


## Replaces the side panel's content (record sheet, weapon list...).
func show_side(content: Control) -> void:
	for c in side_box.get_children():
		c.queue_free()
	if content:
		side_box.add_child(content)
	side_panel.visible = content != null


## A narrow tactical timeline, independent of gameplay state.
func set_phase(phase: int) -> void:
	for i in _phase_cells.size():
		var active := i == phase
		var previous := i < phase
		var fill := Color("#244e56") if active else Color("#1a323b") if previous else UiSkin.SURFACE
		var border := UiSkin.AMBER if active else UiSkin.BORDER
		_phase_cells[i].add_theme_stylebox_override("panel", UiSkin.panel_style(fill, border, 3, 4))
		var label := _phase_cells[i].get_child(0) as Label
		UiSkin.label(label, "heading" if active else "muted")


## Short, non-blocking combat confirmation; subsequent shots replace it.
func show_combat_event(e: GameEvent) -> void:
	if _event_panel == null:
		return
	var message := ""
	var hue := UiSkin.CYAN
	match e.type:
		GameEvent.WEAPON_FIRED:
			if e.data.get("no_ammo", false):
				message = "NO AMMO"
				hue = UiSkin.AMBER
			elif e.data.get("streak_held", false):
				message = "NO LOCK"
				hue = UiSkin.AMBER
			elif bool(e.data.get("hit", false)):
				message = "TARGET HIT"
				hue = UiSkin.GREEN
			else:
				message = "SHOT MISSED"
				hue = UiSkin.MUTED
		GameEvent.UNIT_DESTROYED:
			message = "UNIT DESTROYED"
			hue = UiSkin.RED
		GameEvent.AMMO_EXPLOSION:
			message = "AMMO DETONATION"
			hue = UiSkin.RED
		GameEvent.BUILDING:
			if e.data.get("kind") in ["collapsed", "flattened", "bridge_collapsed"]:
				message = "STRUCTURE DOWN"
				hue = UiSkin.AMBER
	if message == "":
		return
	if _event_tween != null and _event_tween.is_running():
		_event_tween.kill()
	_event_panel.visible = true
	_event_panel.modulate.a = 1.0
	_event_panel.add_theme_stylebox_override("panel",
		UiSkin.panel_style(UiSkin.SURFACE_HIGH, hue, 5, 4))
	_event_label.text = message
	_event_label.add_theme_color_override("font_color", hue)
	_event_tween = create_tween()
	_event_tween.tween_interval(0.5)
	_event_tween.tween_property(_event_panel, "modulate:a", 0.0, 0.75)
	_event_tween.tween_callback(func(): _event_panel.visible = false)


func set_status(text: String) -> void:
	status.text = text


func set_info(text: String) -> void:
	info.text = text
	info.visible = not text.strip_edges().is_empty()


func set_tip(text: String) -> void:
	tip.text = text
	_tip_panel.visible = not text.strip_edges().is_empty()


func set_mode_label(text: String) -> void:
	mode_button.text = text


func set_cinematic_label(enabled: bool) -> void:
	cinematic_button.text = "Cine: On" if enabled else "Cine: Off"
	UiSkin.button(cinematic_button, "selected" if enabled else "secondary")


func set_explain_label(level: int) -> void:
	explain_button.text = "Explain: " + ExplainLevel.name_of(level)


func show_move_controls(visible_: bool) -> void:
	if not visible_ and more_button != null:
		more_button.get_popup().hide()
	move_bar.visible = visible_
	move_bar.get_parent().visible = visible_


func show_attack_controls(visible_: bool, fire_text: String = "Fire", skip_text: String = "Hold Fire") -> void:
	attack_bar.visible = visible_
	attack_bar.get_parent().visible = visible_
	for b in twist_buttons:
		b.visible = fire_text == "Fire"
	attack_button.text = fire_text
	skip_button.text = skip_text


func show_game_over(text: String, detail: String = "") -> void:
	game_over_label.text = text
	game_over_detail.text = detail
	game_over_detail.visible = detail != ""
	game_over_box.visible = true
	sheet_open = false
	show_side(null)  # No contextual panel survives the end of battle.
	if _tools_menu != null:
		_tools_menu.get_popup().hide()
	show_move_controls(false)
	show_attack_controls(false)


func _row(parent: Control) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r


func _bar(parent: Control) -> HBoxContainer:
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UiSkin.panel_style(Color("#0c202df0"), UiSkin.BORDER, 8, 8))
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(frame)
	var bar := _row(frame)
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 12)
	return bar


func _label(parent: Control, size: int = FONT_SIZE) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 3)
	UiSkin.label(l)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _button(parent: Control, text: String, sig: Signal) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = BUTTON_SIZE
	b.add_theme_font_size_override("font_size", FONT_SIZE)
	UiSkin.button(b)
	b.pressed.connect(func(): sig.emit())
	parent.add_child(b)
	return b

