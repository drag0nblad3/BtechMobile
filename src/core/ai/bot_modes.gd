class_name BotModes
extends RefCounted
## Bot firing modes. LB-X: slugs or cluster ammo, whichever has the higher
## expected damage at this to-hit number (cluster is 1 easier, but pellets
## add up to less), falling back to whichever ammo is left. Ultra ACs: BotFire
## plans the volley twice (double fire on and off) and keeps the better one;
## rotary ACs fire four shots in the "on" plan.

const ROTARY_SHOTS := 4


## Sets each weapon's mode for shooting at `e`. ultra: allow double fire.
## Returns the previous modes so the caller can put them back.
static func apply(state: GameState, u: Unit, e: Unit, ultra: bool) -> Array[String]:
	var before: Array[String] = []
	for w in u.weapons:
		before.append(w.mode)
		if w.def.rotary:
			w.mode = _rotary(u, w, ultra)
		elif w.def.rapid > 1:
			w.mode = WeaponModes.ULTRA if ultra and u.ammo_for(w.def) >= w.def.rapid else ""
		elif w.def.lbx:
			w.mode = _lbx(state, u, w, e)
		elif w.narc_ammo:
			w.mode = _narc(state, u, w, e)
	return before


static func restore(u: Unit, before: Array[String]) -> void:
	for i in before.size():
		u.weapons[i].mode = before[i]


static func has_ultra(u: Unit) -> bool:
	for w in u.weapons:
		if w.def.rapid > 1 and not w.destroyed:
			return true
	return false


## Rotary AC: four shots when rapid fire is on (jams on 3 or less, 1 in 12),
## fewer if ammo is short; a jammed one is set to clearing.
static func _rotary(u: Unit, w: MountedWeapon, ultra: bool) -> String:
	if w.jammed:
		return RotaryAc.UNJAM if RotaryAc.unjam_problem(u) == "" else ""
	var n := mini(ROTARY_SHOTS, u.ammo_for(w.def)) if ultra else 1
	return "x%d" % n if n > 1 else ""


## Sets every jammed rotary AC to try clearing; returns a note ("" if none).
static func unjam_all(gc: GameController, u: Unit) -> String:
	var names: Array[String] = []
	for i in u.weapons.size():
		var w := u.weapons[i]
		if w.jammed and not w.destroyed and RotaryAc.unjam_problem(u) == "" and gc.set_weapon_mode(u, i, RotaryAc.UNJAM):
			names.append(w.def.name)
	return "works to clear its jammed %s" % ", ".join(names) if not names.is_empty() else ""


## Narc-equipped missiles when they home on a pod (or are all that's left).
static func _narc(state: GameState, u: Unit, w: MountedWeapon, e: Unit) -> String:
	var narc := u.ammo_for(w.def, Narc.KIND)
	if narc > 0 and (u.ammo_for(w.def) == 0 or Narc.homing(state, u, e)):
		return Narc.KIND
	return ""


static func _lbx(state: GameState, u: Unit, w: MountedWeapon, e: Unit) -> String:
	var slugs := u.ammo_for(w.def)
	var pellets := u.ammo_for(w.def, WeaponModes.CLUSTER)
	if slugs <= 0 or pellets <= 0:
		return WeaponModes.CLUSTER if pellets > 0 else ""
	var best := ""
	var best_ed := -1.0
	for m: String in ["", WeaponModes.CLUSTER]:
		w.mode = m
		var ed := Advisor.expected_damage(w, ToHitCalc.weapon(state, u, w, e, false))
		if ed > best_ed:
			best_ed = ed
			best = m
	return best


## A note on the modes used, for the bot's announcement ("" if none).
static func describe(u: Unit, shots: Array) -> String:
	var parts: Array[String] = []
	for sh: Dictionary in shots:
		var w := u.weapons[int(sh["weapon"])]
		if w.mode == WeaponModes.ULTRA:
			parts.append("double-fires its %s" % w.def.name)
		elif w.def.rotary and WeaponModes.shots(w) > 1:
			parts.append("fires %d shots from its %s" % [WeaponModes.shots(w), w.def.name])
		elif w.mode == WeaponModes.CLUSTER:
			parts.append("loads cluster rounds in its %s for the easier hit" % w.def.name)
	return "; ".join(parts)
