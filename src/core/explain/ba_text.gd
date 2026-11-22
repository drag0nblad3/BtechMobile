class_name BaText
extends RefCounted
## Log text for battle armor squads: which trooper a hit struck. Our own wording.


static func damage(s: GameState, d: Dictionary, level: int) -> String:
	var u := s.unit_by_id(d["unit_id"])
	var t := "  %s: trooper %d takes %d" % [Names.unit(u), d["trooper"], d["amount"]]
	if d["killed"]:
		t += " and is down (%d left)" % d["alive"]
	else:
		t += " (%d armor left)" % d["armor_left"]
	if level == ExplainLevel.FULL:
		t += ". Each hit lands on one trooper; damage past its armor kills it and the rest is wasted, so many small hits beat one big one."
	return t
