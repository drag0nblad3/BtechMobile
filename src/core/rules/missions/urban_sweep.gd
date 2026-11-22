class_name UrbanSweep
extends RefCounted
## Urban Sweep setup (book p. 218): six intel counters, each in its own
## building hex at least 4 hexes from both home edges, spread out. Where
## the map has too few buildings, a medium building is put up for the counter.
## TODO(rules): players take turns placing counters; we spread them evenly.

const COUNTERS := 6
const EDGE_GAP := 4


static func place(m: Mission, map: BattleMap) -> void:
	var band: Array[Vector2i] = []
	for c: Vector2i in map.coords():
		var row := Hex.to_offset(c).y
		var t := map.get_tile(c)
		if row >= EDGE_GAP and row <= map.height - 1 - EDGE_GAP and not t.is_water():
			band.append(c)
	var picks := _spread(band.filter(func(c: Vector2i) -> bool: return map.get_tile(c).building != null), [])
	if picks.size() < COUNTERS:
		var medium: BuildingType = TerrainDb.load_file().buildings.get("medium")
		for c in _spread(band.filter(func(c: Vector2i) -> bool: return map.get_tile(c).building == null), picks):
			map.get_tile(c).building = Building.new(medium, 1)
			picks.append(c)
	for c in picks:
		var o := Objective.make(c, 0, -1, 0)
		o.kind = "intel"
		m.objectives.append(o)


## Up to COUNTERS hexes from `pool`, each as far as possible from the ones
## already chosen (`taken` plus earlier picks).
static func _spread(pool: Array, taken: Array[Vector2i]) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var chosen: Array[Vector2i] = taken.duplicate()
	while out.size() + taken.size() < COUNTERS and not pool.is_empty():
		var best: Vector2i = pool[0]
		var best_d := -1
		for c: Vector2i in pool:
			var d := 1000
			for o in chosen:
				d = mini(d, Hex.distance(c, o))
			if d > best_d:
				best = c
				best_d = d
		out.append(best)
		chosen.append(best)
		pool.erase(best)
	return out
