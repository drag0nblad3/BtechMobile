class_name MapGeography
extends RefCounted
## Procedural campaign cartography; terrain has no new movement modifiers.


static func connect_river(r: MapRegion) -> void:
	for loc in r.locations:
		if loc["kind"] != "bridge":
			continue
		var bridge: Vector2i = loc["zone"]
		for end in [Vector2i(bridge.x, 0), Vector2i(bridge.x, r.height - 1)]:
			var z := bridge
			while z != end:
				z = r.step_toward(z, end)
				if r.location_at(z).is_empty():
					r.terrain[z.y * r.width + z.x] = "river"


static func route(r: MapRegion, from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if not r.has_zone(from) or not r.has_zone(to):
		return result
	result.append(from)
	while from != to:
		var next := r.step_toward(from, to)
		if next == from:
			break
		result.append(next)
		from = next
	return result


static func battle_seed(r: MapRegion, z: Vector2i) -> int:
	# Only immutable geography; ownership and reports must not affect it.
	return maxi(1, int(hash([r.width, r.height, Array(r.terrain), z])))


static func zone_label(r: MapRegion, z: Vector2i) -> String:
	var loc := r.location_at(z)
	return String(loc["name"]) if not loc.is_empty() else "%s %d,%d" % [r.terrain_at(z).capitalize(), z.x + 1, z.y + 1]
