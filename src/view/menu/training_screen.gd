class_name TrainingScreen
extends Control
## Six connected lessons with optional practice checks and retry records.
## Each mission opens after the previous one is played, even after a loss.

var campaign: TrainingCampaign
var db: UnitDb
var _list: VBoxContainer


func _ready() -> void:
	GameSettings.load_settings()
	campaign = TrainingCampaign.load_file()
	if db == null:
		db = UnitDb.load_dir()
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	UiSkin.backdrop(self)
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
	UiSkin.label(title, "heading")
	if not campaign.notebook(p).is_empty():
		UiKit.button(head, "Notebook", _show_notebook, Vector2(180, 60))
	UiKit.button(head, "Back", queue_free, Vector2(140, 60))
	UiSkin.rule(_list)
	UiKit.label(_list, campaign.intro, UiKit.SMALL)
	var next := campaign.next_index(p)
	for i in campaign.missions.size():
		var m := campaign.missions[i]
		var open := campaign.unlocked(i, p)
		var record: Dictionary = p.get(m["id"], {})
		var won: bool = record.get("won", false)
		var mark := "✓ " if won else ("· " if p.has(m["id"]) else ("▶ " if open else ""))
		var b := UiKit.button(_list, "%s%s   —   %s%s" % [mark, m["title"], m["teaches"], "" if open else "  (locked)"],
				start.bind(i), Vector2(0, 64))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = not open
		UiSkin.button(b, "selected" if won else "primary" if i == next and open else "secondary")
		if not record.is_empty():
			var best := int(record.get("practice", 0))
			var count := int(record.get("practice_total", m.get("practice", []).size()))
			var attempts := int(record.get("attempts", 1))
			UiKit.label(_list, "  %d attempts  ·  best practice %d/%d" % [attempts, best, count], UiKit.SMALL)
		if i == next and open:
			var lvl := int(JsonFile.read(campaign.scenario_path(i)).get("bot_level", -1))
			var vs := "  (computer: %s)" % BotSkill.name_of(lvl) if lvl >= 0 else ""
			var briefing := UiKit.label(_list, m.get("briefing", "") + vs, UiKit.SMALL)
			UiSkin.label(briefing, "muted")
			var checks := PackedStringArray()
			for goal: Dictionary in m.get("practice", []):
				checks.append(String(goal.get("title", "")))
			UiKit.label(_list, "Practice (optional): " + "  ·  ".join(checks), UiKit.SMALL)
	if campaign.finished(p):
		UiKit.label(_list, "All six missions attempted. Retry to improve your practice record or win the remaining battles.", UiKit.SMALL)


## Every lesson seen so far, to reread between games.
func _show_notebook() -> void:
	UiKit.clear(_list)
	var head := HBoxContainer.new()
	_list.add_child(head)
	var title := UiKit.label(head, "Rules notebook", 32)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.modulate = Color(1.0, 0.85, 0.45)
	UiKit.button(head, "Missions", _build, Vector2(180, 60))
	var last := ""
	for n in campaign.notebook(GameSettings.training):
		if n["mission"] != last:
			last = n["mission"]
			UiKit.label(_list, last, 26).modulate = Color(0.75, 0.85, 1.0)
		UiKit.label(_list, n["title"], UiKit.FONT).modulate = Color(1.0, 0.9, 0.6)
		UiKit.label(_list, n["text"], UiKit.SMALL)


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
static func finish(index: int, s: GameState, bot_sides: Array, winner: int,
		practice: TrainingPractice = null) -> String:
	if index < 0:
		return ""
	var player := 0 if not bot_sides.has(0) else 1
	var c := TrainingCampaign.load_file()
	var r := TrainingCampaign.result(s, player, winner)
	if practice == null:
		practice = TrainingPractice.from_mission(c.missions[index])
	r["practice"] = practice.completed_count()
	r["practice_total"] = practice.goals.size()
	GameSettings.record_training(c.missions[index]["id"], r)
	return c.debrief(index, r["won"], GameSettings.training) + "\n\n" + practice.summary()
