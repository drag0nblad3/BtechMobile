class_name ForceBuilderScreen
extends Control
## Search, fill two forces, check BV, then start. Core rules are unchanged.

var db: UnitDb
var builder: ForceBuilder
var map_picker := MapPicker.new()
var catalog: ForceCatalog
var bot_sides := [1]
var _rosters: Array[ForceRosterPanel] = []
var _side_buttons: Array[Button] = []
var _active_side := 0
var _status: Label
var _feedback: Label
var _start_button: Button
var _setup: ForceBuilderSetup
var _starter_confirm: ConfirmationDialog
var _pending_starter: Dictionary = {}
var _pending_side := -1


## Android Back returns to the launcher without exiting the app.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_tree().change_scene_to_file("res://scenes/launcher.tscn")


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			get_tree().change_scene_to_file("res://scenes/launcher.tscn")


func _ready() -> void:
	GameSettings.load_settings()
	db = UnitDb.load_dir()
	builder = ForceBuilder.new(db)
	set_anchors_preset(PRESET_FULL_RECT)
	UiSkin.backdrop(self)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)
	var heading := HBoxContainer.new()
	layout.add_child(heading)
	var title := UiKit.label(heading, "FORCE BUILDER  /  SKIRMISH", 27)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiSkin.label(title, "heading")
	var steps := UiKit.label(heading, "SEARCH → ADD → DEPLOY", 16)
	steps.autowrap_mode = TextServer.AUTOWRAP_OFF
	UiSkin.label(steps, "section")
	UiSkin.rule(layout)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	layout.add_child(body)
	catalog = ForceCatalog.new(db, _on_add, builder)
	catalog.build(body)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 1.0
	right.add_theme_constant_override("separation", 8)
	body.add_child(right)
	var side_row := HBoxContainer.new()
	right.add_child(side_row)
	var add_to := UiKit.label(side_row, "ADD TO:", 18)
	add_to.autowrap_mode = TextServer.AUTOWRAP_OFF
	UiSkin.label(add_to, "section")
	for side in 2:
		var idx := side
		var choose := UiKit.button(side_row, "", func(): _select_side(idx),
			Vector2(150, 52))
		choose.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choose.add_theme_font_size_override("font_size", 19)
		_side_buttons.append(choose)
	var roster_row := HBoxContainer.new()
	roster_row.custom_minimum_size.y = 180
	roster_row.add_theme_constant_override("separation", 8)
	right.add_child(roster_row)
	for side in 2:
		var idx := side
		var roster := ForceRosterPanel.new()
		roster.build(roster_row, idx, func(): _select_side(idx), _on_remove,
			_choose_starter)
		_rosters.append(roster)
	_feedback = UiKit.label(right, "", 18)
	UiSkin.label(_feedback, "section")
	_setup = ForceBuilderSetup.new()
	_setup.build(right, builder, map_picker, bot_sides, _refresh, _notify,
		{"continue": _continue_saved, "replay": _watch_saved_replay,
		"forensics": _open_forensics, "training": open_training})
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 14)
	layout.add_child(footer)
	_status = UiKit.label(footer, "", 21)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiSkin.label(_status, "body")
	_start_button = UiKit.button(footer, "START BATTLE", _start,
		Vector2(275, 68), "primary")
	_start_button.name = "StartBattle"
	_starter_confirm = ConfirmationDialog.new()
	_starter_confirm.title = "Replace selected force?"
	_starter_confirm.ok_button_text = "LOAD FORMATION"
	_starter_confirm.cancel_button_text = "KEEP FORCE"
	add_child(_starter_confirm)
	_starter_confirm.confirmed.connect(_apply_pending_starter)
	UiSkin.button(_starter_confirm.get_ok_button(), "primary")
	UiSkin.button(_starter_confirm.get_cancel_button(), "subtle")
	_refresh()
	if BattleLaunch.open_training:
		BattleLaunch.open_training = false
		open_training.call_deferred()


func _select_side(side: int) -> void:
	_active_side = side
	_feedback.text = ""
	catalog.set_active_side(side)
	_refresh()


func _notify(message: String) -> void:
	_feedback.text = message


## A template changes only the selected roster. Confirm replacements and budget raises.
func _choose_starter(side: int, index: int) -> void:
	var forms := StarterFormations.all()
	if index < 0 or index >= forms.size():
		return
	_select_side(side)
	var form: Dictionary = forms[index]
	var plan := StarterFormations.plan(builder, side, form)
	if not plan.get("ok", false):
		_notify(String(plan.get("reason", "Formation not available.")))
		return
	_pending_side = side
	_pending_starter = form
	if not builder.rosters[side].is_empty() or plan["raises_budget"]:
		var msg := "%s: %s\n\nReplace %s's current roster with %d 'Mechs?" % [
			form["name"], form["description"], Names.side(side),
			(form["units"] as Array).size()]
		msg += "\n\nTotal BV at this side's pilot skill: %d." % int(plan["cost"])
		if plan["raises_budget"]:
			msg += "\nThis will raise the BV limit for BOTH sides from %d to %d." % [
				builder.budget, int(plan["budget"])]
		_starter_confirm.dialog_text = msg
		_starter_confirm.popup_centered(Vector2i(575, 0))
	else:
		_apply_pending_starter()


func _apply_pending_starter() -> void:
	if _pending_side < 0 or _pending_starter.is_empty():
		return
	var side := _pending_side
	var name := String(_pending_starter["name"])
	var before := builder.budget
	var result := StarterFormations.apply(builder, side, _pending_starter)
	_pending_side = -1
	_pending_starter = {}
	if not result.get("ok", false):
		_notify(String(result.get("reason", "Unable to load formation.")))
		return
	var message := "%s loaded for %s (%d BV)." % [
		name, Names.side(side), int(result["cost"])]
	if builder.budget > before:
		message += " BV limit raised to %d for both sides." % builder.budget
	_notify(message)
	_refresh()


func _on_remove(side: int, index: int) -> void:
	builder.remove(side, index)
	_notify("Removed a unit from %s." % Names.side(side))
	_refresh()


func _on_add(side: int, def_id: String) -> void:
	var reason := builder.cant_add(side, def_id)
	if reason != "":
		_notify(reason)
		return
	builder.add(side, def_id)
	var message := "%s added to %s." % [db.get_def(def_id).display_name(), Names.side(side)]
	if builder.availability_mode == EraAvailability.Mode.ADVISORY:
		var report := builder.availability_for(side, def_id)
		if report["status"] != "available":
			message += " Historical note: " + String(report["reason"])
	_notify(message)
	_refresh()


func _refresh() -> void:
	for side in 2:
		_rosters[side].refresh(builder, db, side == _active_side)
		_side_buttons[side].text = Names.side(side).to_upper()
		UiSkin.button(_side_buttons[side], "selected" if side == _active_side else "subtle")
	catalog.refresh()
	_setup.refresh()
	var red := builder.bv(0)
	var blue := builder.bv(1)
	var within := red <= builder.budget and blue <= builder.budget
	var ready := builder.ready_to_fight() and within
	_start_button.disabled = not ready
	var historical_issue := builder.first_restriction_issue()
	if builder.availability_mode == EraAvailability.Mode.STRICT and historical_issue != "":
		_status.text = "Historical restriction: " + historical_issue
	elif not builder.ready_to_fight():
		_status.text = "Add at least one unit to each force to begin."
	elif not within:
		_status.text = "A force is over budget. Increase the limit or remove a unit."
	else:
		_status.text = builder.balance_text() + "  Ready to deploy."


func _continue_saved() -> void:
	BattleLaunch.load_autosave = true
	get_tree().change_scene_to_file(BattleLaunch.BATTLE_SCENE)


func _watch_saved_replay() -> void:
	get_tree().change_scene_to_file("res://scenes/battle_replay.tscn")


func _open_forensics() -> void:
	get_tree().change_scene_to_file("res://scenes/battle_forensics.tscn")




## The connected training games with lessons (see TrainingCampaign).
func open_training() -> void:
	var t := TrainingScreen.new()
	t.db = db
	add_child(t)


func _start() -> void:
	if not builder.ready_to_fight() or builder.bv(0) > builder.budget or builder.bv(1) > builder.budget:
		return
	var map := map_picker.choice.build()
	BattleLaunch.pending = builder.build(map)
	BattleLaunch.bot_sides = bot_sides.duplicate()
	get_tree().change_scene_to_file(BattleLaunch.BATTLE_SCENE)
