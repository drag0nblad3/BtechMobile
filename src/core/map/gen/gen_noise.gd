class_name GenNoise
extends RefCounted
## Smooth random fields for the map generator, plus a helper that turns a
## field into exact terrain shares by rank (the top 15% of a field become
## woods, say), so a theme's densities hold whatever the noise does.


## One value per hex in about -1..1. The same seed gives the same field.
static func field(g: GenGrid, seed_value: int, frequency: float, octaves: int = 3) -> PackedFloat32Array:
	var n := FastNoiseLite.new()
	n.seed = seed_value
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = frequency
	n.fractal_type = FastNoiseLite.FRACTAL_FBM
	n.fractal_octaves = octaves
	var out := PackedFloat32Array()
	out.resize(g.size())
	for i in g.size():
		var p := g.world(i)
		out[i] = n.get_noise_2d(p.x, p.y)
	return out


## `candidates` sorted from the highest field value to the lowest.
static func ranked(values: PackedFloat32Array, candidates: Array) -> Array:
	var out := candidates.duplicate()
	out.sort_custom(func(a: int, b: int) -> bool:
		return values[a] > values[b] if values[a] != values[b] else a < b)
	return out


## The highest `share` of `candidates` (share 0..1, at least one if > 0).
static func top(values: PackedFloat32Array, candidates: Array, share: float) -> Array:
	if share <= 0.0 or candidates.is_empty():
		return []
	var n := clampi(int(round(candidates.size() * share)), 1, candidates.size())
	return ranked(values, candidates).slice(0, n)
