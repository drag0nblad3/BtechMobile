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
	var mp := tile.terrain.move_cost + (0 if not tile.is_water() else (1 if tile.depth == 1 else 2))
	if mp > 0:
		parts.append("+%d MP to enter" % mp)
	var cover := LineOfSight.woods_value(tile)
	if cover > 0:
		parts.append("+%d to hit a 'Mech here" % cover)
	if tile.is_water():
		parts.append("plus %d level%s down to the bottom" % [tile.depth, "" if tile.depth == 1 else "s"])
		parts.append("running in needs a piloting roll")
		if tile.depth >= 2:
			parts.append("can't be targeted fully under water")
		parts.append("heat sinks under water cool double (%s, up to +6)" % (
				"only leg sinks while standing" if tile.depth == 1 else "all of them"))
		if tile.depth == 1:
			parts.append("partial cover: +1, leg hits absorbed")
	if parts.is_empty():
		return t + (": open ground" if level == ExplainLevel.LIGHT else ": open ground. No cover, but nothing slows you down.")
	t += ": " + ", ".join(parts)
	if level == ExplainLevel.FULL and cover > 0:
		t += ". Woods also block line of sight once 3 points lie between two 'Mechs."
	return t


static func _building(b: Building, level: int) -> String:
	var lv := "%d level%s tall" % [b.height, "" if b.height == 1 else "s"]
	if b.type.civilian:
		var c := "%s, %s: +1 MP to enter" % [b.type.name, lv]
		if level == ExplainLevel.FULL:
			c += ". It blocks line of sight, but any hit or any 'Mech walking in flattens it."
		return c
	var t := "%s, %s: +1 MP to enter, threshold %d, destroy on %d+" % [b.type.name, lv,
			b.type.threshold, b.type.destroy_tn]
	if level == ExplainLevel.FULL:
		t += ". Only %s 'Mechs or heavier can force their way in, with a piloting roll at +1; failing risks bringing it down on you. " % [
				["light", "medium", "heavy", "assault"][b.type.entry_class]] \
				+ ("Inside, you are +2 to hit. " if b.height >= 2 else "Standing in it gives partial cover: hits on your legs strike the walls. ") \
				+ "If it collapses, a 'Mech inside takes %d per level above it. It blocks line of sight like a hill %s." % [
				b.collapse_damage(b.height - 1), lv]
	return t


## Log line for a GameEvent.BUILDING.
static func building_event(s: GameState, d: Dictionary, level: int) -> String:
	var where := Hex.label(d["coord"])
	var u := s.unit_by_id(int(d.get("unit_id", -1)))
	var who := Names.unit(u) if u != null else "Someone"
	var bname := String(d["name"]).to_lower()
	match d["kind"]:
		"flattened":
			return "%s walks straight through the %s at %s, flattening it." % [who, bname, where]
		"entry_failed":
			var t := "  %s smashes through the walls clumsily." % who
			if level == ExplainLevel.FULL:
				t += " A failed entry roll doesn't knock you down, but it may bring the building down."
			return t
		"roof":
			var t := "  %s lands on the roof of the %s at %s." % [who, bname, where]
			if d.get("over", false):
				t += " It is too heavy for that roof."
			if level == ExplainLevel.FULL:
				t += " Up here it sees and shoots from higher ground, but it can only leave by jumping or crossing to another roof, and a roof too weak for it may give way."
			return t
		"careful":
			var t := "  %s eases into the %s at %s." % [who, bname, where]
			if level == ExplainLevel.FULL:
				t += " Running straight into a building as your whole move is careful entry: no roll, and any 'Mech can do it."
			return t
		"shoved_in":
			var t := "  %s is driven through the walls of the %s at %s." % [who, bname, where]
			if level == ExplainLevel.FULL:
				t += " Being shoved into a building always gets you in, but the impact may bring it down."
			return t
		"destroy_check":
			if level == ExplainLevel.OFF:
				return ""
			var mod := " +%d for %d damage" % [d["mod"], d["damage"]] if int(d["mod"]) > 0 else ""
			return "  Destroy check on the %s at %s: rolled %d%s, needs %d: %s." % [bname, where,
					d["roll"], mod, d["need"], "it is coming down" if d["destroyed"] else "it holds"]
		"shot":
			if level == ExplainLevel.OFF:
				return ""
			var t := "  The %s at %s takes %d damage." % [bname, where, d["damage"]]
			if level == ExplainLevel.FULL:
				t += " Enough damage from one 'Mech in a phase earns a roll to bring it down."
			return t
		"cover_hit":
			if level == ExplainLevel.OFF:
				return ""
			return "  The walls around %s take %d damage instead of its legs." % [who, d["damage"]]
		"collapsed":
			var t := "The %s at %s collapses!" % [bname, where]
			if int(d.get("damage", 0)) > 0 and u != null:
				t += " %s is buried under it for %d damage." % [who, d["damage"]]
			return t
	return ""
