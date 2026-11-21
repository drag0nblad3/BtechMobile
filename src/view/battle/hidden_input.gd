class_name HiddenInput
extends Node
## Buttons for a human side's hidden units: reveal one at the start of a
## Movement or Weapon Attack Phase, and answer a point-blank chance when an
## enemy stumbles onto one. Calls the controller only.

var controller: GameController
var hud: BattleHud
var bots: BotDriver
var _box: VBoxContainer


func _ready() -> void:
	_box = VBoxContainer.new()
	_box.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_box.position = Vector2(-300, -120)
	_box.add_theme_constant_override("separation", 8)
	hud.add_child(_box)
	controller.event.connect(func(_e: GameEvent): refresh.call_deferred())
	refresh()


func refresh() -> void:
	for c in _box.get_children():
		c.queue_free()
	var s := controller.state
	if s.game_over:
		return
	if not s.point_blank.is_empty():
		var h := s.unit_by_id(int(s.point_blank[0]["unit_id"]))
		var t := s.unit_by_id(int(s.point_blank[0]["target_id"]))
		if h and t and not bots.bot_sides.has(h.side):
			_point_blank(h, t)
		return
	for h in s.hidden:
		if not bots.bot_sides.has(h.side) and HiddenUnits.may_reveal(s, h):
			_add("Reveal %s" % h.def.display_name(), func(): controller.reveal(h))


func _point_blank(h: Unit, t: Unit) -> void:
	var p := PointBlank.plan(controller.state, h, t)
	var cool := PointBlank.plan(controller.state, h, t, true)
	var tip := "%s found your hidden %s. Fire point-blank? It uses up %s's whole turn." % [
			t.def.display_name(), h.def.display_name(), h.def.display_name()]
	if GameSettings.explain_level == ExplainLevel.FULL:
		tip += " The shots count as 1 hex away and ignore the target's movement."
	hud.set_tip(tip)
	_add("Fire all (%d weapons, ~%.1f dmg)" % [p["shots"].size(), p["expected"]],
			func(): controller.point_blank(h, p["shots"], p["twist"]))
	if cool["shots"].size() < p["shots"].size() and not cool["shots"].is_empty():
		_add("Fire, stay cool (%d weapons)" % cool["shots"].size(),
				func(): controller.point_blank(h, cool["shots"], cool["twist"]))
	_add("Let it pass", func(): controller.point_blank(h, []))


func _add(text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(280, 64)
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(cb)
	_box.add_child(b)
