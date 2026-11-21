class_name BotFire
extends RefCounted
## Bot weapon choice: best target by expected damage, then weapons in order
## of damage per heat while heat after the turn stays manageable.

## Heat limits come from BotSkill: a Veteran aims to end at 4 or less (no MP
## loss) and accepts 8 when the target is nearly dead.


## Returns {shots: [{weapon, target_id}], twist, modes: {weapon index: mode}, reason}.
static func plan(state: GameState, u: Unit) -> Dictionary:
	var best := {"shots": [], "twist": 0, "reason": "holds fire: no enemy in range and sight", "value": 0.0}
	var original := u.torso_twist
	var nearest := BotMove.nearest_enemy(state, u, u.coord)
	for twist in ([0, -1, 1] if not u.prone and not u.def.quad and BotSkill.basic_tricks() else [0]):
		u.torso_twist = twist
		for e in state.units:
			if e.side == u.side or e.destroyed or (BotSkill.nearest_only() and e != nearest):
				continue
			for ultra in ([true, false] if BotModes.has_ultra(u) and BotSkill.advanced_tricks() else [false]):
				var before := BotModes.apply(state, u, e, ultra)
				var p := _volley(state, u, e)
				if p["value"] > best["value"]:
					p["twist"] = twist
					p["modes"] = _modes(u, p["shots"])
					var note := BotModes.describe(u, p["shots"])
					if note != "":
						p["reason"] += "; " + note
					best = p
				BotModes.restore(u, before)
	u.torso_twist = original
	return best


static func _modes(u: Unit, shots: Array) -> Dictionary:
	var out := {}
	for sh: Dictionary in shots:
		out[int(sh["weapon"])] = u.weapons[int(sh["weapon"])].mode
	return out


static func _volley(state: GameState, u: Unit, e: Unit) -> Dictionary:
	var opts := []
	for o in FireOptions.for_target(state, u, e):
		if o["to_hit"].possible():
			var ed := Advisor.expected_damage(o["weapon"], o["to_hit"])
			if ed > 0.0:
				opts.append([ed, o])
	opts.sort_custom(func(a, b): return a[0] / maxf(1.0, _heat(a[1]["weapon"])) > b[0] / maxf(1.0, _heat(b[1]["weapon"])))
	var limit := BotSkill.heat_stretch() if _fragile(e) else BotSkill.heat_limit()
	var shots := []
	var idx := []
	var total := 0.0
	var held: Array[String] = []
	for pair in opts:
		var o: Dictionary = pair[1]
		var after := Advisor.projected_heat(u, FireOptions.volley_heat(u, idx + [o["index"]]))
		if after > limit and not idx.is_empty():
			held.append(o["weapon"].def.name)
			continue
		idx.append(o["index"])
		shots.append({"weapon": o["index"], "target_id": e.id})
		total += pair[0]
	# Prefer damaged or slow targets a little: finishing one off matters.
	var value := total * (1.0 + 0.5 * _damage_fraction(e))
	var why := "fires at %s: %.1f expected damage" % [Names.unit(e), total]
	if _damage_fraction(e) > 0.3:
		why += ", it is already badly hurt"
	if not held.is_empty():
		why += "; holds %s to stay cool" % ", ".join(held)
	return {"shots": shots, "value": value, "reason": why}


static func _heat(w: MountedWeapon) -> float:
	return float(w.def.heat * WeaponModes.shots(w))


static func _damage_fraction(e: Unit) -> float:
	var full := 0.0
	var now := 0.0
	for loc in Location.COUNT:
		full += e.def.armor[loc] + e.def.rear_armor[loc] + StructureTable.points(e.def.tonnage, loc, e.def.quad)
		now += e.armor[loc] + e.rear_armor[loc] + e.structure[loc]
	return 1.0 - now / maxf(1.0, full)


static func _fragile(e: Unit) -> bool:
	return _damage_fraction(e) > 0.6 or e.structure[Location.CT] < StructureTable.points(e.def.tonnage, Location.CT) / 2
