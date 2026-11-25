class_name MapRegionGen
extends RefCounted
## Builds a campaign map from data/campaign/map_campaign.json: weighted
## random terrain per zone, then the key locations (capital in the north,
## the rest scattered, none on the south landing row), each held by side 1.
## TODO(rules): the book has the GM draw the map; sizes and counts are ours.


static func generate(rules: Dictionary, rng: RandomNumberGenerator) -> MapRegion:
	var r := MapRegion.new()
	r.width = int(rules.get("width", 8))
	r.height = int(rules.get("height", 6))
	var terrains: Dictionary = rules.get("terrains", {})
	for i in r.width * r.height:
		r.terrain.append(_weighted(terrains, rng))
	var names: Array = rules.get("town_names", []).duplicate()
	var taken := {}
	for kind: String in rules.get("locations", {}):
		var info: Dictionary = rules["locations"][kind]
		for n in int(info.get("count", 1)):
			var z := _spot(r, kind, taken, rng)
			taken[z] = true
			if info.has("terrain"):
				r.terrain[z.y * r.width + z.x] = String(info["terrain"])
			var town := String(names.pop_front()) if not names.is_empty() else String(info["name"])
			r.locations.append({"id": "%s%d" % [kind, n + 1], "kind": kind,
				"name": town if kind in ["capital", "city"] else "%s %s" % [town, info["name"]],
				"zone": z, "points": int(info["points"]), "benefit": String(info.get("benefit", "")), "owner": 1})
	return r


## A free zone: the capital in the two northern rows, others anywhere but
## the southern landing row, never next to another location if avoidable.
static func _spot(r: MapRegion, kind: String, taken: Dictionary, rng: RandomNumberGenerator) -> Vector2i:
	var rows := 2 if kind == "capital" else r.height - 1
	for attempt in 200:
		var z := Vector2i(rng.randi_range(0, r.width - 1), rng.randi_range(0, rows - 1))
		if taken.has(z):
			continue
		if attempt < 100 and r.neighbors(z).any(func(n: Vector2i) -> bool: return taken.has(n)):
			continue
		return z
	for i in r.width * (r.height - 1):
		var z := Vector2i(i % r.width, i / r.width)
		if not taken.has(z):
			return z
	return Vector2i.ZERO


static func _weighted(terrains: Dictionary, rng: RandomNumberGenerator) -> String:
	var total := 0
	for t: String in terrains:
		total += int(terrains[t].get("weight", 1))
	var pick := rng.randi_range(1, maxi(1, total))
	for t: String in terrains:
		pick -= int(terrains[t].get("weight", 1))
		if pick <= 0:
			return t
	return "plains"
