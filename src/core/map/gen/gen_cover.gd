class_name GenCover
extends RefCounted
## Woods and rough ground on open dry hexes. Woods come in clumps from a
## noise field, with heavy woods at the clump cores; rough ground leans
## towards hilltops and slopes.


static func apply(g: GenGrid, t: MapTheme, seed_value: int) -> void:
	_woods(g, t, seed_value + 101)
	_rough(g, t, seed_value + 202)


static func _woods(g: GenGrid, t: MapTheme, seed_value: int) -> void:
	var f := GenNoise.field(g, seed_value, t.woods_scale, 2)
	var open := _open(g)
	if open.is_empty():
		return
	var share := minf(1.0, t.woods * g.size() / open.size())
	var woods := GenNoise.top(f, open, share)
	for i: int in woods:
		g.token[i] = "L"
	for i: int in GenNoise.top(f, woods, t.heavy):
		g.token[i] = "H"


static func _rough(g: GenGrid, t: MapTheme, seed_value: int) -> void:
	var f := GenNoise.field(g, seed_value, 0.3, 2)
	for i in g.size():
		f[i] += 0.12 * g.level[i] + 0.15 * _steepness(g, i)
	var open := _open(g)
	if open.is_empty():
		return
	for i: int in GenNoise.top(f, open, minf(1.0, t.rough * g.size() / open.size())):
		g.token[i] = "r"


static func _open(g: GenGrid) -> Array:
	var out: Array = []
	for i in g.size():
		if g.is_open_ground(i):
			out.append(i)
	return out


static func _steepness(g: GenGrid, i: int) -> int:
	var s := 0
	for n in g.neighbors(i):
		s = maxi(s, absi(g.level[n] - g.level[i]))
	return s
