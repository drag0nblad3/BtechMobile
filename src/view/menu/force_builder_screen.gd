class_name ForceBuilderScreen
extends Control
## Pick a map, a Battle Value budget and up to four 'Mechs per side, then start.
## Both sides are played on this device (hot seat) for now.

var db: UnitDb
var builder: ForceBuilder
var maps: PackedStringArray
var map_index := 0
var _rosters: Array[VBoxContainer] = []
var _totals: Array[Label] = []
var _status: Label
var _info: Label
var catalog: ForceCatalog
var bot_sides := [1]


func _ready() -> void:
	GameSettings.load_settings()
	db = UnitDb.load_dir()
	builder = ForceBuilder.new(db)
	maps = JsonFile.list_dir("res://data/maps")
	set_anchors_preset(PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.11, 0.12, 0.13)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 16)
	margin.add_child(cols)
	catalog = ForceCatalog.new(db, _on_add)
	catalog.build(cols)
	for side in 2:
		_build_roster(cols, side)
	_build_options(cols)
	_refresh()


func _build_roster(parent: Control, side: int) -> void:
	var box := UiKit.panel(parent)
	box.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiKit.label(box, "%s force" % Names.side(side)).modulate = PlaceholderMech.SIDE_COLORS[side].lightened(0.3)
	_totals.append(UiKit.label(box, "", UiKit.SMALL))
	var r := VBoxContainer.new()
	box.add_child(r)
	_rosters.append(r)


func _build_options(parent: Control) -> void:
	var scroll := ScrollContainer.new()  # the options outgrow a landscape phone screen
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	var box := UiKit.panel(scroll)
	box.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info = UiKit.label(box, "", UiKit.SMALL)
	var row1 := HBoxContainer.new()
	box.add_child(row1)
	UiKit.button(row1, "Map", func(): map_index = (map_index + 1) % maps.size(); _refresh(), Vector2(100, 60))
	UiKit.button(row1, "Budget", _next_budget, Vector2(100, 60))
	var row2 := HBoxContainer.new()
	box.add_child(row2)
	for side in 2:
		UiKit.button(row2, Names.side(side) + " player", func():
				if bot_sides.has(side): bot_sides.erase(side)
				else: bot_sides.append(side)
				_refresh(), Vector2(100, 60))
	var row3 := HBoxContainer.new()
	box.add_child(row3)
	for side in 2:
		UiKit.button(row3, Names.side(side) + " skill", _on_skill.bind(side), Vector2(100, 60))
	var row4 := HBoxContainer.new()
	box.add_child(row4)
	UiKit.button(row4, "Mission", func(): builder.next_mission(); _refresh(), Vector2(100, 60))
	UiKit.button(row4, "Withdrawal", func(): builder.forced_withdrawal = not builder.forced_withdrawal; _refresh(), Vector2(100, 60))
	UiKit.button(row4, "Hidden", func(): builder.hidden_side = (builder.hidden_side + 2) % 3 - 1; _refresh(), Vector2(100, 60))
	UiKit.button(box, "Conditions", func(): builder.next_conditions(); _refresh(), Vector2(0, 60))
	UiKit.button(box, "Initiative Die", func():
			builder.initiative_die = not builder.initiative_die; _refresh(), Vector2(0, 60))
	UiKit.button(box, "Explanations", func():
			GameSettings.set_explain_level(ExplainLevel.next(GameSettings.explain_level)); _refresh(), Vector2(0, 60))
	_status = UiKit.label(box, "", UiKit.SMALL)
	UiKit.button(box, "Start battle", _start, Vector2(0, 80))
	UiKit.button(box, "Training: first battle", _start_training, Vector2(0, 64))


func _next_budget() -> void:
	var i := ForceBuilder.BUDGETS.find(builder.budget)
	builder.budget = ForceBuilder.BUDGETS[(i + 1) % ForceBuilder.BUDGETS.size()]
	_refresh()


func _on_skill(side: int) -> void:
	var ok := builder.next_skill(side)
	_refresh()
	if not ok:
		_status.text = "That skill would put %s over budget" % Names.side(side)


func _on_add(side: int, def_id: String) -> void:
	var why := builder.cant_add(side, def_id)
	if why != "":
		_status.text = why
		return
	builder.add(side, def_id)
	_refresh()


func _refresh() -> void:
	for side in 2:
		UiKit.clear(_rosters[side])
		_totals[side].text = "%s of %d/%d  ·  %d / %d BV  ·  %d tons  ·  %s" % [builder.formation(side),
				builder.rosters[side].size(), builder.max_units(side), builder.bv(side), builder.budget, builder.tons(side), BvSkill.preset_name(builder.skills[side].x, builder.skills[side].y)]
		var ids: Array = builder.rosters[side]
		for i in ids.size():
			UiKit.button(_rosters[side], "✕ " + db.get_def(ids[i]).display_name(),
					func(): builder.remove(side, i); _refresh())
	var map_name: String = JsonFile.read(maps[map_index]).get("name", "?")
	catalog.refresh()
	var weather := ", ".join(builder.conditions.names()) if not builder.conditions.is_clear() else "clear"
	_info.text = "Mission: %s\nForced Withdrawal: %s · Hidden units: %s\n" % [builder.mission_name(),
			"on" if builder.forced_withdrawal else "off", "off" if builder.hidden_side < 0 else Names.side(builder.hidden_side)]
	_info.text += "Map: %s\nBudget: %d BV per side\nConditions: %s\nExplanations: %s\nInitiative Die: %s\nRed: %s · Blue: %s" % [map_name,
			builder.budget, weather, ExplainLevel.name_of(GameSettings.explain_level), "on" if builder.initiative_die else "off",
			"Computer" if bot_sides.has(0) else "You", "Computer" if bot_sides.has(1) else "You"]
	if GameSettings.explain_level == ExplainLevel.FULL:
		_info.text += "\n" + BvText.WHAT_IS_BV
		_info.text += "\nSkill: better MechWarriors hit and keep their footing more often, and cost more BV (Veteran 3/4 is x%.2f, Elite 2/3 x%.2f, Green 5/6 x%.2f)." % [
				BvSkill.multiplier(3, 4), BvSkill.multiplier(2, 3), BvSkill.multiplier(5, 6)]
		_info.text += "\n" + ForceBuilder.FORMATION_TIP
		_info.text += "\nInitiative Die (optional): a side that keeps losing initiative gets +1 more on each roll until it wins."
		if builder.mission_id not in ["", "random"]:
			_info.text += "\n" + String(StandardMissions.info(builder.mission_id).get("summary", ""))
		elif builder.mission_id == "random":
			_info.text += "\nA standard mission is rolled when the battle starts, with its complications (one may add random weather)."
		_info.text += "\nHidden units (optional): one side starts hidden in woods, rough, buildings or deep water, waiting in ambush. Walking into or next to one reveals it, and it may fire point-blank."
		_info.text += "\nForced Withdrawal (optional): badly damaged 'Mechs must retreat to their home edge instead of fighting to the end."
		for line in ConditionsText.effects(builder.conditions):
			_info.text += "\n" + line
		_info.text += "\nTip: mix ranges. Long-range missiles want distance; brawlers want to close in."
	var balance := builder.balance_text()
	if balance != "" and GameSettings.explain_level != ExplainLevel.OFF:
		_info.text += "\n" + balance
	_status.text = "" if builder.ready_to_fight() else "Add at least one 'Mech to each side."


## Guided one-on-one against the computer, with lessons (see Tutorial).
func _start_training() -> void:
	var path := "res://data/scenarios/tutorial.json"
	BattleLaunch.pending = ScenarioLoader.load_file(path, TerrainDb.load_file(), db)
	BattleLaunch.bot_sides = JsonFile.read(path).get("bot_sides", [1])
	BattleLaunch.tutorial_path = path
	get_tree().change_scene_to_file(BattleLaunch.BATTLE_SCENE)


func _start() -> void:
	if not builder.ready_to_fight():
		return
	var map := MapLoader.load_file(maps[map_index], TerrainDb.load_file())
	BattleLaunch.pending = builder.build(map)
	BattleLaunch.bot_sides = bot_sides.duplicate()
	get_tree().change_scene_to_file(BattleLaunch.BATTLE_SCENE)
