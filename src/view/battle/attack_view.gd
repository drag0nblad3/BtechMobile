class_name AttackView
extends RefCounted
## Shows AttackInput's current choice: highlighted hexes, the info line, the
## advice tip and the side panel of weapon or physical attack rows.


static func refresh(ai: AttackInput) -> void:
	if ai.attacker == null:
		return
	var level := GameSettings.explain_level
	var weapon := ai.is_weapon_phase()
	ai.hud.show_attack_controls(true, "Fire" if weapon else "Attack", "Hold Fire" if weapon else "Skip")
	if ai.attacker.def.quad or ai.attacker.arms_flipped:
		for b in ai.hud.twist_buttons:
			b.visible = false  # quads can't twist (p. 238); flipped arms rule it out
	ai.hud.flip_button.visible = weapon and ArmFlip.design_can(ai.attacker.def) and not ai.attacker.prone
	ai.hud.flip_button.text = "Arms forward" if ai.attacker.arms_flipped else "Flip arms"
	ai.hud.flip_button.disabled = not ai.attacker.arms_flipped and ArmFlip.problem(ai.attacker) != ""
	var hexes := {ai.attacker.coord: HexHighlighter.SELECTED}
	if ai.target:
		hexes[ai.target.coord] = Color(1, 0.2, 0.2, 0.55)
	if ai.target_hex != Hex.INVALID:
		hexes[ai.target_hex] = Color(1, 0.6, 0.2, 0.55)
	ai.highlighter.show_hexes(hexes)
	var twist: String = ["  (torso twisted left)", "", "  (torso twisted right)"][ai.attacker.torso_twist + 1]
	if ai.attacker.arms_flipped:
		twist = "  (arms flipped: arm weapons fire backwards)"
	if ai.target_hex != Hex.INVALID and not weapon:
		ai.hud.set_info("%s -> building %s" % [Names.unit(ai.attacker), Hex.label(ai.target_hex)])
		ai.hud.set_tip("Buildings can't dodge: punches, kicks and swings always hit them.")
		if not ai.hud.sheet_open:
			ai.hud.show_side(AttackPanel.build("Physical attack on building " + Hex.label(ai.target_hex),
				AttackRows.physical(ai.controller.state, ai.attacker, null, ai.target_hex), ai.physical, level, ai._toggle))
		return
	if ai.target_hex != Hex.INVALID:
		ai.hud.set_info("%s -> %s %s (%d hexes)%s" % [Names.unit(ai.attacker), _noun(ai), Hex.label(ai.target_hex),
				Hex.distance(ai.attacker.coord, ai.target_hex), twist])
		ai.hud.set_tip(Advisor.volley(ai.controller.state, ai.attacker, ai._shot_list(), level))
		if not ai.hud.sheet_open:
			ai.hud.show_side(AttackPanel.build("Weapons at %s %s" % [_noun(ai), Hex.label(ai.target_hex)],
				AttackRows.weapons(ai.controller.state, ai.attacker, options(ai), ai.shots, ai._here()), ai._selected_here(), level, ai._toggle, ai._mode))
		return
	if ai.target == null:
		ai.hud.set_info("%s: tap an enemy (or a building) to aim%s" % [Names.unit(ai.attacker), twist])
		var club := MeleeWeapons.club_here(ai.controller.state, ai.attacker)
		if weapon and club != "" and not ai.hud.sheet_open:
			var b := Button.new()
			b.text = "Pick up a %s as a club (instead of firing)" % club
			b.custom_minimum_size = Vector2(0, 58)
			b.add_theme_font_size_override("font_size", 20)
			b.pressed.connect(ai._pick_up_club)
			ai.hud.show_side(b)
		ai.hud.set_tip(Advisor.targets(ai.controller.state, ai.attacker, level) if weapon else "Tap an adjacent enemy to punch or kick it.")
		if not ai.hud.sheet_open:
			ai.hud.show_side(null)
		return
	ai.hud.set_info("%s -> %s (%d hexes)%s" % [Names.unit(ai.attacker), Names.unit(ai.target),
			Hex.distance(ai.attacker.coord, ai.target.coord), twist])
	if weapon:
		ai.hud.set_tip(Advisor.volley(ai.controller.state, ai.attacker, ai._shot_list(), level))
		if not ai.hud.sheet_open:
			var panel := AttackPanel.build("Weapons at " + Names.unit(ai.target),
				AttackRows.weapons(ai.controller.state, ai.attacker, options(ai), ai.shots, ai._here()), ai._selected_here(), level, ai._toggle, ai._mode)
			var side: Control = AimPicker.wrap(panel, ai.target, ai.aims.get(ai.target.id, -1), ai._next_aim) \
					if AimPicker.available(ai.attacker, ai.target) else panel
			ai.hud.show_side(TagInput.wrap(side, ai) if TagInput.available(ai.controller.state, ai.attacker, ai.target) else side)
	else:
		ai.hud.set_tip(Advisor.physical(ai.controller.state, ai.attacker, ai.target, level))
		if not ai.hud.sheet_open:
			ai.hud.show_side(AttackPanel.build("Physical attack on " + Names.unit(ai.target),
				AttackRows.physical(ai.controller.state, ai.attacker, ai.target), ai.physical, level, ai._toggle))


## What the tapped hex target is: "building" or the woods' name.
static func _noun(ai: AttackInput) -> String:
	return WoodsFire.noun(ai.controller.state.map.get_tile(ai.target_hex))


## Fire options against the current target (aims applied).
static func options(ai: AttackInput) -> Array:
	if ai.target_hex != Hex.INVALID:
		return BuildingFire.options(ai.controller.state, ai.attacker, ai.target_hex)
	var opts := FireOptions.for_target(ai.controller.state, ai.attacker, ai.target, secondary(ai, ai.target))
	AimPicker.apply(ai.controller.state, ai.target, opts, ai.aims.get(ai.target.id, -1))
	return opts


## Secondary if the rules would pick another primary once t is added.
static func secondary(ai: AttackInput, t: Unit) -> bool:
	var list := ai._shot_list()
	list.append({"weapon": -1, "target_id": t.id})
	return FireOptions.primary_target(ai.controller.state, ai.attacker, list) != t.id
