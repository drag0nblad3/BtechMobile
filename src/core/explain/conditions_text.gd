class_name ConditionsText
extends RefCounted
## Plain words for the battlefield conditions in play (Conditions).


## One line naming the conditions; FULL adds what each one does.
static func describe(c: Conditions, level: int) -> String:
	if c == null or c.is_clear():
		return ""
	var t := "Conditions: %s." % ", ".join(c.names())
	if level == ExplainLevel.FULL:
		for line in effects(c):
			t += "\n" + line
	return t


## One sentence per condition on what it changes.
static func effects(c: Conditions) -> Array[String]:
	var out: Array[String] = []
	if c.cold > 0:
		out.append("Extreme cold: every 'Mech sheds %d extra heat a turn, and shutdown and ammo rolls from heat are %d easier. A warrior with broken life support now suffers from the cold, unless the 'Mech runs warm." % [
				ExtremeTemp.extra_sinks(c), c.cold])
	if c.heat > 0:
		out.append("Extreme heat: every 'Mech gains %d heat a turn, and shutdown and ammo rolls from heat are %d harder. Fire fewer weapons than usual." % [
				ExtremeTemp.heat_added(c), c.heat])
	if c.odd_gravity():
		out.append("Gravity %.1f G: damage from falls and collapsing buildings is multiplied by %.1f, and every jump needs a piloting roll (at -1) in the strange gravity." % [
				c.gravity, c.gravity])
	if c.wind:
		out.append("Wind: +1 to every piloting roll outside buildings. A 'Mech that jumps rolls at +1 on landing and falls a level if it fails. Smoke and fog are blown away.")
	if c.low_visibility:
		out.append("Low visibility: +1 to every ranged attack. At the start of each Weapon Attack Phase every 'Mech makes a sensor check (its piloting skill); passing it removes the +1 for that turn.")
	if c.rain:
		out.append("Rain: every hex but water, pavement and buildings is mud; a running 'Mech that turns in mud must roll (at -1) or fall. Nothing can be set on fire.")
	if c.snowfall:
		out.append("Snowfall: deep snow everywhere but water. Ending a move in snow sheds 1 extra heat per leg (4 lying down), but a 'Mech that falls next to a slope may start an avalanche.")
	if c.cold > 0:
		out.append("The cold freezes every water hex: 'Mechs walk on the ice, and any piloting roll made on ice is +1.")
	if c.heat > 0:
		out.append("The heat dries up all water: lakes become dry sinkholes.")
	if c.night:
		out.append("Night: 'Mech sensors see heat and low light, so darkness doesn't change how 'Mechs fight.")
	return out


## Log line for a sensor check.
static func sensor_check(s: GameState, d: Dictionary, level: int) -> String:
	if level == ExplainLevel.OFF:
		return ""
	var who := Names.unit(s.unit_by_id(d["unit_id"]))
	var t := "%s sensor check (%s): %d vs %d+: %s" % [who, d["why"], d["roll"], d["need"],
			"sees through it" if d["ok"] else "still blind"]
	if level == ExplainLevel.FULL:
		t += ". Passing ignores the +1 for low visibility on this turn's shots; failing never makes a 'Mech fall" \
				if d["why"] == "low visibility" else ""
	return t + "."


## Extra words for a Heat Phase line when the temperature moved the heat.
static func heat_note(weather: int) -> String:
	if weather > 0:
		return ", +%d from the heat outside" % weather
	if weather < 0:
		return ", -%d from the cold outside" % -weather
	return ""
