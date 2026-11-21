class_name StandardMissions
extends RefCounted
## The book's Standard Missions (pp. 212-218), built for one of our maps.
## Names, goals and limits live in data/missions/standard.json; this sets up
## sides, objectives, deployment zones and complications. The book assumes
## two mapsheets side by side; on our single sheet hex 1509 is the middle
## of the map and placements keep their distance from the home edges.
## Side 0 deploys from the south edge, side 1 from the north (the attacker,
## where a mission has one, is rolled).

const PATH := "res://data/missions/standard.json"


static func all() -> Array:
	return JsonFile.read(PATH)["missions"]


static func info(id: String) -> Dictionary:
	for m: Dictionary in all():
		if m["id"] == id:
			return m
	return {}


static func available_ids() -> Array[String]:
	var out: Array[String] = []
	for m: Dictionary in all():
		if m.get("available", false):
			out.append(m["id"])
	return out


## Standard Mission Table: first 1D6 picks the band (1-3 / 4-6), second the
## mission. TODO(rules): missions not in the game yet are rerolled.
static func roll(dice: Dice) -> String:
	for i in 30:
		var band := 0 if dice.d6() <= 3 else 1
		var pick := dice.d6()
		for m: Dictionary in all():
			if int(m["table"][0]) == band and int(m["table"][1]) == pick and m.get("available", false):
				return m["id"]
	return "annihilation"


## {mission: Mission, zones: [side 0 zones, side 1 zones], conditions: Conditions or null,
##  notes: [String], attacker: side or -1}
static func setup(id: String, map: BattleMap, dice: Dice, forced_withdrawal := false) -> Dictionary:
	var d := info(id)
	assert(not d.is_empty(), "Unknown mission %s" % id)
	var md := d.duplicate()
	md["forced_withdrawal"] = forced_withdrawal
	var mission := Mission.from_dict(md)
	var out := {"mission": mission, "conditions": null, "notes": [], "attacker": -1,
			"zones": [[{"edge": "south", "depth": 1}], [{"edge": "north", "depth": 1}]]}
	MissionLayouts.apply(String(d.get("setup", "")), out, map, dice)
	var comps := Complications.roll(dice, d.get("complications", "restricted"), d.get("no_random_duration", false))
	for c in comps:
		_complicate(c, out, dice)
		out["notes"].append("Complication: " + String(Complications.NAMES.get(c, c)))
	mission.notes = out["notes"]
	return out


static func _complicate(c: String, out: Dictionary, dice: Dice) -> void:
	match c:
		"random_duration":
			out["mission"].random_duration = true
		"conditions":
			out["conditions"] = ConditionsTable.roll(dice)
		"knife_fight":
			for zones: Array in out["zones"]:
				for z: Dictionary in zones:
					if z.has("edge"):
						z["depth"] = int(z.get("depth", 1)) + 4
						if z.has("to_depth"):
							z["to_depth"] = int(z["to_depth"]) + 4
