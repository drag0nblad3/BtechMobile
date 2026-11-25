class_name GenRiver
extends RefCounted
## A river from one map edge to the opposite one, following low ground.
## Its surface never climbs downstream, so it cuts a gully through any
## rise it has to cross. Mostly Depth 1, with deeper pools if it is wide.


static func apply(g: GenGrid, t: MapTheme, rng: RandomNumberGenerator, seed_value: int, fords := false) -> void:
	if rng.randf() >= t.river_chance:
		return
	var side: String = ["left", "top", "right", "bottom"][rng.randi_range(0, 3)]
	var edge := GenPath.edge(g, side)
	var lo := int(edge.size() * 0.2)
	var start: int = edge[rng.randi_range(lo, edge.size() - 1 - lo)]
	var goal_side := GenPath.opposite(side)
	var jitter := GenNoise.field(g, seed_value + 17, 0.35, 2)
	var path := GenPath.find(g, [start], func(i: int) -> bool: return _on_edge(g, i, goal_side),
			func(_a: int, b: int) -> int: return 2 + 4 * g.level[b] + int((jitter[b] + 1.0) * 2.0))
	var river := {}
	var surface := 99
	var bank := rng.randi_range(0, 5)
	for i: int in path:
		surface = mini(surface, g.level[i])
		var deep := t.river_width > 1 and rng.randf() < 0.3
		g.make_water(i, surface, 2 if deep else 1)
		river[i] = true
		if t.river_width > 1:
			var nb := g.neighbors(i)
			var j: int = nb[bank % nb.size()]
			if not g.is_water(j):
				g.make_water(j, surface, 1)
				river[j] = true
		if rng.randf() < 0.15:
			bank = rng.randi_range(0, 5)

	if fords and path.size() >= 6:
		# Two spaced shallow crossings, only on the river's own footprint.
		# Keep deep pools elsewhere and let normal roads/bridges follow.
		for frac in [0.33, 0.67]:
			var i: int = path[clampi(roundi((path.size() - 1) * frac), 1, path.size() - 2)]
			_ford(g, river, i)


static func _ford(g: GenGrid, river: Dictionary, i: int) -> void:
	var crossing := [i]
	for n in g.neighbors(i):
		if river.has(n):
			crossing.append(n)
	for c: int in crossing:
		g.depth[c] = 1
		for n in g.neighbors(c):
			if not g.is_water(n):
				# A Depth 1 ford needs its dry banks within two levels of the
				# bottom, not simply within two levels of the water surface.
				g.level[n] = clampi(g.level[n], g.level[c] - 3, g.level[c] + 1)


static func _on_edge(g: GenGrid, i: int, side: String) -> bool:
	match side:
		"top":
			return g.row_of(i) == 0
		"bottom":
			return g.row_of(i) == g.h - 1
		"left":
			return g.col_of(i) == 0
	return g.col_of(i) == g.w - 1
