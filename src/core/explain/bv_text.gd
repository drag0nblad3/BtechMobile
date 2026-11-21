class_name BvText
extends RefCounted
## Explains where a design's Battle Value comes from, in our own words.

const WHAT_IS_BV := "Battle Value (BV) scores how much a 'Mech is worth in a fight: " \
		+ "how much punishment it can take and how hard it is to hit, plus how much " \
		+ "damage it can deal without overheating and how fast it gets there. " \
		+ "Equal BV means a fair fight, even when tonnage differs."


## One line for the force builder catalog. Empty at Off.
static func line(def: UnitDef, level: int) -> String:
	var b := BattleValue.breakdown(def)
	if level == ExplainLevel.OFF:
		return ""
	var official := BattleValue.is_official(def)
	if level == ExplainLevel.LIGHT:
		if official:
			return "BV %d (official sheet)" % def.bv
		return "Defense %d · offense %d" % [roundi(b["defensive"]), roundi(b["offensive"])]
	if official:
		return _official(def, b)
	var parts: Array[String] = ["BV %d (our estimate: no official sheet)." % b["total"]]
	parts.append("Defense %d from %d armor and its structure%s." % [roundi(b["defensive"]),
			def.total_armor(), (", +%d to hit it when it runs" % b["tmm"]) if b["tmm"] > 0 else ""])
	if b["ammo_penalty"] > 0:
		var n := def.ammo_mounts.size()
		parts.append("Its %d ton%s of ammo can explode, which lowers defense." % [n, "" if n == 1 else "s"])
	parts.append("Offense %d from its weapons%s." % [roundi(b["offensive"]),
			", boosted by speed" if b["speed_factor"] > 1.0 else (", reduced by low speed" if b["speed_factor"] < 1.0 else "")])
	var halved: Array = b["halved"]
	if not halved.is_empty():
		var names := _unique(halved)
		parts.append("%s count%s half: it can't fire everything without overheating." % [
				", ".join(names), "" if names.size() > 1 else "s"])
	return " ".join(parts)


## Official BV: name the source, then say in words what drives it.
static func _official(def: UnitDef, b: Dictionary) -> String:
	var parts: Array[String] = ["BV %d, from its official record sheet." % def.bv]
	parts.append("It earns defense from %d armor%s." % [def.total_armor(),
			(" and being hard to hit when it runs (+%d)" % b["tmm"]) if b["tmm"] > 0 else ""])
	if not def.ammo_mounts.is_empty():
		parts.append("Ammo that can explode lowers it.")
	var halved: Array = b["halved"]
	if not halved.is_empty():
		parts.append("It can't fire everything without overheating, so some guns count for less.")
	return " ".join(parts)


static func _unique(names: Array) -> PackedStringArray:
	var out := PackedStringArray()
	for n: String in names:
		if not out.has(n):
			out.append(n)
	return out
