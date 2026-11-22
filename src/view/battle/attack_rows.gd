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
			extra = "  avg %.1f, %d heat" % [Advisor.expected_damage(w, o["to_hit"]), w.def.heat * WeaponModes.shots(w)]
			if w.cap_charged:
				extra += " (charged: +%d damage, +%d heat)" % [PpcCapacitor.DAMAGE, PpcCapacitor.HEAT]
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
		Narc.KIND:
			return "Narc-equipped missiles (home on Narc pods)"
		RotaryAc.UNJAM:
			return "Clear the jam (Gunnery +3, stand or walk)"
		PpcCapacitor.CHARGE:
			return "Charge the capacitor instead (5 heat a turn; next shot +5 damage)"
	if not w.def.munitions.is_empty():
		return Atm.mode_text(w)
	if w.def.rotary:
		if w.jammed:
			return "Jammed: tap to try clearing it"
		var n := WeaponModes.shots(w)
		return "1 shot" if n == 1 else "%d shots (jams on %d or less)" % [n, RotaryAc.jams_on(n)]
	if w.capacitor:
		return "Fire (capacitor empty)"
	return "Single shot" if w.def.rapid > 1 else "Standard ammo"


## Rows for physical attacks on a 'Mech, or (hex given) on a building.
static func physical(state: GameState, attacker: Unit, target: Unit, hex := Hex.INVALID) -> Array:
	var rows := []
	var opts := BuildingMelee.options(state, attacker, hex) if hex != Hex.INVALID \
			else PhysicalOptions.for_target(state, attacker, target)
	for o in opts:
		var key := "%s:%d" % [o["kind"], o["limb"]]
		var lbl: String = o["kind"].capitalize()
		if o["limb"] >= 0:
			lbl += " (%s)" % Location.code_for(attacker.def, o["limb"])
		rows.append({"key": key, "label": lbl, "to_hit": o["to_hit"],
				"extra": "  %d dmg" % o["damage"] if o["damage"] > 0 else "  shove 1 hex"})
	return rows


## Declaration list from the selected "kind:limb" keys.
static func physical_list(keys: Dictionary, target: Unit, hex: Vector2i) -> Array:
	var list := []
	for k: String in keys:
		var parts := k.split(":")
		var req := {"kind": parts[0], "limb": int(parts[1])}
		if hex != Hex.INVALID:
			req["hex"] = hex
		else:
			req["target_id"] = target.id
		list.append(req)
	return list


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
