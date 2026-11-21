class_name PilotText
extends RefCounted
## Log text for piloting rolls, falls and MechWarrior injuries.


static func describe(e: GameEvent, s: GameState, level: int, seen: Dictionary = {}) -> String:
	var d := e.data
	var who := Names.unit(s.unit_by_id(d["unit_id"]))
	match e.type:
		GameEvent.PSR:
			if level == ExplainLevel.OFF:
				return "" if d["ok"] else "%s fails a piloting roll (%s)." % [who, d["reason"]]
			var t := "%s piloting roll (%s): rolled %d, needed %d: %s" % [who, d["reason"],
					d["roll"], d["need"], "OK" if d["ok"] else "FAILED"]
			return t + ModsText.lines(d["mods"], level, seen)
		GameEvent.FALL:
			var t := "%s falls (%s) onto its %s and takes %d damage." % [who, d["reason"],
					"back" if d.get("rear", false) else "front", d["damage"]]
			if level == ExplainLevel.FULL:
				t += " Heavier 'Mechs fall harder: 1 point per 10 tons%s. Standing up next turn costs 2 MP and a roll." % (
						", halved by the water" if d.get("water", false) else "")
			return t
		GameEvent.WENT_PRONE:
			var t := "%s drops prone." % who
			if level == ExplainLevel.FULL:
				t += " Lying down is +1 to hit from range but -2 from an adjacent 'Mech, and it fires at +2 itself. Standing up costs 2 MP and a piloting roll."
			return t
		GameEvent.MASC:
			var t := "%s engages MASC: rolled %d, needed %d: %s" % [who, d["roll"], d["need"],
					"it can run at twice its walking speed" if d["ok"] else "it FAILS and strains its legs"]
			if level == ExplainLevel.OFF:
				return "%s's MASC %s." % [who, "kicks in" if d["ok"] else "fails"]
			if level == ExplainLevel.FULL:
				t += ". Using it again next turn needs %d+; each turn of rest lowers that by a step" % d["next"]
				if not d["ok"]:
					t += ". A failure means a critical check on one leg at the end of the move"
			return t + "."
		GameEvent.STAND:
			return "%s %s." % [who, "stands up" if d["ok"] else "fails to stand"]
		GameEvent.PILOT_HIT:
			var t := "%s's MechWarrior is hurt (%s): %d/6 hits." % [who, d["why"], d["hits"]]
			if level == ExplainLevel.FULL and d["hits"] < 6:
				t += " Each hit makes blacking out more likely; six is fatal."
			return t
		GameEvent.CONSCIOUSNESS:
			if d["was_conscious"] and d["conscious"]:
				return "" if level == ExplainLevel.OFF else "%s stays conscious (%d vs %d+)." % [who, d["roll"], d["need"]]
			if d["was_conscious"]:
				return "%s's MechWarrior blacks out (%d vs %d+)." % [who, d["roll"], d["need"]]
			return "%s's MechWarrior %s." % [who, "wakes up" if d["conscious"] else "is still out"]
	return ""
