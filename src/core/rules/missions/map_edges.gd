class_name MapEdges
extends RefCounted
## Battlefield edges by name: "north" (row 01), "south" (last row), "west"
## (column 01), "east" (last column). Distances are counted in hexes.
## "west|east" names two edges at once (the nearer one counts).

const OPPOSITE := {"north": "south", "south": "north", "west": "east", "east": "west"}


## Hexes from `c` to the edge (0 = on it).
static func distance(map: BattleMap, c: Vector2i, edge: String) -> int:
	if edge.contains("|"):
		var best := 1 << 20
		for e in edge.split("|"):
			best = mini(best, distance(map, c, e))
		return best
	var o := Hex.to_offset(c)
	match edge:
		"north":
			return o.y
		"south":
			return map.height - 1 - o.y
		"west":
			return o.x
		"east":
			return map.width - 1 - o.x
	return 0


static func on_edge(map: BattleMap, c: Vector2i, edge: String) -> bool:
	return distance(map, c, edge) == 0
