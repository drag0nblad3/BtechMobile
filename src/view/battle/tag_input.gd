class_name TagInput
extends RefCounted
## The weapon panel's TAG button: designate the target before firing (Tag).


static func available(state: GameState, attacker: Unit, target: Unit) -> bool:
	return target != null and target.side != attacker.side and Tag.problem(state, attacker) == ""


## The panel with a TAG button on top.
static func wrap(panel: Control, ai: AttackInput) -> Control:
	var th := Tag.to_hit(ai.controller.state, ai.attacker, ai.target)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var b := Button.new()
	b.text = "TAG %s (%s)" % [Names.unit(ai.target), "%d+" % th.target() if th.possible() else "can't"]
	b.tooltip_text = "Designate it first: friendly missiles that can fire indirectly may then arc in at it. No damage, and you can still fire your weapons."
	b.disabled = not th.possible()
	b.custom_minimum_size = Vector2(0, 54)
	b.add_theme_font_size_override("font_size", 19)
	b.pressed.connect(func() -> void: _press(ai))
	box.add_child(b)
	box.add_child(panel)
	return box


static func _press(ai: AttackInput) -> void:
	var target := ai.target
	var ok := ai.controller.fire_tag(ai.attacker, target.id)
	AttackView.refresh(ai)
	if ok:
		ai.hud.set_tip("TAG %s: %s." % [Names.unit(target),
				"designated for indirect fire this turn" if Tag.designator(ai.controller.state, ai.attacker.side, target) == ai.attacker else "missed"])
