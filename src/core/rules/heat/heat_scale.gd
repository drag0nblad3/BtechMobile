class_name HeatScale
extends RefCounted
## Effects of a 'Mech's current heat level (the heat scale on a record sheet).
## Thresholds checked against the book's heat data table.

const MAX_HEAT := 30


## Walking MP lost: -1 at 5+, -2 at 10+, -3 at 15+, -4 at 20+, -5 at 25+.
static func mp_penalty(heat: int) -> int:
	return clampi(heat / 5, 0, 5)


static func to_hit_penalty(heat: int) -> int:
	if heat >= 24:
		return 4
	if heat >= 17:
		return 3
	if heat >= 13:
		return 2
	if heat >= 8:
		return 1
	return 0


## 2d6 needed to avoid shutting down; 0 = no roll, 99 = automatic shutdown.
static func shutdown_avoid(heat: int) -> int:
	if heat >= 30:
		return 99
	if heat >= 26:
		return 10
	if heat >= 22:
		return 8
	if heat >= 18:
		return 6
	if heat >= 14:
		return 4
	return 0


## 2d6 needed to avoid an ammunition explosion; 0 = no roll.
static func ammo_explosion_avoid(heat: int) -> int:
	if heat >= 28:
		return 8
	if heat >= 23:
		return 6
	if heat >= 19:
		return 4
	return 0


## Short description of what this heat level does (record sheet / tips).
static func effects_text(heat: int, c: Conditions = null) -> String:
	var parts: Array[String] = []
	if mp_penalty(heat) > 0:
		parts.append("-%d MP" % mp_penalty(heat))
	if to_hit_penalty(heat) > 0:
		parts.append("+%d to hit" % to_hit_penalty(heat))
	var sd := shutdown_avoid(heat) if c == null else ExtremeTemp.avoid(shutdown_avoid(heat), c)
	if sd == 99:
		parts.append("shuts down")
	elif sd > 0:
		parts.append("shutdown unless %d+" % sd)
	var ae := ammo_explosion_avoid(heat) if c == null else ExtremeTemp.avoid(ammo_explosion_avoid(heat), c)
	if ae == 99:
		parts.append("ammo explodes")
	elif ae > 0:
		parts.append("ammo explodes unless %d+" % ae)
	return ", ".join(parts) if not parts.is_empty() else "no effect"
