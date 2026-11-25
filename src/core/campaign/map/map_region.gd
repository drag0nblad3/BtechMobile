class_name MapRegion
extends RefCounted
## The campaign map of a map-based campaign (Campaign Operations p. 143):
## a grid of Zones in offset coordinates (column, row), each one battlefield
## with a terrain, and the key locations fought over. Side 1 (the defender)
## starts holding every location; side 0 lands on the south edge.

var width := 8
var height := 6
var geography_seed := 0  ## Stable battle terrain, separate from the combat dice.
var terrain: Array[String] = []  ## Per zone, row by row.
## [{id, kind, name, zone: Vector2i, points, benefit, owner}]
var locations: Array[Dictionary] = []


func has_zone(z: Vector2i) -> bool:
	return z.x >= 0 and z.y >= 0 and z.x < width and z.y < height


func terrain_at(z: Vector2i) -> String:
	return terrain[z.y * width + z.x] if has_zone(z) else ""


## Zones apart (the map is laid out like a hex mapsheet).
func distance(a: Vector2i, b: Vector2i) -> int:
	return Hex.distance(Hex.from_offset(a), Hex.from_offset(b))


func neighbors(z: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for f in 6:
		var n := Hex.to_offset(Hex.neighbor(Hex.from_offset(z), f))
		if has_zone(n):
			out.append(n)
	return out


## The next zone on a shortest way from `from` toward `to`.
func step_toward(from: Vector2i, to: Vector2i) -> Vector2i:
	var best := from
	for n in neighbors(from):
		if distance(n, to) < distance(best, to):
			best = n
	return best


func location_at(z: Vector2i) -> Dictionary:
	for l in locations:
		if l["zone"] == z:
			return l
	return {}


func points(side: int) -> int:
	var n := 0
	for l in locations:
		if int(l["owner"]) == side:
			n += int(l["points"])
	return n


func total_points() -> int:
	return points(0) + points(1) + points(-1)


func to_dict() -> Dictionary:
	var locs := []
	for l in locations:
		var d := l.duplicate()
		d["zone"] = [l["zone"].x, l["zone"].y]
		locs.append(d)
	return {"width": width, "height": height, "terrain": Array(terrain), "locations": locs,
		"geography_seed": geography_seed}


static func from_dict(d: Dictionary) -> MapRegion:
	var r := MapRegion.new()
	r.width = int(d.get("width", 8))
	r.height = int(d.get("height", 6))
	for t in d.get("terrain", []):
		r.terrain.append(String(t))
	for l: Dictionary in d.get("locations", []):
		var c := l.duplicate()
		c["zone"] = Vector2i(int(l["zone"][0]), int(l["zone"][1]))
		c["points"] = int(l["points"])
		c["owner"] = int(l["owner"])
		r.locations.append(c)
	r.geography_seed = int(d.get("geography_seed", 0))
	if r.geography_seed == 0:
		r.geography_seed = maxi(1, int(hash([r.width, r.height, Array(r.terrain)])) & 0x7fffffff)
	return r
