class_name BotModes
extends RefCounted
## Bot firing modes. LB-X: slugs or cluster ammo, whichever has the higher
## expected damage at this to-hit number (cluster is 1 easier, but pellets
## add up to less), falling back to whichever ammo is left. Ultra ACs: BotFire
## plans the volley twice (double fire on and off) and keeps the better one.


## Sets each weapon's mode for shooting at `e`. ultra: allow double fire.
## Returns the previous modes so the caller can put them back.
static func apply(state: GameState, u: Unit, e: Unit, ultra: bool) -> Array[String]:
	var before: Array[String] = []
	for w in u.weapons:
		before.append(w.mode)
		if w.def.rapid > 1:
			w.mode = WeaponModes.ULTRA if ultra and u.ammo_for(w.def) >= w.def.rapid else ""
		elif w.def.lbx:
			w.mode = _lbx(state, u, w, e)
	return before


static func restore(u: Unit, before: Array[String]) -> void:
	for i in before.size():
		u.weapons[i].mode = before[i]


static func has_ultra(u: Unit) -> bool:
	for w in u.weapons:
		if w.def.rapid > 1 and not w.destroyed:
			return true
	return false


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
		elif w.mode == WeaponModes.CLUSTER:
			parts.append("loads cluster rounds in its %s for the easier hit" % w.def.name)
	return "; ".join(parts)
