class_name DamageText
extends RefCounted
## Log text for damage, critical checks and ammo explosions.


static func damage(s: GameState, d: Dictionary, level: int) -> String:
	var who := Names.unit(s.unit_by_id(d["unit_id"]))
	var loc := Location.name_of(d["loc"]) + (" (rear)" if d.get("rear", false) else "")
	if d["covered"]:
		return "  %d damage at %s's %s strikes the %s instead." % [d["amount"], who, loc,
				"hill in front of it" if d.get("hill", false) else "water"]
	var t := "  %s takes %d in the %s" % [who, d["amount"], loc]
	if level != ExplainLevel.OFF:
		var parts: Array[String] = []
		for st: Dictionary in d["steps"]:
			var p := "%s %d armor" % [Location.code(st["loc"]), st["armor"]]
			if st["structure"] > 0:
				p += " + %d structure" % st["structure"]
			if st["destroyed"]:
				p += ", DESTROYED"
			parts.append(p)
		t += " (%s)" % "; ".join(parts)
	else:
		for st: Dictionary in d["steps"]:
			if st["destroyed"]:
				t += ", %s destroyed" % Location.name_of(st["loc"])
	if level == ExplainLevel.FULL:
		if d["steps"].size() > 1:
			t += "\n  Damage past a destroyed location moves inward toward the center torso."
		elif d["steps"].size() == 1 and d["steps"][0]["breached"]:
			t += "\n  Armor is gone there: structure hits can cause critical hits."
		if d.get("tac", false):
			t += "\n  A location roll of 2 can cause a critical hit even through armor."
	return t + "."


static func crit_check(s: GameState, d: Dictionary, level: int) -> String:
	if d["crits"] == 0 and level != ExplainLevel.FULL:
		return ""
	var t := "  Critical check (%s): rolled %d, %d critical hit%s" % [
			Location.code(d["loc"]), d["roll"], d["crits"], "" if d["crits"] == 1 else "s"]
	if level == ExplainLevel.FULL:
		t += ". 8-9 means one, 10-11 two, 12 three or a lost limb"
	return t + "."


static func breach(s: GameState, d: Dictionary, level: int) -> String:
	var who := Names.unit(s.unit_by_id(d["unit_id"]))
	var where := Location.name_of(d["loc"]).to_lower()
	var roll: int = d["roll"]
	if not d["flooded"]:
		return "" if level != ExplainLevel.FULL else "  Hull breach check (%s): rolled %d, the seals hold." % [where, roll]
	var why := "rolled %d" % roll if roll > 0 else ("no armor left under water" if roll == 0 else "the torso beside it flooded")
	var t := "  %s's %s floods (%s)" % [who, where, why]
	if not d["effects"].is_empty():
		t += ": %s stop working" % ", ".join(d["effects"])
	if level == ExplainLevel.FULL:
		t += ". Damage under water risks a breach on 2-4; a flooded location is dead weight for the rest of the battle"
	return t + "."


static func ammo(s: GameState, d: Dictionary, level: int) -> String:
	var t := "  %s's %s ammo explodes in the %s for %d damage!" % [
			Names.unit(s.unit_by_id(d["unit_id"])), d["ammo"], Location.name_of(d["loc"]), d["damage"]]
	if d.get("case", false) and level != ExplainLevel.OFF:
		t += " CASE vents the blast out the back: the damage stays in that location."
	if level == ExplainLevel.FULL:
		t += " Ammo explosions skip armor and hurt the pilot. Energy weapons can't explode."
	return t
