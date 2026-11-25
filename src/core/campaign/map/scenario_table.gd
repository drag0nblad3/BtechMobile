class_name ScenarioTable
extends RefCounted
## Who attacks and which scenario two meeting lances fight (Campaign
## Operations pp. 149-150). Attack beats anything; Scout attacks a Defend
## or non-combat order; other pairings are rolled. The Scenario Type table
## uses its Scout column if either side scouts, with the book's modifiers.

const NAMES := {"extraction": "Extraction", "hold_the_line": "Hold the Line", "standup": "Stand-Up Fight",
	"hide_and_seek": "Hide and Seek", "breakthrough": "Breakthrough", "probe": "Probe", "recon_raid": "Recon Raid"}


## The attacking lance of the two.
static func attacker(a: MapLance, b: MapLance, dice: Dice) -> MapLance:
	for pair in [[a, b], [b, a]]:
		var x: MapLance = pair[0]
		var y: MapLance = pair[1]
		if x.order == MapLance.ATTACK and y.order != MapLance.ATTACK:
			return x
		if y.order == MapLance.DEFEND and x.order != MapLance.DEFEND:
			return x
		if x.order == MapLance.SCOUT and not MapLance.COMBAT.has(y.order):
			return x
	return a if dice.d6() <= 3 else b


## {scenario, roll, column} for lances `a` and `b`.
static func roll(a: MapLance, b: MapLance, dice: Dice, rules: Dictionary) -> Dictionary:
	var scout := a.order == MapLance.SCOUT or b.order == MapLance.SCOUT
	var orders := [a.order, b.order]
	var calm := func(o: String) -> bool: return not MapLance.COMBAT.has(o)
	var mod := 0
	if scout:
		if orders.has(MapLance.ATTACK):
			mod -= 3
		elif orders.count(MapLance.SCOUT) == 2:
			mod += 1
		elif orders.any(calm):
			mod += 3
	else:
		if orders.count(MapLance.ATTACK) == 2:
			mod += 1
		elif orders.has(MapLance.ATTACK) and orders.any(calm):
			mod += 3
	var col: Array = rules.get("scenario_table", {}).get("scout" if scout else "battle", [])
	var r := dice.d6()
	var i := clampi(r + mod, 1, col.size()) - 1
	return {"scenario": String(col[i]) if not col.is_empty() else "standup", "roll": r, "mod": mod,
		"column": "scout" if scout else "battle"}


static func mission_for(scenario: String, rules: Dictionary) -> String:
	return String(rules.get("scenario_missions", {}).get(scenario, ""))


static func name_of(scenario: String) -> String:
	return NAMES.get(scenario, scenario.capitalize())
