class_name TagText
extends RefCounted
## Log text for a TAG designation (Tag).


static func describe(s: GameState, d: Dictionary, level: int, seen: Dictionary = {}) -> String:
	var who := Names.unit(s.unit_by_id(d["unit_id"]))
	var target := Names.unit(s.unit_by_id(d["target_id"]))
	if d.has("why"):
		return "%s can't TAG %s: %s." % [who, target, d["why"]]
	var t := "%s fires TAG at %s: rolled %d, needed %d+, %s." % [who, target, d["roll"], d["need"],
			"designated" if d["hit"] else "missed"]
	if level == ExplainLevel.FULL:
		t += (" Friendly missiles that can fire indirectly may now arc in at it, with the TAG 'Mech as spotter and no +1 for spotting while shooting."
				if d["hit"] else " A miss costs nothing: it can still spot normally this turn.")
	return t + ModsText.lines(d["mods"], level, seen)
