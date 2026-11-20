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
var _bv_labels: Array = []  ## [Label, UnitDef] per catalog entry.
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
	_build_catalog(cols)
	for side in 2:
		_build_roster(cols, side)
	_build_options(cols)
	_refresh()


func _build_catalog(parent: Control) -> void:
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_stretch_ratio = 2.0
	parent.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	UiKit.label(list, "'Mechs")
	for def in db.sorted_defs():
		var box := UiKit.panel(list)
		UiKit.label(box, "%s  ·  BV %d  ·  %d t %s  ·  %d/%d MP  ·  %d armor" % [def.display_name(),
				BattleValue.of(def), def.tonnage, def.weight_class(), def.walk_mp, def.run_mp(), def.total_armor()])
		UiKit.label(box, _weapons_line(def), UiKit.SMALL)
		var bv_line := BvText.line(def, GameSettings.explain_level)
		_bv_labels.append([UiKit.label(box, bv_line, UiKit.SMALL), def])
		if def.role != "":
			UiKit.label(box, def.role, UiKit.SMALL).modulate = Color(0.8, 0.85, 0.75)
		var row := HBoxContainer.new()
		box.add_child(row)
		for side in 2:
			UiKit.button(row, "+ " + Names.side(side), _on_add.bind(side, def.id), Vector2(140, 56))


func _weapons_line(def: UnitDef) -> String:
	var counts := {}
	for m in def.weapon_mounts:
		var n: String = m["weapon"].name
		counts[n] = counts.get(n, 0) + 1
	var parts: Array[String] = []
	for n: String in counts:
		parts.append(("%d× %s" % [counts[n], n]) if counts[n] > 1 else n)
	return ", ".join(parts) + "  ·  %d heat sinks" % def.heat_sinks


func _build_roster(parent: Control, side: int) -> void:
	var box := UiKit.panel(parent)
	box.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiKit.label(box, "%s force" % Names.side(side)).modulate = PlaceholderMech.SIDE_COLORS[side].lightened(0.3)
	_totals.append(UiKit.label(box, "", UiKit.SMALL))
	var r := VBoxContainer.new()
	box.add_child(r)
	_rosters.append(r)


func _build_options(parent: Control) -> void:
	var box := UiKit.panel(parent)
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
	UiKit.button(box, "Explanations", func():
			GameSettings.set_explain_level(ExplainLevel.next(GameSettings.explain_level)); _refresh(), Vector2(0, 60))
	_status = UiKit.label(box, "", UiKit.SMALL)
	UiKit.button(box, "Start battle", _start, Vector2(0, 80))
	UiKit.button(box, "Training: first battle", _start_training, Vector2(0, 64))


func _next_budget() -> void:
	var i := ForceBuilder.BUDGETS.find(builder.budget)
	builder.budget = ForceBuilder.BUDGETS[(i + 1) % ForceBuilder.BUDGETS.size()]
	_refresh()


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
		_totals[side].text = "%d / %d BV  ·  %d tons" % [builder.bv(side), builder.budget, builder.tons(side)]
		var ids: Array = builder.rosters[side]
		for i in ids.size():
			UiKit.button(_rosters[side], "✕ " + db.get_def(ids[i]).display_name(),
					func(): builder.remove(side, i); _refresh())
	var map_name: String = JsonFile.read(maps[map_index]).get("name", "?")
	for pair: Array in _bv_labels:
		pair[0].text = BvText.line(pair[1], GameSettings.explain_level)
		pair[0].visible = pair[0].text != ""
	_info.text = "Map: %s\nBudget: %d BV per side\nExplanations: %s\nRed: %s · Blue: %s" % [map_name,
			builder.budget, ExplainLevel.name_of(GameSettings.explain_level),
			"Computer" if bot_sides.has(0) else "You", "Computer" if bot_sides.has(1) else "You"]
	if GameSettings.explain_level == ExplainLevel.FULL:
		_info.text += "\n" + BvText.WHAT_IS_BV
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
