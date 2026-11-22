class_name ForceBuilderSetup
extends RefCounted
## Progressive disclosure for map, combatants and optional rules.

var builder: ForceBuilder
var map_picker: MapPicker
var bot_sides: Array
var _changed: Callable
var _message: Callable
var _options: Dictionary
var _budget_button: Button
var _mission_button: Button
var _players: Array[Button] = []
var _advanced: VBoxContainer
var _advanced_button: Button
var _info: Label


func build(parent: Control, b: ForceBuilder, picker: MapPicker,
		bots: Array, changed: Callable, message: Callable, options: Dictionary) -> void:
	builder = b
	map_picker = picker
	bot_sides = bots
	_changed = changed
	_message = message
	_options = options
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	var box := UiKit.panel(scroll)
	box.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiSkin.label(UiKit.label(box, "BATTLE SETUP", 21), "section")
	map_picker.build(box, changed)
	_budget_button = UiKit.button(box, "", _next_budget, Vector2(0, 52))
	_mission_button = UiKit.button(box, "", func():
		builder.next_mission()
		_changed.call(), Vector2(0, 52))
	var player_row := HBoxContainer.new()
	box.add_child(player_row)
	for side in 2:
		var idx := side
		var toggle := UiKit.button(player_row, "", func(): _toggle_player(idx),
			Vector2(0, 52))
		toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		toggle.add_theme_font_size_override("font_size", 18)
		_players.append(toggle)
	_advanced_button = UiKit.button(box, "ADVANCED OPTIONS  ▸", _toggle_advanced,
		Vector2(0, 52), "subtle")
	_advanced = VBoxContainer.new()
	_advanced.visible = false
	_advanced.add_theme_constant_override("separation", 7)
	box.add_child(_advanced)
	UiKit.button(_advanced, "Computer skill", func():
		GameSettings.set_ai_level(BotSkill.next(GameSettings.ai_level))
		_changed.call(), Vector2(0, 52))
	for side in 2:
		var idx := side
		UiKit.button(_advanced, Names.side(side) + " pilot skill", func():
			if not builder.next_skill(idx):
				_message.call("That pilot upgrade would exceed the BV limit.")
			_changed.call(), Vector2(0, 52))
	UiKit.button(_advanced, "Battle conditions", func():
		builder.next_conditions()
		_changed.call(), Vector2(0, 52))
	UiKit.button(_advanced, "Forced withdrawal", func():
		builder.forced_withdrawal = not builder.forced_withdrawal
		_changed.call(), Vector2(0, 52))
	UiKit.button(_advanced, "Hidden units", func():
		builder.hidden_side = (builder.hidden_side + 2) % 3 - 1
		_changed.call(), Vector2(0, 52))
	UiKit.button(_advanced, "Initiative die", func():
		builder.initiative_die = not builder.initiative_die
		_changed.call(), Vector2(0, 52))
	UiKit.button(_advanced, "Explanations", func():
		GameSettings.set_explain_level(ExplainLevel.next(GameSettings.explain_level))
		_changed.call(), Vector2(0, 52))
	_info = UiKit.label(_advanced, "", 17)
	UiSkin.label(_info, "muted")
	UiSkin.rule(box, UiSkin.BORDER)
	if BattleSave.has_game():
		UiKit.button(box, "CONTINUE SAVED BATTLE", func():
			_options["continue"].call(), Vector2(0, 56), "selected")
	if BattleSave.has_replay():
		UiKit.button(box, "Watch last replay", func():
			_options["replay"].call(), Vector2(0, 52))
		UiKit.button(box, "Tactical Academy: Forensics", func():
			_options["forensics"].call(), Vector2(0, 52))
	UiKit.button(box, "Training campaign", func():
		_options["training"].call(), Vector2(0, 52))
	refresh()


func _next_budget() -> void:
	var i := ForceBuilder.BUDGETS.find(builder.budget)
	builder.budget = ForceBuilder.BUDGETS[(i + 1) % ForceBuilder.BUDGETS.size()]
	_changed.call()


func _toggle_player(side: int) -> void:
	if bot_sides.has(side):
		bot_sides.erase(side)
	else:
		bot_sides.append(side)
	_changed.call()


func _toggle_advanced() -> void:
	_advanced.visible = not _advanced.visible
	_advanced_button.text = "ADVANCED OPTIONS  ▾" if _advanced.visible else "ADVANCED OPTIONS  ▸"


func refresh() -> void:
	_budget_button.text = "BV LIMIT  •  %d per side  ▸" % builder.budget
	_mission_button.text = "MISSION  •  %s  ▸" % builder.mission_name()
	for side in 2:
		_players[side].text = "%s: %s" % [
			Names.side(side), "Computer" if bot_sides.has(side) else "Human"]
	var weather := ", ".join(builder.conditions.names()) if not builder.conditions.is_clear() else "Clear"
	_info.text = "AI: %s  •  Conditions: %s\nPilots: Red %s, Blue %s\nWithdrawal: %s  •  Hidden: %s\nInitiative die: %s  •  Explanations: %s" % [
		BotSkill.name_of(GameSettings.ai_level), weather,
		BvSkill.preset_name(builder.skills[0].x, builder.skills[0].y),
		BvSkill.preset_name(builder.skills[1].x, builder.skills[1].y),
		"On" if builder.forced_withdrawal else "Off",
		"Off" if builder.hidden_side < 0 else Names.side(builder.hidden_side),
		"On" if builder.initiative_die else "Off",
		ExplainLevel.name_of(GameSettings.explain_level)]
