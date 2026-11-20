class_name TerrainText
extends RefCounted
## What a hex does to movement, cover and line of sight, for the hex info line.


static func describe(tile: MapTile, level: int) -> String:
	if tile == null or level == ExplainLevel.OFF:
		return ""
	var t := "%s %s, level %d" % [Hex.label(tile.coord), tile.terrain.name, tile.level]
	if tile.is_water():
		t += ", depth %d" % tile.depth
	var parts: Array[String] = []
	var mp := tile.terrain.move_cost + (0 if not tile.is_water() else (1 if tile.depth == 1 else 3))
	if mp > 0:
		parts.append("+%d MP to enter" % mp)
	var cover := LineOfSight.woods_value(tile)
	if cover > 0:
		parts.append("+%d to hit a 'Mech here" % cover)
	if tile.is_water():
		parts.append("no running in" if tile.depth == 1 else "can't be targeted fully under water")
		parts.append("cools %d heat a turn" % HeatPhase.water_cooling(tile))
		if tile.depth == 1:
			parts.append("partial cover: +1, leg hits absorbed")
	if parts.is_empty():
		return t + (": open ground" if level == ExplainLevel.LIGHT else ": open ground. No cover, but nothing slows you down.")
	t += ": " + ", ".join(parts)
	if level == ExplainLevel.FULL and cover > 0:
		t += ". Woods also block line of sight once 3 points lie between two 'Mechs."
	return t
