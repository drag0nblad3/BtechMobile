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

const FONT_SIZE := 24
const BUTTON_SIZE := Vector2(140, 68)
const MARGIN := 18

var status: Label
var info: Label
var tip: Label
var move_bar: HBoxContainer
var attack_bar: HBoxContainer
var mode_button: Button
var charge_button: Button
var smash_button: Button
var masc_button: Button
var sc_button: Button
var explain_button: Button
var cinematic_button: Button
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
var pause_menu: BattlePauseMenu
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
	var heading := _row(col)
	status = _label(heading)
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Give the full battle status its own line: seven 140px buttons and a
	# turn/mission label cannot fit side by side at 1280x720 on a phone.
	var shortcuts := _row(col)
	shortcuts.add_theme_constant_override("separation", 6)
	_button(shortcuts, "Pause", pause_toggled)
	_button(shortcuts, "Save", save_battle)
	_button(shortcuts, "Replay", watch_replay)
	_button(shortcuts, "Log", log_toggled)
	_button(shortcuts, "Sheet", sheet_toggled)
	explain_button = _button(shortcuts, "Explain", explain_cycled)
	_button(shortcuts, "Map View", top_down_toggled)
	cinematic_button = _button(shortcuts, "Cine: Off", cinematic_toggled)
	for b: Button in shortcuts.get_children():
		b.custom_minimum_size = Vector2(120, 54)
		b.add_theme_font_size_override("font_size", 20)
	info = _label(col)
	var middle := _row(col)
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var left := VBoxContainer.new()
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.add_child(left)
	tip = _label(left, 20)
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
	move_bar.add_child(more_button)
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
	_button(move_bar, "Cancel", cancel)
	_button(move_bar, "Confirm", confirm)
	refresh_move_actions()
	attack_bar = _bar(col)
	twist_buttons = [_button(attack_bar, "◀ Twist", twist_left), _button(attack_bar, "Twist ▶", twist_right)]
	flip_button = _button(attack_bar, "Flip arms", flip_arms)
	flip_button.visible = false
	skip_button = _button(attack_bar, "Hold Fire", attack_skip)
	attack_button = _button(attack_bar, "Fire", attack_confirm)
	show_move_controls(false)
	show_attack_controls(false)
	pause_menu = BattlePauseMenu.new()
	pause_menu.visible = false
	add_child(pause_menu)
	pause_menu.resumed.connect(func(): pause_toggled.emit())
	pause_menu.save_requested.connect(func(): save_battle.emit())
	pause_menu.exit_requested.connect(func(): exit_battle.emit())


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
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		pause_toggled.emit()


func _build_side_panel(parent: Control) -> void:
	side_panel = PanelContainer.new()
	side_panel.custom_minimum_size = Vector2(470, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.08, 0.86)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(10)
	side_panel.add_theme_stylebox_override("panel", style)
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
	game_over_detail = _label(game_over_box, FONT_SIZE)
	game_over_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	game_over_detail.custom_minimum_size.x = 760  # training debriefs run long
	_button(game_over_box, "Analyze Battle", battle_forensics)
	_button(game_over_box, "New Battle", new_battle)


## Replaces the side panel's content (record sheet, weapon list...).
func show_side(content: Control) -> void:
	for c in side_box.get_children():
		c.queue_free()
	if content:
		side_box.add_child(content)
	side_panel.visible = content != null


func set_status(text: String) -> void:
	status.text = text


func set_info(text: String) -> void:
	info.text = text


func set_tip(text: String) -> void:
	tip.text = text


func set_mode_label(text: String) -> void:
	mode_button.text = text


func set_cinematic_label(enabled: bool) -> void:
	cinematic_button.text = "Cine: On" if enabled else "Cine: Off"


func set_explain_label(level: int) -> void:
	explain_button.text = "Explain: " + ExplainLevel.name_of(level)


func show_move_controls(visible_: bool) -> void:
	move_bar.visible = visible_


func show_attack_controls(visible_: bool, fire_text: String = "Fire", skip_text: String = "Hold Fire") -> void:
	attack_bar.visible = visible_
	for b in twist_buttons:
		b.visible = fire_text == "Fire"
	attack_button.text = fire_text
	skip_button.text = skip_text


func show_game_over(text: String, detail: String = "") -> void:
	game_over_label.text = text
	game_over_detail.text = detail
	game_over_detail.visible = detail != ""
	game_over_box.visible = true
	show_move_controls(false)
	show_attack_controls(false)


func _row(parent: Control) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r


func _bar(parent: Control) -> HBoxContainer:
	var bar := _row(parent)
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 12)
	return bar


func _label(parent: Control, size: int = FONT_SIZE) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _button(parent: Control, text: String, sig: Signal) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = BUTTON_SIZE
	b.add_theme_font_size_override("font_size", FONT_SIZE)
	b.pressed.connect(func(): sig.emit())
	parent.add_child(b)
	return b

