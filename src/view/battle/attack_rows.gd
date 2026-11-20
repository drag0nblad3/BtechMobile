class_name AttackRows
extends RefCounted
## Rows for the attack side panel: one per weapon or physical attack, with
## its to-hit number and a short note. Shots map weapon index -> target id
## ('Mech) or Vector2i (building hex).


static func weapons(state: GameState, attacker: Unit, options: Array, shots: Dictionary, here: Variant) -> Array:
	var rows := []
	for o in options:
		var w: MountedWeapon = o["weapon"]
		var extra := ""
		var aim: Variant = shots.get(o["index"])
		if aim != null and not (typeof(aim) == typeof(here) and aim == here):
			extra = "  (aimed at %s)" % target_name(state, aim)
		elif o["to_hit"].possible():
			extra = "  avg %.1f, %d heat" % [Advisor.expected_damage(w.def, o["to_hit"]), w.def.heat]
		var row := {"key": o["index"], "label": w.label(), "to_hit": o["to_hit"], "extra": extra}
		if WeaponModes.modes(w).size() > 1:
			row["mode"] = mode_text(w)
		rows.append(row)
	return rows


static func mode_text(w: MountedWeapon) -> String:
	match w.mode:
		WeaponModes.ULTRA:
			return "Double shot (2x heat and ammo)"
		WeaponModes.CLUSTER:
			return "Cluster ammo (-1 to hit, 1-point pellets)"
	return "Single shot" if w.def.rapid > 1 else "Standard ammo"


static func physical(state: GameState, attacker: Unit, target: Unit) -> Array:
	var rows := []
	for o in PhysicalOptions.for_target(state, attacker, target):
		var key := "%s:%d" % [o["kind"], o["limb"]]
		var lbl: String = o["kind"].capitalize()
		if o["limb"] >= 0:
			lbl += " (%s)" % Location.code(o["limb"])
		rows.append({"key": key, "label": lbl, "to_hit": o["to_hit"],
				"extra": "  %d dmg" % o["damage"] if o["damage"] > 0 else "  shove 1 hex"})
	return rows


static func target_name(state: GameState, t: Variant) -> String:
	if t is Vector2i:
		return "building " + Hex.label(t)
	return Names.unit(state.unit_by_id(int(t)))


## Declarable list: primary target's shots first, other 'Mechs, then buildings.
static func shot_list(shots: Dictionary, primary_id: int) -> Array:
	var out := []
	for wi: int in shots:
		if shots[wi] is int and shots[wi] == primary_id:
			out.append({"weapon": wi, "target_id": shots[wi]})
	for wi: int in shots:
		if shots[wi] is int and shots[wi] != primary_id:
			out.append({"weapon": wi, "target_id": shots[wi]})
	for wi: int in shots:
		if shots[wi] is Vector2i:
			out.append({"weapon": wi, "hex": shots[wi]})
	return out


## Weapons aimed at `here` (a 'Mech id or a building hex), as a set.
static func selected(shots: Dictionary, here: Variant) -> Dictionary:
	var out := {}
	for wi: int in shots:
		if typeof(shots[wi]) == typeof(here) and shots[wi] == here:
			out[wi] = true
	return out
