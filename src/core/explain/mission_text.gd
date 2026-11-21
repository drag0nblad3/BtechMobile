class_name MissionText
extends RefCounted
## Log text for missions: crippling, withdrawing, leaving the map, Victory
## Points, Random Duration and how the battle was decided.


static func describe(e: GameEvent, s: GameState, level: int) -> String:
	var d := e.data
	match e.type:
		GameEvent.CRIPPLED:
			var who := Names.unit(s.unit_by_id(d["unit_id"]))
			var t := "%s is crippled (%s)." % [who, d["why"]]
			if d["withdraw"]:
				t += " It must withdraw."
				if level == ExplainLevel.FULL:
					t += " From now on it has to move toward its home edge every turn and may leave the map there. It can still shoot, but no longer holds objectives, and the enemy scores it as if destroyed."
			return t
		GameEvent.UNIT_EXITED:
			var who := Names.unit(s.unit_by_id(d["unit_id"]))
			if d["kind"] == "withdraw":
				var t := "%s withdraws off the battlefield." % who
				if level != ExplainLevel.OFF:
					t += " Saving it earns its side %d VP (half its value)." % d["vp"]
				return t
			return "%s leaves the battlefield and scores %d VP." % [who, d["vp"]]
		GameEvent.MISSION:
			if d["kind"] == "vp":
				if level == ExplainLevel.OFF:
					return ""
				return "%s holds objectives: +%d VP (total %d)." % [Names.side(d["side"]), d["vp"], d["total"]]
			if d["kind"] == "duration":
				var t := "Random duration: rolled %d (ends on %d or less): %s." % [d["roll"], d["ends_on"],
						"this is the last turn" if d["last"] else "the battle goes on"]
				return t if level != ExplainLevel.OFF or d["last"] else ""
		GameEvent.GAME_OVER:
			return game_over(d)
	return ""


static func game_over(d: Dictionary) -> String:
	var t := "Battle over: %s wins" % Names.side(d["winner"]) if d["winner"] >= 0 else "Battle over: nobody wins"
	if d.has("scores"):
		var parts: Array[String] = []
		for side: int in d["scores"]:
			parts.append("%s %d VP" % [Names.side(side), d["scores"][side]])
		t += " (%s; %s)" % [", ".join(parts), d.get("why", "")]
	elif d["winner"] < 0:
		t = "Battle over: no survivors"
	return t + "."


## Short score line for the HUD status ("" without a Victory Point mission).
static func status(s: GameState) -> String:
	var m := s.mission.def
	if m == null or not m.uses_vp():
		return ""
	var parts: Array[String] = []
	for side in s.sides():
		parts.append("%s %d" % [Names.side(side), VictoryPoints.total(s, side)])
	var turns := ("/%d" % m.turns) if m.turns > 0 and not m.random_duration else ""
	return "  ·  VP %s%s" % [", ".join(parts), ("  ·  of " + turns.substr(1) + " turns") if turns != "" else ""]


## The mission's goal in plain words, for the start of the battle.
static func briefing(m: Mission, level: int) -> String:
	if m == null:
		return ""
	var t := "Mission: %s." % m.name
	if m.summary != "" and level != ExplainLevel.OFF:
		t += " " + m.summary
	if m.turns > 0:
		t += " %s turns%s." % [m.turns, " (or fewer: Random Duration)" if m.random_duration else ""]
	for n: String in m.notes:
		t += " " + n + ("" if n.ends_with(".") else ".")
	if m.forced_withdrawal and level == ExplainLevel.FULL:
		t += " Forced Withdrawal: a badly damaged 'Mech (two engine hits, a side torso, or two limbs including a leg) must retreat to its home edge."
	return t
