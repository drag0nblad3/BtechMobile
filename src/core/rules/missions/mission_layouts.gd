class_name MissionLayouts
extends RefCounted
## Per-mission setup for StandardMissions: who attacks, objectives and
## deployment zones, scaled to our single mapsheet (see StandardMissions).


static func apply(kind: String, out: Dictionary, map: BattleMap, dice: Dice) -> void:
	var m: Mission = out["mission"]
	var mid := Deployment.center(map)
	match kind:
		"ambush":
			var att := _attacker(out, dice)
			out["zones"][att] = [{"edge": "west", "depth": 1}, {"edge": "east", "depth": 1}]
			m.home_edges[att] = "west|east"
			m.initiative_side = att
			m.initiative_turns = 2
			out["notes"].append("%s ambushes from both flanks and wins initiative on turns 1 and 2." % Names.side(att))
		"annihilation":
			if dice.d6() >= 3:
				_short_edges(out, m)
				out["notes"].append("The forces meet from the short edges.")
		"short_edges":
			_short_edges(out, m)
		"dominate":
			var att := _attacker(out, dice)
			var dfd := 1 - att
			out["zones"][dfd] = [{"near": Hex.label(mid), "radius": 2}, out["zones"][dfd][0]]
			out["notes"].append("%s attacks; half of %s starts cut off around %s." % [
					Names.side(att), Names.side(dfd), Hex.label(mid)])
		"steel_rain":
			SteelRain.place(m, out, map, _attacker(out, dice), dice)
		"objective_raid":
			ObjectiveRaid.place(m, map, dice, out["notes"])
		"urban_sweep":
			UrbanSweep.place(m, map)
			out["notes"].append("Six buildings may hold intel: scan them from within 2 hexes.")
		"focal_point":
			m.objectives.append(Objective.make(mid, 2, -1, 3))
		"general_melee":
			out["zones"] = [[{"edge": "south", "depth": 6, "to_depth": 7}], [{"edge": "north", "depth": 6, "to_depth": 7}]]
		"control_the_field":
			var r := control_radius(dice.d6())
			for side in 2:
				var edge := m.home_edge(side)
				for frac in [0.25, 0.75]:
					m.objectives.append(Objective.make(_spot(map, edge, 4, frac), r, side, 1))
			out["notes"].append("Objective control radius: %d." % r)
		"hold_the_line":
			var r := control_radius(dice.d6())
			var chooser := dice.d6() % 2
			var e1 := m.home_edge(chooser)
			m.objectives.append(Objective.make(_spot(map, e1, 6, 0.15), r, -1, 1))
			m.objectives.append(Objective.make(_spot(map, m.home_edge(1 - chooser), 7, 0.5), r, -1, 1))
			m.objectives.append(Objective.make(_spot(map, e1, 6, 0.85), r, -1, 1))
			out["notes"].append("Objective control radius: %d." % r)


## Control radius roll used by several missions: 1-2 = 0, 3-5 = 1, 6 = 2.
static func control_radius(d6: int) -> int:
	return 0 if d6 <= 2 else (1 if d6 <= 5 else 2)


static func _attacker(out: Dictionary, dice: Dice) -> int:
	var att := 0 if dice.d6() <= 3 else 1
	out["attacker"] = att
	return att


static func _short_edges(out: Dictionary, m: Mission) -> void:
	out["zones"] = [[{"edge": "west", "depth": 1}], [{"edge": "east", "depth": 1}]]
	m.home_edges.assign(["west", "east"])


## A hex `depth` in from `edge`, `frac` of the way along it.
static func _spot(map: BattleMap, edge: String, depth: int, frac: float) -> Vector2i:
	var along := int(round(frac * ((map.height if edge in ["west", "east"] else map.width) - 1)))
	match edge:
		"north":
			return Hex.from_offset(Vector2i(along, depth))
		"south":
			return Hex.from_offset(Vector2i(along, map.height - 1 - depth))
		"west":
			return Hex.from_offset(Vector2i(depth, along))
	return Hex.from_offset(Vector2i(map.width - 1 - depth, along))
