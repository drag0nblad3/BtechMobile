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
var _era: OptionButton
var _year: SpinBox
var _policy: OptionButton
var _factions: Array[OptionButton] = []
var _paint_swatches: Array[ColorRect] = []
var _mission_button: Button
var _players: Array[Button] = []
var _advanced: VBoxContainer
var _advanced_button: Button
var _info: Label
var _ai: Button
var _pilots: Array[Button] = []
var _conditions: Button
var _withdrawal: Button
var _hidden: Button
var _initiative: Button
var _formations: Button
var _explanations: Button


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
	# Map, budget, mission and players come first; history after them.
	var history := VBoxContainer.new()
	history.add_theme_constant_override("separation", 8)
	box.add_child(history)
	UiSkin.label(UiKit.label(history, "FACTIONS, PAINT & AVAILABILITY", 18), "section")
	var era_row := HBoxContainer.new()
	history.add_child(era_row)
	_era = OptionButton.new()
	_era.fit_to_longest_item = false
	_era.clip_text = true
	_era.custom_minimum_size.y = 50
	_era.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_era.add_theme_font_size_override("font_size", 17)
	for era: Dictionary in EraAvailability.ERAS:
		_era.add_item("%s (%d-%d)" % [era["name"], era["start"], era["end"]])
	era_row.add_child(_era)
	_era.item_selected.connect(func(index: int):
		builder.era_year = int(EraAvailability.ERAS[index]["start"])
		_changed.call())
	_year = SpinBox.new()
	_year.min_value = 2398
	_year.max_value = 3153
	_year.step = 1
	_year.custom_minimum_size = Vector2(115, 50)
	_year.tooltip_text = "Exact historical year, including the middle of an era."
	era_row.add_child(_year)
	_year.value_changed.connect(func(value: float):
		builder.era_year = int(value)
		_changed.call())
	_policy = OptionButton.new()
	_policy.fit_to_longest_item = false
	_policy.clip_text = true
	_policy.custom_minimum_size.y = 50
	_policy.add_theme_font_size_override("font_size", 18)
	for mode_name: String in EraAvailability.MODE_NAMES:
		_policy.add_item("RESTRICTIONS: " + mode_name)
	history.add_child(_policy)
	_policy.item_selected.connect(func(index: int):
		builder.availability_mode = index
		_changed.call())
	for side in 2:
		var idx := side
		var faction_row := HBoxContainer.new()
		history.add_child(faction_row)
		var faction_label := UiKit.label(faction_row, Names.side(side).to_upper() + " FACTION", 16)
		faction_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		UiSkin.label(faction_label, "section")
		var picker_for_faction := OptionButton.new()
		picker_for_faction.fit_to_longest_item = false
		picker_for_faction.clip_text = true
		picker_for_faction.custom_minimum_size.y = 50
		picker_for_faction.tooltip_text = "Also paints this side's voxel 'Mechs and adds a stylized armor insignia. Historical restrictions are optional."
		picker_for_faction.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		picker_for_faction.add_theme_font_size_override("font_size", 17)
		for faction: Dictionary in EraAvailability.FACTIONS:
			picker_for_faction.add_item(String(faction["name"]))
		faction_row.add_child(picker_for_faction)
		_factions.append(picker_for_faction)
		for color_index in 2:
			var swatch := ColorRect.new()
			swatch.custom_minimum_size = Vector2(21, 32)
			swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
			faction_row.add_child(swatch)
			_paint_swatches.append(swatch)
		picker_for_faction.item_selected.connect(func(index: int):
			builder.factions[idx] = String(EraAvailability.FACTIONS[index]["id"])
			GameSettings.set_paint_faction(idx, builder.factions[idx])
			_changed.call())
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
	box.move_child(history, player_row.get_index())
	_advanced_button = UiKit.button(box, "ADVANCED OPTIONS  ▸", _toggle_advanced,
		Vector2(0, 52), "subtle")
	_advanced = VBoxContainer.new()
	_advanced.visible = false
	_advanced.add_theme_constant_override("separation", 7)
	box.add_child(_advanced)
	_ai = UiKit.button(_advanced, "Computer skill", func():
		GameSettings.set_ai_level(BotSkill.next(GameSettings.ai_level))
		_changed.call(), Vector2(0, 52))
	for side in 2:
		var idx := side
		_pilots.append(UiKit.button(_advanced, Names.side(side) + " pilot skill", func():
			if not builder.next_skill(idx):
				_message.call("That pilot upgrade would exceed the BV limit.")
			_changed.call(), Vector2(0, 52)))
	_conditions = UiKit.button(_advanced, "Battle conditions", func():
		builder.next_conditions()
		_changed.call(), Vector2(0, 52))
	_withdrawal = UiKit.button(_advanced, "Forced withdrawal", func():
		builder.forced_withdrawal = not builder.forced_withdrawal
		_changed.call(), Vector2(0, 52))
	_hidden = UiKit.button(_advanced, "Hidden units", func():
		builder.hidden_side = (builder.hidden_side + 2) % 3 - 1
		_changed.call(), Vector2(0, 52))
	_initiative = UiKit.button(_advanced, "Initiative die", func():
		builder.initiative_die = not builder.initiative_die
		_changed.call(), Vector2(0, 52))
	_formations = UiKit.button(_advanced, "Formations", func():
		builder.formations = not builder.formations
		_changed.call(), Vector2(0, 52))
	_explanations = UiKit.button(_advanced, "Explanations", func():
		GameSettings.set_explain_level(ExplainLevel.next(GameSettings.explain_level))
		_changed.call(), Vector2(0, 52))
	_info = UiKit.label(_advanced, "", 17)
	UiSkin.label(_info, "muted")
	UiSkin.rule(box, UiSkin.BORDER)
	if _options.get("has_saved_battle", false):
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
	_era.select(EraAvailability.era_index(builder.era_year))
	_era.tooltip_text = _era.get_item_text(_era.selected)
	_year.set_value_no_signal(builder.era_year)
	_policy.select(builder.availability_mode)
	_policy.tooltip_text = _policy.get_item_text(_policy.selected)
	for side in 2:
		var paint := VxLivery.scheme(builder.factions[side])
		_paint_swatches[side * 2].color = Color(String(paint["primary"]))
		_paint_swatches[side * 2 + 1].color = Color(String(paint["secondary"]))
		for i in EraAvailability.FACTIONS.size():
			if EraAvailability.FACTIONS[i]["id"] == builder.factions[side]:
				_factions[side].select(i)
				_factions[side].tooltip_text = String(EraAvailability.FACTIONS[i]["name"]) + " — also sets this side's paint and insignia."
				break
	_budget_button.text = "BV LIMIT  •  %d per side  ▸" % builder.budget
	_mission_button.text = "MISSION  •  %s  ▸" % builder.mission_name()
	_mission_button.clip_text = true
	_mission_button.tooltip_text = builder.mission_name()
	_ai.text = "COMPUTER SKILL  •  %s" % BotSkill.name_of(GameSettings.ai_level)
	for side in 2:
		_pilots[side].text = "%s PILOT SKILL  •  %s" % [
			Names.side(side).to_upper(),
			BvSkill.preset_name(builder.skills[side].x, builder.skills[side].y)]
	_conditions.text = "CONDITIONS  •  %s" % (
		", ".join(builder.conditions.names()) if not builder.conditions.is_clear() else "Clear")
	_withdrawal.text = "FORCED WITHDRAWAL  •  %s" % ("On" if builder.forced_withdrawal else "Off")
	_hidden.text = "HIDDEN UNITS  •  %s" % (
		"Off" if builder.hidden_side < 0 else Names.side(builder.hidden_side))
	_initiative.text = "INITIATIVE DIE  •  %s" % ("On" if builder.initiative_die else "Off")
	_formations.text = "FORMATION BONUSES  •  %s" % ("On" if builder.formations else "Off")
	_explanations.text = "EXPLANATIONS  •  %s" % ExplainLevel.name_of(GameSettings.explain_level)
	for side in 2:
		_players[side].text = "%s: %s" % [
			Names.side(side), "Computer" if bot_sides.has(side) else "Human"]
	var weather := ", ".join(builder.conditions.names()) if not builder.conditions.is_clear() else "Clear"
	_info.text = "AI: %s  •  Conditions: %s\nPilots: Red %s, Blue %s\nWithdrawal: %s  •  Hidden: %s\nInitiative die: %s  •  Formations: %s  •  Explanations: %s" % [
		BotSkill.name_of(GameSettings.ai_level), weather,
		BvSkill.preset_name(builder.skills[0].x, builder.skills[0].y),
		BvSkill.preset_name(builder.skills[1].x, builder.skills[1].y),
		"On" if builder.forced_withdrawal else "Off",
		"Off" if builder.hidden_side < 0 else Names.side(builder.hidden_side),
		"On" if builder.initiative_die else "Off",
		"On" if builder.formations else "Off",
		ExplainLevel.name_of(GameSettings.explain_level)]
