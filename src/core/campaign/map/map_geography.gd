class_name MapGeography
extends RefCounted
## Regional geography is deterministic and independent of tactical dice.
## Roads are cartographic links, not new movement rules.


static func battle_seed(r: MapRegion, z: Vector2i) -> int:
	return maxi(1, int(hash([r.geography_seed, z.x, z.y])) & 0x7fffffff)


static func shape(r: MapRegion) -> void:
	var fixed := {}
	var river := Vector2i(-1, -1)
	for loc in r.locations:
		fixed[loc["zone"]] = true
		if loc["kind"] == "bridge":
			river = loc["zone"]
	# Cluster neighboring biomes, keeping every key location's terrain.
	for pass_index in 2:
		var before := r.terrain.duplicate()
		for y in r.height:
			for x in r.width:
				var z := Vector2i(x, y)
				if fixed.has(z):
					continue
				var counts := {}
				for n in r.neighbors(z):
					var t: String = before[n.y * r.width + n.x]
					if t in ["plains", "woods", "hills", "badlands", "lakes"]:
						counts[t] = int(counts.get(t, 0)) + 1
				var best: String = before[y * r.width + x]
				var score := 1
				for t: String in counts:
					if int(counts[t]) > score:
						best = t
						score = counts[t]
				r.terrain[y * r.width + x] = best
	# Connect the bridge to a north/south watercourse. Settlements retain
	# their battle theme even where a river crosses the same zone.
	if r.has_zone(river):
		for end in [Vector2i(river.x, 0), Vector2i(river.x, r.height - 1)]:
			for z in route(r, river, end):
				if not fixed.has(z):
					r.terrain[z.y * r.width + z.x] = "river"


static func route(r: MapRegion, a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if not r.has_zone(a) or not r.has_zone(b):
		return out
	out.append(a)
	while a != b:
		var n := r.step_toward(a, b)
		if n == a:
			break
		out.append(n)
		a = n
	return out


## Connect landmarks with a small spanning tree instead of all pairs.
static func roads(r: MapRegion) -> Array:
	var out := []
	if r.locations.is_empty():
		return out
	var connected: Array[Vector2i] = [r.locations[0]["zone"]]
	var left: Array[Vector2i] = []
	for i in range(1, r.locations.size()):
		left.append(r.locations[i]["zone"])
	while not left.is_empty():
		var distance := 1 << 20
		var a := connected[0]
		var b := left[0]
		for from in connected:
			for to in left:
				var d := r.distance(from, to)
				if d < distance:
					a = from
					b = to
					distance = d
		out.append(route(r, a, b))
		left.erase(b)
		connected.append(b)
	return out
