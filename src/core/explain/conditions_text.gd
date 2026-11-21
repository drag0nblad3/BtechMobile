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
	if c.night:
		out.append("Night: 'Mech sensors see heat and low light, so darkness doesn't change how 'Mechs fight.")
	return out


## Extra words for a Heat Phase line when the temperature moved the heat.
static func heat_note(weather: int) -> String:
	if weather > 0:
		return ", +%d from the heat outside" % weather
	if weather < 0:
		return ", -%d from the cold outside" % -weather
	return ""
