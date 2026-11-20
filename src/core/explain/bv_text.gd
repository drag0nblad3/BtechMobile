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
	if level == ExplainLevel.LIGHT:
		return "Defense %d · offense %d" % [roundi(b["defensive"]), roundi(b["offensive"])]
	var parts: Array[String] = ["BV %d." % b["total"]]
	parts.append("Defense %d from %d armor and its structure%s." % [roundi(b["defensive"]),
			def.total_armor(), (", +%d to hit it when it runs" % b["tmm"]) if b["tmm"] > 0 else ""])
	if b["ammo_penalty"] > 0:
		parts.append("Its %d tons of ammo can explode, which lowers defense." % def.ammo_mounts.size())
	parts.append("Offense %d from its weapons%s." % [roundi(b["offensive"]),
			", boosted by speed" if b["speed_factor"] > 1.0 else (", reduced by low speed" if b["speed_factor"] < 1.0 else "")])
	var halved: Array = b["halved"]
	if not halved.is_empty():
		var names := _unique(halved)
		parts.append("%s count%s half: it can't fire everything without overheating." % [
				", ".join(names), "" if names.size() > 1 else "s"])
	return " ".join(parts)


static func _unique(names: Array) -> PackedStringArray:
	var out := PackedStringArray()
	for n: String in names:
		if not out.has(n):
			out.append(n)
	return out
