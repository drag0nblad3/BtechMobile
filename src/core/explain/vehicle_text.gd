class_name VehicleText
extends RefCounted
## Log text for combat vehicles: hits by location, motive damage and
## critical hits. Our own wording.

const EFFECTS := {"driver": "the driver is hurt (+2 to driving)", "commander": "the commander is hurt (+1 to its rolls)",
		"crew_stunned": "the crew is stunned and loses its next turn", "stabilizer": "a weapon stabilizer is hit (+1 to fire from there)",
		"sensors": "its sensors are hit (+1 to its shots)", "turret_locked": "the turret locks in place",
		"turret_off": "the turret is blown off", "engine": "the engine is hit: it can't move",
		"fuel": "the fuel tank explodes", "ammo": "its ammunition explodes", "crew_killed": "the crew is killed",
		"none": "nothing vital is hit"}
const MOTIVE := {"none": "no effect", "minor": "minor damage (+1 to driving)",
		"moderate": "moderate damage (-1 Cruising MP)", "heavy": "heavy damage (Cruising MP halved)",
		"major": "major damage: it's stuck where it is"}


static func damage(s: GameState, d: Dictionary, level: int) -> String:
	var u := s.unit_by_id(d["unit_id"])
	var t := "  %s takes %d on its %s (armor %d, structure %d left)" % [Names.unit(u), d["amount"],
			VehicleLoc.name_of(d["loc"]).to_lower(), d["armor_left"], d["structure_left"]]
	if level == ExplainLevel.FULL:
		t += ". Vehicles have no damage transfer: losing a location's structure destroys them, except the turret."
	return t


static func event(s: GameState, d: Dictionary, level: int) -> String:
	var who := Names.unit(s.unit_by_id(d["unit_id"]))
	if d["kind"] == "motive":
		var t := "  %s's motive system: %d%+d, %s." % [who, d["roll"], d["mod"], MOTIVE[d["effect"]]]
		if level == ExplainLevel.FULL:
			t += " Hits from the sides and rear, and on wheels or hover skirts, do more harm."
		return t
	var effect: String = d["effect"]
	var parts := effect.split(":")
	var what: String = EFFECTS.get(parts[0], parts[0])
	if parts.size() > 1:
		what = "its %s is %s" % [parts[1], "destroyed" if parts[0] == "weapon" else "jammed for the rest of the game"]
	return "  Critical hit on %s's %s (%d): %s." % [who, VehicleLoc.name_of(d["loc"]).to_lower(), d["roll"], what]
