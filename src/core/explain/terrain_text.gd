class_name TerrainText
extends RefCounted
## What a hex does to movement, cover and line of sight, for the hex info line.


static func describe(tile: MapTile, level: int) -> String:
	if tile == null or level == ExplainLevel.OFF:
		return ""
	var t := "%s %s, level %d" % [Hex.label(tile.coord), tile.terrain.name, tile.level]
	if tile.is_water():
		t += ", depth %d" % tile.depth
	if tile.building != null:
		return t + ": " + _building(tile.building, level)
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


static func _building(b: Building, level: int) -> String:
	var t := "%s, %d level%s tall, %d/%d CF: +%d MP to enter" % [b.type.name, b.height,
			"" if b.height == 1 else "s", b.cf, b.type.cf, b.type.move_cost]
	if level == ExplainLevel.FULL:
		t += ". Entering takes a piloting roll (+%d); a 'Mech over %d tons brings it down. " % [
				b.type.psr_mod, b.cf] \
				+ "Inside, the walls soak %d damage from every hit. It blocks line of sight like a hill %d level%s high." % [
				b.absorbs(), b.height, "" if b.height == 1 else "s"]
	return t


## Log line for a GameEvent.BUILDING.
static func building_event(s: GameState, d: Dictionary, level: int) -> String:
	var where := Hex.label(d["coord"])
	var who := Names.unit(s.unit_by_id(d["unit_id"])) if d.has("unit_id") else ""
	match d["kind"]:
		"overweight":
			var t := "%s crashes through the %s at %s." % [who, String(d["name"]).to_lower(), where]
			if level == ExplainLevel.FULL:
				t += " At %d tons it is heavier than the %d CF the building had left, so it stops there and the building comes down." % [
						s.unit_by_id(d["unit_id"]).def.tonnage, d["cf"]]
			return t
		"scraped":
			return "  %s scrapes through the walls and takes %d damage." % [who, d["damage"]]
		"absorbed":
			if level == ExplainLevel.OFF:
				return ""
			var t := "  The building at %s soaks %d of %d damage (CF left %d)." % [where, d["absorbed"], d["damage"], d["cf"]]
			if level == ExplainLevel.FULL:
				t += " Fighting from inside a building trades its walls for your armor."
			return t
		"shot":
			var t := "  The %s at %s takes %d damage (CF left %d)." % [String(d["name"]).to_lower(), where, d["damage"], d["cf"]]
			if level == ExplainLevel.FULL:
				t += " Bringing it down drops anyone inside and opens the line of sight."
			return t
		"collapsed":
			return "The %s at %s collapses into rubble!" % [String(d["name"]).to_lower(), where]
	return ""
