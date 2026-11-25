class_name DrillScreen
extends Control
## Rules drills: one multiple-choice question at a time from RulesDrill, with
## the answer explained. Topic chips narrow the questions; score and streak
## are for this visit only.

const LAUNCHER := "res://scenes/launcher.tscn"
const TOPICS := [["All", ""], ["To-hit", "to_hit"], ["Hit location", "location"],
		["Missiles", "cluster"], ["Heat", "heat"], ["2d6 odds", "odds"]]

var _rng := RandomNumberGenerator.new()
var _db: UnitDb
var _terrain: TerrainDb
var _topic := ""
var _q: Dictionary = {}
var _answered := false
var _right := 0
var _asked := 0
var _streak := 0
var _prompt: Label
var _feedback: Label
var _score: Label
var _choices: GridContainer
var _next: Button
var _chips: Array[Button] = []


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_leave()


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_leave()


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	UiSkin.backdrop(self)
	_rng.randomize()
	_db = UnitDb.load_dir()
	_terrain = TerrainDb.load_file()
	var scroll := UiKit.landscape_scroll(self)
	var box := UiKit.panel(scroll)
	box.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	var head := HBoxContainer.new()
	box.add_child(head)
	var title := UiKit.label(head, "RULES DRILLS", 32)
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	_score = UiKit.label(head, "", UiKit.SMALL)
	for l: Label in [title, _score]:
		l.autowrap_mode = TextServer.AUTOWRAP_OFF  # wrapping labels collapse inside an HBox
	_score.size_flags_vertical = SIZE_SHRINK_CENTER
	UiKit.button(head, "MENU", _leave, Vector2(130, 52), "subtle")
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 6)
	box.add_child(chips)
	for t: Array in TOPICS:
		var c := UiKit.button(chips, t[0], _pick_topic.bind(t[1]), Vector2(0, 46), "subtle")
		c.add_theme_font_size_override("font_size", 18)
		c.size_flags_horizontal = SIZE_EXPAND_FILL
		_chips.append(c)
	UiSkin.rule(box)
	_prompt = UiKit.label(box, "", 24)
	_prompt.custom_minimum_size.y = 70
	_choices = GridContainer.new()
	_choices.columns = 2
	_choices.add_theme_constant_override("h_separation", 8)
	_choices.add_theme_constant_override("v_separation", 8)
	box.add_child(_choices)
	_feedback = UiKit.label(box, "", UiKit.SMALL)
	_feedback.custom_minimum_size.y = 56
	_next = UiKit.button(box, "NEXT QUESTION", _ask, Vector2(0, 60), "primary")
	_pick_topic("")


func _pick_topic(kind: String) -> void:
	_topic = kind
	for i in _chips.size():
		UiSkin.button(_chips[i], "primary" if TOPICS[i][1] == kind else "subtle")
	_ask()


func _ask() -> void:
	_q = RulesDrill.make(_rng, _db, _terrain, _topic)
	_answered = false
	_prompt.text = _q["prompt"]
	_feedback.text = "Pick an answer."
	UiKit.clear(_choices)
	for i in _q["choices"].size():
		var b := UiKit.button(_choices, _q["choices"][i], _answer.bind(i), Vector2(0, 54))
		b.name = "Choice%d" % i
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_next.disabled = true
	_show_score()


func _answer(i: int) -> void:
	if _answered:
		return
	_answered = true
	_asked += 1
	var ok := i == int(_q["answer"])
	_right += 1 if ok else 0
	_streak = _streak + 1 if ok else 0
	var buttons := _choices.get_children()
	for j in buttons.size():
		var tone := "primary" if j == int(_q["answer"]) else "danger" if j == i else "subtle"
		UiSkin.button(buttons[j] as Button, tone)
	_feedback.text = ("Right. " if ok else "Not quite: it's %s. " % _q["choices"][int(_q["answer"])]) + String(_q["explain"])
	_next.disabled = false
	_show_score()


func _show_score() -> void:
	_score.text = "%d / %d right  ·  streak %d" % [_right, _asked, _streak]


func _leave() -> void:
	get_tree().change_scene_to_file(LAUNCHER)
