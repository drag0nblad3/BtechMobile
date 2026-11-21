class_name WeaponText
extends RefCounted
## Log text for one weapon resolving (hit or miss, clusters, AMS, Artemis, aimed shots).


static func fired(s: GameState, d: Dictionary, level: int, seen: Dictionary) -> String:
	var who := "%s %s -> %s" % [Names.unit(s.unit_by_id(d["attacker_id"])), d["weapon"], Explainer._target(s, d)]
	if d.get("no_ammo", false):
		return "%s: out of ammo." % who
	var res := "HIT" if d["hit"] else "miss"
	if d.get("shots", 1) > 1:
		res += " (%d shots)" % d["shots"]
	if d["missiles"] > 0:
		var unit := "shots" if d.get("mode", "") == WeaponModes.ULTRA or d.get("shots", 1) > 1 else (
				"pellets" if d.get("mode", "") == WeaponModes.CLUSTER else "missiles")
		res += ", %d %s" % [d["missiles"], unit]
		if d.get("cluster_bonus", 0) > 0 and level != ExplainLevel.OFF:
			res += " (Artemis +%d)" % d["cluster_bonus"]
		if d.has("artemis_blocked") and level != ExplainLevel.OFF:
			res += " (no Artemis bonus: %s)" % d["artemis_blocked"]
	if d.get("ams", false):
		res += "; anti-missile fire shot some down (-4 to the cluster roll)" if level != ExplainLevel.OFF else ", AMS"
	if d.get("streak_held", false) and level != ExplainLevel.OFF:
		res += "; the Streak never locked on, so it held its missiles (no heat, no ammo used)"
	if d.get("jammed", false):
		res += "; the rotary AC JAMS" + (" (a roll of %d or less jams it at %d shots; clearing it takes a Gunnery roll +3 while standing or walking)"
				% [RotaryAc.jams_on(d["shots"]), d["shots"]] if level == ExplainLevel.FULL else "")
	if d.get("heat_added", 0) > 0:
		res += ", +%d heat to the target" % d["heat_added"]
	if d.has("aim_roll"):
		res += "; aim roll %d: %s" % [d["aim_roll"], ("lands on the " + Location.name_of(d["aim"]).to_lower())
				if d["aim_hit"] else "missed the aim, hit location rolled"]
		if level == ExplainLevel.FULL:
			res += " (aimed shots need 4+ on 1D6)"
	if level == ExplainLevel.OFF:
		return "%s: %s" % [who, res]
	var t := "%s: rolled %d, needed %d: %s" % [who, d["roll"], d["need"], res]
	if d["need"] <= 2:
		t += " (2 or less always hits)"
	return t + ModsText.lines(d["mods"], level, seen)


## A try at clearing a jammed rotary AC.
static func unjam(s: GameState, d: Dictionary, level: int) -> String:
	var who := "%s's %s" % [Names.unit(s.unit_by_id(d["unit_id"])), d["weapon"]]
	if d.has("why"):
		return "%s stays jammed: %s." % [who, d["why"]]
	if level == ExplainLevel.OFF:
		return "%s: %s." % [who, "cleared" if d["ok"] else "still jammed"]
	return "%s: clearing roll %d, needed %d (Gunnery +3): %s." % [who, d["roll"], d["need"],
			"cleared, it can fire next turn" if d["ok"] else "still jammed"]
