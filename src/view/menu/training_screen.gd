class_name TrainingScreen
extends Control
## The training campaign: its story, the cadet's record and the six
## connected lessons. Each mission opens after the one before it is played.

var campaign: TrainingCampaign
var db: UnitDb
var _list: VBoxContainer


func _ready() -> void:
	GameSettings.load_settings()
	campaign = TrainingCampaign.load_file()
	if db == null:
		db = UnitDb.load_dir()
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.1, 0.12)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	_list = UiKit.panel(scroll)
	_list.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_build()


func _build() -> void:
	UiKit.clear(_list)
	var p := GameSettings.training
	var head := HBoxContainer.new()
	_list.add_child(head)
	var title := UiKit.label(head, campaign.name, 32)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.modulate = Color(1.0, 0.85, 0.45)
	UiKit.button(head, "Back", queue_free, Vector2(140, 60))
	UiKit.label(_list, campaign.intro, UiKit.SMALL)
	var next := campaign.next_index(p)
	for i in campaign.missions.size():
		var m := campaign.missions[i]
		var open := campaign.unlocked(i, p)
		var won: bool = p.get(m["id"], {}).get("won", false)
		var mark := "✓ " if won else ("· " if p.has(m["id"]) else ("▶ " if open else ""))
		var b := UiKit.button(_list, "%s%s   —   %s%s" % [mark, m["title"], m["teaches"], "" if open else "  (locked)"],
				start.bind(i), Vector2(0, 64))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = not open
		if i == next and open:
			var lvl := int(JsonFile.read(campaign.scenario_path(i)).get("bot_level", -1))
			var vs := "  (computer: %s)" % BotSkill.name_of(lvl) if lvl >= 0 else ""
			UiKit.label(_list, m.get("briefing", "") + vs, UiKit.SMALL).modulate = Color(0.8, 0.85, 0.9)
	if campaign.finished(p):
		UiKit.label(_list, "Campaign complete. Replay any lesson whenever you like.", UiKit.SMALL)


func start(i: int) -> void:
	var path := campaign.scenario_path(i)
	BattleLaunch.pending = ScenarioLoader.load_file(path, TerrainDb.load_file(), db)
	BattleLaunch.bot_sides = JsonFile.read(path).get("bot_sides", [1])
	BattleLaunch.tutorial_path = path
	BattleLaunch.training_mission = i
	BattleLaunch.bot_level = int(JsonFile.read(path).get("bot_level", -1))
	get_tree().change_scene_to_file(BattleLaunch.BATTLE_SCENE)


## Saves a finished training mission's result and returns its debrief
## ("" when `index` is -1, i.e. not a training battle).
static func finish(index: int, s: GameState, bot_sides: Array, winner: int) -> String:
	if index < 0:
		return ""
	var player := 0 if not bot_sides.has(0) else 1
	var c := TrainingCampaign.load_file()
	var r := TrainingCampaign.result(s, player, winner)
	GameSettings.record_training(c.missions[index]["id"], r)
	return c.debrief(index, r["won"], GameSettings.training)
