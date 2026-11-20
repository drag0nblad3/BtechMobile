class_name AttackInput
extends Node
## Weapon and physical attack phases: pick your 'Mech (the first one waiting
## is picked for you), tap an enemy, toggle weapons or punches/kicks in the
## side panel, then Fire / Attack or Hold Fire / Skip.
## The first enemy you assign weapons to is the primary target.

signal attacker_selected(u: Unit)

var controller: GameController
var hud: BattleHud
var highlighter: HexHighlighter
var bots: BotDriver

var attacker: Unit
var target: Unit
var primary_id := -1
var shots := {}     ## Weapon phase: weapon index -> target id.
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
		return false
	if controller.pending_units().has(u):
		_select(u)
	elif attacker and u.side != attacker.side:
		target = u
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
		var list := []
		for wi: int in shots:  # primary target's shots first
			if shots[wi] == primary_id:
				list.append({"weapon": wi, "target_id": shots[wi]})
		for wi: int in shots:
			if shots[wi] != primary_id:
				list.append({"weapon": wi, "target_id": shots[wi]})
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
		if target:
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
	primary_id = -1
	shots.clear()
	physical.clear()
	attacker_selected.emit(u)
	_refresh()


## Selects every possible weapon not already aimed elsewhere.
func _default_shots() -> void:
	for o in FireOptions.for_target(controller.state, attacker, target, _secondary(target)):
		if o["to_hit"].possible() and not shots.has(o["index"]):
			shots[o["index"]] = target.id
	if primary_id < 0 and shots.values().has(target.id):
		primary_id = target.id


func _secondary(t: Unit) -> bool:
	return primary_id >= 0 and t.id != primary_id


func _toggle(key: Variant, on: bool) -> void:
	if is_weapon_phase():
		if on:
			shots[key] = target.id
			if primary_id < 0:
				primary_id = target.id
		else:
			shots.erase(key)
			if not shots.values().has(primary_id):
				primary_id = shots.values()[0] if not shots.is_empty() else -1
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
	highlighter.show_hexes(hexes)
	var twist: String = ["  (torso twisted left)", "", "  (torso twisted right)"][attacker.torso_twist + 1]
	if target == null:
		hud.set_info("%s: tap an enemy to aim%s" % [Names.unit(attacker), twist])
		hud.set_tip(Advisor.targets(controller.state, attacker, level) if weapon else "Tap an adjacent enemy to punch or kick it.")
		if not hud.sheet_open:
			hud.show_side(null)
		return
	hud.set_info("%s -> %s (%d hexes)%s" % [Names.unit(attacker), Names.unit(target),
			Hex.distance(attacker.coord, target.coord), twist])
	if weapon:
		hud.set_tip(Advisor.volley(controller.state, attacker, _shot_list(), level))
		if not hud.sheet_open:
			hud.show_side(AttackPanel.build("Weapons at " + Names.unit(target), _weapon_rows(),
				_selected_here(), level, _toggle))
	else:
		hud.set_tip(Advisor.physical(controller.state, attacker, target, level))
		if not hud.sheet_open:
			hud.show_side(AttackPanel.build("Physical attack on " + Names.unit(target),
				_physical_rows(), physical, level, _toggle))


func _shot_list() -> Array:
	var out := []
	for wi: int in shots:
		out.append({"weapon": wi, "target_id": shots[wi]})
	out.sort_custom(func(a, b): return a["target_id"] == primary_id and b["target_id"] != primary_id)
	return out


func _selected_here() -> Dictionary:
	var out := {}
	for wi: int in shots:
		if shots[wi] == target.id:
			out[wi] = true
	return out


func _weapon_rows() -> Array:
	var rows := []
	for o in FireOptions.for_target(controller.state, attacker, target, _secondary(target)):
		var w: MountedWeapon = o["weapon"]
		var extra := ""
		if shots.has(o["index"]) and shots[o["index"]] != target.id:
			extra = "  (aimed at %s)" % Names.unit(controller.state.unit_by_id(shots[o["index"]]))
		elif o["to_hit"].possible():
			extra = "  avg %.1f, %d heat" % [Advisor.expected_damage(w.def, o["to_hit"]), w.def.heat]
		rows.append({"key": o["index"], "label": w.label(), "to_hit": o["to_hit"], "extra": extra})
	return rows


func _physical_rows() -> Array:
	var rows := []
	for o in PhysicalOptions.for_target(controller.state, attacker, target):
		var key := "%s:%d" % [o["kind"], o["limb"]]
		var lbl: String = o["kind"].capitalize()
		if o["limb"] >= 0:
			lbl += " (%s)" % Location.code(o["limb"])
		rows.append({"key": key, "label": lbl, "to_hit": o["to_hit"],
				"extra": "  %d dmg" % o["damage"] if o["damage"] > 0 else "  shove 1 hex"})
	return rows
