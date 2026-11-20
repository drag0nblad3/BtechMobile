class_name AttackInput
extends Node
## Weapon and physical attack phases: pick your 'Mech (the first one waiting
## is picked for you), tap an enemy, toggle weapons or punches/kicks in the
## side panel, then Fire / Attack or Hold Fire / Skip.
## The first enemy you assign weapons to is the primary target. In the weapon
## phase you may also tap a building to shoot it.

signal attacker_selected(u: Unit)

var controller: GameController
var hud: BattleHud
var highlighter: HexHighlighter
var bots: BotDriver

var attacker: Unit
var target: Unit
var target_hex := Hex.INVALID  ## Building being aimed at, if any.
var primary_id := -1
var shots := {}     ## Weapon phase: weapon index -> target id, or building hex (Vector2i).
var physical := {}  ## Physical phase: "kind:limb" -> true (current target only).


func active() -> bool:
	var p := controller.state.phase
	if bots and bots.is_bot_turn():
		return false
	return not controller.state.game_over and (p == Phase.Kind.WEAPON_ATTACK or p == Phase.Kind.PHYSICAL_ATTACK)


func is_weapon_phase() -> bool:
	return controller.state.phase == Phase.Kind.WEAPON_ATTACK


## Called when a new unit is due to act.
func begin() -> void:
	if not active():
		return
	clear()
	var p := controller.pending_units()
	if not p.is_empty():
		_select(p[0])


func clear() -> void:
	attacker = null
	target = null
	target_hex = Hex.INVALID
	primary_id = -1
	shots.clear()
	physical.clear()
	hud.show_attack_controls(false)
	highlighter.clear()


func on_hex_tapped(c: Vector2i) -> bool:
	if not active():
		return false
	var u := controller.state.unit_at(c)
	if u == null:
		var tile := controller.state.map.get_tile(c)
		if attacker == null or not is_weapon_phase() or tile == null or tile.building == null:
			return false
		target = null
		target_hex = c
		_default_shots()
		_refresh()
		return true
	if controller.pending_units().has(u):
		_select(u)
	elif attacker and u.side != attacker.side:
		target = u
		target_hex = Hex.INVALID
		physical.clear()
		if is_weapon_phase():
			_default_shots()
	_refresh()
	return true


func on_confirm() -> void:
	if attacker == null:
		return
	var u := attacker
	if is_weapon_phase():
		var list := _shot_list()
		clear()
		controller.declare_fire(u, list)
	else:
		var list := []
		for k: String in physical:
			var parts := k.split(":")
			list.append({"kind": parts[0], "limb": int(parts[1]), "target_id": target.id})
		clear()
		controller.declare_physical(u, list)


func on_twist(dir: int) -> void:
	if attacker and is_weapon_phase():
		controller.set_torso_twist(attacker, clampi(attacker.torso_twist + dir, -1, 1))
		shots.clear()
		primary_id = -1
		if target or target_hex != Hex.INVALID:
			_default_shots()
		_refresh()


func on_skip() -> void:
	if attacker == null:
		return
	var u := attacker
	clear()
	if is_weapon_phase():
		controller.declare_fire(u, [])
	else:
		controller.declare_physical(u, [])


func _select(u: Unit) -> void:
	attacker = u
	target = null
	target_hex = Hex.INVALID
	primary_id = -1
	shots.clear()
	physical.clear()
	attacker_selected.emit(u)
	_refresh()


## Selects every possible weapon not already aimed elsewhere.
func _default_shots() -> void:
	for o in _options():
		if o["to_hit"].possible() and not shots.has(o["index"]):
			shots[o["index"]] = _here()
	if target and primary_id < 0 and _selected_here().size() > 0:
		primary_id = target.id


func _options() -> Array:
	if target_hex != Hex.INVALID:
		return BuildingFire.options(controller.state, attacker, target_hex)
	return FireOptions.for_target(controller.state, attacker, target, _secondary(target))


func _secondary(t: Unit) -> bool:
	return primary_id >= 0 and t.id != primary_id


func _toggle(key: Variant, on: bool) -> void:
	if is_weapon_phase():
		if on:
			shots[key] = _here()
			if primary_id < 0 and target:
				primary_id = target.id
		else:
			shots.erase(key)
			var ids := shots.values().filter(func(v: Variant) -> bool: return v is int)
			if not ids.has(primary_id):
				primary_id = ids[0] if not ids.is_empty() else -1
	else:
		if on:
			if String(key).begins_with("kick") or String(key).begins_with("push"):
				physical.clear()
			else:
				for k: String in physical.keys():
					if k.begins_with("kick") or k.begins_with("push"):
						physical.erase(k)
			physical[key] = true
		else:
			physical.erase(key)
	_refresh()


func _refresh() -> void:
	if attacker == null:
		return
	var level := GameSettings.explain_level
	var weapon := is_weapon_phase()
	hud.show_attack_controls(true, "Fire" if weapon else "Attack", "Hold Fire" if weapon else "Skip")
	var hexes := {attacker.coord: HexHighlighter.SELECTED}
	if target:
		hexes[target.coord] = Color(1, 0.2, 0.2, 0.55)
	if target_hex != Hex.INVALID:
		hexes[target_hex] = Color(1, 0.6, 0.2, 0.55)
	highlighter.show_hexes(hexes)
	var twist: String = ["  (torso twisted left)", "", "  (torso twisted right)"][attacker.torso_twist + 1]
	if target_hex != Hex.INVALID:
		hud.set_info("%s -> building %s (%d hexes)%s" % [Names.unit(attacker), Hex.label(target_hex),
				Hex.distance(attacker.coord, target_hex), twist])
		hud.set_tip(Advisor.volley(controller.state, attacker, _shot_list(), level))
		if not hud.sheet_open:
			hud.show_side(AttackPanel.build("Weapons at building " + Hex.label(target_hex),
				AttackRows.weapons(controller.state, attacker, _options(), shots, _here()), _selected_here(), level, _toggle))
		return
	if target == null:
		hud.set_info("%s: tap an enemy (or a building) to aim%s" % [Names.unit(attacker), twist])
		hud.set_tip(Advisor.targets(controller.state, attacker, level) if weapon else "Tap an adjacent enemy to punch or kick it.")
		if not hud.sheet_open:
			hud.show_side(null)
		return
	hud.set_info("%s -> %s (%d hexes)%s" % [Names.unit(attacker), Names.unit(target),
			Hex.distance(attacker.coord, target.coord), twist])
	if weapon:
		hud.set_tip(Advisor.volley(controller.state, attacker, _shot_list(), level))
		if not hud.sheet_open:
			hud.show_side(AttackPanel.build("Weapons at " + Names.unit(target),
				AttackRows.weapons(controller.state, attacker, _options(), shots, _here()), _selected_here(), level, _toggle))
	else:
		hud.set_tip(Advisor.physical(controller.state, attacker, target, level))
		if not hud.sheet_open:
			hud.show_side(AttackPanel.build("Physical attack on " + Names.unit(target),
				AttackRows.physical(controller.state, attacker, target), physical, level, _toggle))


func _shot_list() -> Array:
	return AttackRows.shot_list(shots, primary_id)


func _selected_here() -> Dictionary:
	return AttackRows.selected(shots, _here())


## Current aim: the target 'Mech's id, or the building hex.
func _here() -> Variant:
	return target_hex if target_hex != Hex.INVALID else (target.id if target else -1)
