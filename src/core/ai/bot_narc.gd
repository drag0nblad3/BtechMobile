class_name BotNarc
extends RefCounted
## Bot Narc beacons: adds a beacon shot at the volley's target when the
## side has Narc-equipped missiles to use and no pod of its own is on it yet.
## Beacons make no heat, so they never crowd out other weapons.


## Adds beacon shots to `shots`; returns a note ("" if none).
static func add_beacons(state: GameState, u: Unit, shots: Array) -> String:
	if shots.is_empty() or not _side_has_narc_ammo(state, u.side):
		return ""
	var t := state.unit_by_id(int(shots[0].get("target_id", -1)))
	if t == null or t.narc_pods.any(func(p: Dictionary) -> bool: return p["side"] == u.side):
		return ""
	var used := shots.map(func(sh: Dictionary) -> int: return int(sh["weapon"]))
	for i in u.weapons.size():
		if u.weapons[i].def.beacon and not used.has(i) and ToHitCalc.weapon(state, u, u.weapons[i], t).possible():
			shots.append({"weapon": i, "target_id": t.id})
			return "tags %s with a Narc pod for its side's homing missiles" % Names.unit(t)
	return ""


static func _side_has_narc_ammo(state: GameState, side: int) -> bool:
	for f in state.units:
		if f.side == side and not f.destroyed and f.weapons.any(func(w: MountedWeapon) -> bool:
				return w.narc_ammo and f.ammo_for(w.def, Narc.KIND) > 0):
			return true
	return false
