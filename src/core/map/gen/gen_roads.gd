class_name GenRoads
extends RefCounted
## Paved roads from edge to edge. A road avoids climbing and water; where
## it must cross a river it fords it as a paved causeway at the water's
## surface, since the game has no bridges yet. Roads join where they meet.

const CLIMB := 5     ## Cost per level of climb or descent.
const WET := 14      ## Extra cost to pave a water hex, plus 6 per depth.


static func apply(g: GenGrid, t: MapTheme, rng: RandomNumberGenerator) -> void:
	for k in t.roads:
		var side: String = ["left", "top"][k % 2] if rng.randf() < 0.7 else ["right", "bottom"][k % 2]
		var edge := GenPath.edge(g, side).filter(func(i: int) -> bool: return not g.is_water(i))
		if edge.is_empty():
			continue
		var lo := int(edge.size() * 0.15)
		var start: int = edge[rng.randi_range(lo, edge.size() - 1 - lo)]
		var goal := GenPath.opposite(side)
		var goal_hexes := {}
		for i: int in GenPath.edge(g, goal):
			goal_hexes[i] = true
		pave(g, GenPath.find(g, [start], func(i: int) -> bool: return goal_hexes.has(i),
				func(a: int, b: int) -> int: return step_cost(g, a, b)))


static func step_cost(g: GenGrid, a: int, b: int) -> int:
	if g.token[b] == "p":
		return 1
	var climb := absi(g.level[b] - g.level[a])
	if climb > GenElevation.MAX_STEP:
		return 200
	var c := 3 + CLIMB * climb
	if g.is_water(b):
		c += WET + 6 * g.depth[b]
	return c


static func pave(g: GenGrid, path: Array) -> void:
	for i: int in path:
		g.token[i] = "p"
		g.depth[i] = 0
		g.buildings.erase(i)

