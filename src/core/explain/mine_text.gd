class_name MineText
extends RefCounted
## Log text for minefields (Minefields).


static func describe(s: GameState, d: Dictionary, level: int) -> String:
	var where := Hex.label(d["coord"])
	match d["kind"]:
		"laid":
			return "  A %s minefield (%d damage groups) now covers %s." % [
					Minefields.NAMES[int(d["density"])], d["groups"], where]
		"triggered":
			var who := Names.unit(s.unit_by_id(int(d["unit_id"])))
			var t := "  %s sets off a minefield at %s: %d vs %d+, %s" % [who, where, d["roll"], d["need"],
					"%d groups of %d damage on the legs" % [d["groups"], Minefields.GROUP] if d["hit"] else "the mines don't go off"]
			if level == ExplainLevel.FULL:
				t += ". Each time a field goes off it loses a group; jumping over a field is safe, landing in it isn't" if d["hit"] \
						else ". The field stays live for the next 'Mech"
			return t + "."
		"cleared":
			return "  The artillery blast clears the minefield at %s (%d vs %d+)." % [where, d["roll"], d["need"]]
		"survived":
			return "  The mines at %s survive the blast (%d vs %d+)." % [where, d["roll"], d["need"]] if level != ExplainLevel.OFF else ""
	return ""
