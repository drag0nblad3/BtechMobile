class_name Names
extends RefCounted
## Display names for sides and units in logs and explanations.

const SIDES := ["Red", "Blue", "Yellow", "Green"]


static func side(s: int) -> String:
	return SIDES[s] if s >= 0 and s < SIDES.size() else "Side %d" % s


static func unit(u: Unit) -> String:
	return "%s %s" % [side(u.side), u.def.name] if u else "?"


static func pct(chance: float) -> String:
	return "%d%%" % roundi(chance * 100.0)
