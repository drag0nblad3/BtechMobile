class_name AttackInput
extends Node
## Weapon and physical attack phases: pick your 'Mech (the first one waiting
## is picked for you), tap an enemy, toggle weapons or punches/kicks in the
## side panel, then Fire / Attack or Hold Fire / Skip.
## The primary target is the first enemy in your forward arc you assign
## weapons to (else the first enemy). In the weapon
## phase you may also tap a building to shoot it, or woods to set them alight.

signal attacker_selected(u: Unit)
signal target_chosen(attacker: Unit, target: Unit)  ## The camera frames the pair.

var controller: GameController
var hud: BattleHud
var highlighter: HexHighlighter
var aim_guide: BattleAimOverlay
var bots: BotDriver
var units_layer: UnitsLayer

var attacker: Unit
var target: Unit
var target_hex := Hex.INVALID  ## Building being aimed at, if any.
var primary_id := -1
var shots := {}     ## Weapon phase: weapon index -> target id, or building hex (Vector2i).
var aims := {}  ## Weapon phase: target id -> aimed location (AimPicker).
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
	aims.clear()
	physical.clear()
	hud.show_attack_controls(false)
	if not hud.sheet_open:
		hud.show_side(null)  # Submitted or abandoned targeting does not own the panel.
	highlighter.clear()
	if aim_guide != null:
		aim_guide.clear()


func on_hex_tapped(c: Vector2i) -> bool:
	if not active():
		return false
	var u := controller.state.unit_at(c)
	if u == null:
		var tile := controller.state.map.get_tile(c)
		if attacker == null or tile == null or not (Bridges.structure(tile) != null
				or (is_weapon_phase() and WoodsFire.can_light(tile))):
			return false
		target = null
		target_hex = c
		physical.clear()
		if is_weapon_phase():
			_default_shots()
		_refresh()
		return true
	if u == attacker and not is_weapon_phase() and not BaSwarm.swarmers(controller.state, u).is_empty():
		u = BaSwarm.swarmers(controller.state, u)[0]  # tap your own hex to swat swarmers off
	if controller.pending_units().has(u):
		_select(u)
	elif attacker and u.side != attacker.side:
		target = u
		target_hex = Hex.INVALID
		physical.clear()
		if is_weapon_phase():
			_default_shots()
		target_chosen.emit(attacker, u)
	_refresh()
	return true


func on_confirm() -> void:
	if attacker == null or (units_layer != null and units_layer.attack_playing):
		return
	var u := attacker
	if is_weapon_phase():
		var list := _shot_list()
		clear()
		controller.declare_fire(u, list)
	else:
		var list := AttackRows.physical_list(physical, target, target_hex)
		clear()
		controller.declare_physical(u, list)


## Hint: pre-select the attack an Elite computer player would make; you still confirm.
func on_hint() -> void:
	if attacker == null:
		return
	var state := controller.state
	if is_weapon_phase():
		var h := Hint.fire(state, attacker, GameSettings.explain_level)
		if h["twist"] == BotFire.FLIP:
			controller.set_arms_flipped(attacker, true)
		elif attacker.arms_flipped:
			controller.set_arms_flipped(attacker, false)
		if h["twist"] != BotFire.FLIP:
			controller.set_torso_twist(attacker, h["twist"])
		for i: int in h["modes"]:
			controller.set_weapon_mode(attacker, i, h["modes"][i])
		shots.clear()
		aims.clear()
		primary_id = -1
		target_hex = Hex.INVALID
		for sh: Dictionary in h["shots"]:
			shots[int(sh["weapon"])] = int(sh["target_id"])
			if primary_id < 0:
				primary_id = int(sh["target_id"])
			if sh.has("aim"):
				aims[int(sh["target_id"])] = int(sh["aim"])
		target = state.unit_by_id(primary_id) if primary_id >= 0 else target
		_finish_hint(h["text"])
		return
	var p := Hint.physical(state, attacker, GameSettings.explain_level)
	physical.clear()
	for a: Dictionary in p["attacks"]:
		target = state.unit_by_id(int(a["target_id"]))
		target_hex = Hex.INVALID
		physical["%s:%d" % [a["kind"], int(a["limb"])]] = true
	_finish_hint(p["text"])


func _finish_hint(text: String) -> void:
	if target:
		target_chosen.emit(attacker, target)
	_refresh()
	hud.set_tip(text + "\n" + hud.tip.text)


func _pick_up_club() -> void:
	var u := attacker
	clear()
	controller.pick_up_club(u)


func on_twist(dir: int) -> void:
	if attacker and is_weapon_phase():
		controller.set_torso_twist(attacker, clampi(attacker.torso_twist + dir, -1, 1))
		shots.clear()
		primary_id = -1
		if target or target_hex != Hex.INVALID:
			_default_shots()
		_refresh()


func on_flip() -> void:
	if attacker and is_weapon_phase():
		controller.set_arms_flipped(attacker, not attacker.arms_flipped)
		shots.clear()
		primary_id = -1
		if target or target_hex != Hex.INVALID:
			_default_shots()
		_refresh()


func on_skip() -> void:
	if attacker == null or (units_layer != null and units_layer.attack_playing):
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
	aims.clear()
	physical.clear()
	attacker_selected.emit(u)
	_refresh()


## Selects every possible weapon not already aimed elsewhere.
func _default_shots() -> void:
	for o in AttackView.options(self):
		if o["to_hit"].possible() and not shots.has(o["index"]):
			shots[o["index"]] = _here()
	if target and primary_id < 0 and _selected_here().size() > 0:
		primary_id = target.id


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
			if _alone(String(key)):
				physical.clear()
			else:
				for k: String in physical.keys():
					if _alone(k):
						physical.erase(k)
			physical[key] = true
		else:
			physical.erase(key)
	_refresh()


## Attacks that must be the only physical attack this turn.
static func _alone(key: String) -> bool:
	return key.begins_with("kick") or key.begins_with("push") or key.begins_with(Zweihander.KIND)


func _mode(key: Variant) -> void:
	var w := attacker.weapons[int(key)]
	controller.set_weapon_mode(attacker, int(key), WeaponModes.next_mode(w))
	_refresh()


func _refresh() -> void:
	AttackView.refresh(self)
	if aim_guide != null:
		aim_guide.show_attack(self)


func _shot_list() -> Array:
	return AimPicker.tag(AttackRows.shot_list(shots, primary_id), aims)


func _next_aim() -> void:
	aims[target.id] = AimPicker.next(target, aims.get(target.id, -1))
	_refresh()


func _selected_here() -> Dictionary:
	return AttackRows.selected(shots, _here())


## Current aim: the target 'Mech's id, or the building hex.
func _here() -> Variant:
	return target_hex if target_hex != Hex.INVALID else (target.id if target else -1)

