class_name Complications
extends RefCounted
## Mission complications (book p. 213). Master table (2D6): 3 Knife-Fight,
## 4 Edge, 5 Edge: Commanders, 6 Random Duration, 7 Battlefield Conditions,
## 8 ECM Interference, 9 Fog of War, 10 Thicker Fog, 11 Waves, 2 and 12
## nothing. Restricted table (1D6): 1 nothing, 2 Edge, 3 Edge: Commanders,
## 4 Random Duration, 5 Battlefield Conditions, 6 ECM Interference.
## Annihilation rolls once on the master table, then a second time on a 4+.
## Fog of War and Thicker Fog hide where forces deploy; both sides deploy at
## once here, so they change nothing.
## TODO(rules): Edge isn't in the game yet; those results are rerolled (as
## is Random Duration where a mission forbids it).

const MASTER := {3: "knife_fight", 4: "edge", 5: "edge_commanders", 6: "random_duration",
		7: "conditions", 8: "ecm", 9: "fog_of_war", 10: "thicker_fog", 11: "waves"}
const RESTRICTED := {2: "edge", 3: "edge_commanders", 4: "random_duration", 5: "conditions", 6: "ecm"}
const SUPPORTED := ["", "knife_fight", "random_duration", "conditions", "ecm", "fog_of_war", "thicker_fog", "waves"]
const NAMES := {"": "none", "knife_fight": "Knife-Fight (both sides deploy 4 hexes closer)",
		"random_duration": "Random Duration (the battle may end from turn 7)",
		"conditions": "Battlefield Conditions",
		"ecm": "ECM Interference (Artemis needs a sensor check each turn)",
		"fog_of_war": "Fog of War (deployment is hidden; both sides deploy at once)",
		"thicker_fog": "Thicker Fog (decoy blips; both sides deploy at once)",
		"waves": "Waves (half of each force arrives from turn 2)"}


## Complication ids for a mission: `table` is "master", "restricted" or "annihilation".
static func roll(dice: Dice, table: String, no_random_duration: bool) -> Array[String]:
	var out: Array[String] = []
	var first := _one(dice, table, no_random_duration, out)
	out.append(first)
	if table == "annihilation" and dice.d6() >= 4:
		out.append(_one(dice, table, no_random_duration, out))
	return out.filter(func(c: String) -> bool: return c != "")


static func _one(dice: Dice, table: String, no_rd: bool, have: Array[String]) -> String:
	for i in 20:
		var c := ""
		if table == "restricted":
			c = RESTRICTED.get(dice.d6(), "")
		else:
			c = MASTER.get(dice.roll_2d6(), "")
		if not SUPPORTED.has(c) or (no_rd and c == "random_duration") or (c != "" and have.has(c)):
			continue
		return c
	return ""
