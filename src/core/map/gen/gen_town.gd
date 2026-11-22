class_name GenTown
extends RefCounted
## Streets and buildings. Urban themes lay a street grid (straight
## columns, zig-zag rows) and fill the blocks; other themes scatter a few
## farm buildings, mostly beside roads. Buildings stay off the two rows
## at each home edge so 'Mechs never deploy inside one.


static func streets(g: GenGrid, t: MapTheme, rng: RandomNumberGenerator) -> void:
	if t.street_every <= 0:
		return
	var n := t.street_every
	var col0 := rng.randi_range(1, n)
	var row0 := rng.randi_range(2, n + 1)
	var paved: Array = []
	for i in g.size():
		var c := g.col_of(i)
		var r := g.row_of(i)
		if (c - col0) % n == 0 and c >= col0 or (r - row0) % (n + 1) == 0 and r >= row0:
			paved.append(i)
	GenRoads.pave(g, paved)


static func buildings(g: GenGrid, t: MapTheme, rng: RandomNumberGenerator) -> void:
	if t.buildings <= 0.0:
		return
	var spots: Array = []
	for i in g.size():
		if g.is_open_ground(i) and not g.near_home_edge(i):
			spots.append(i)
	if t.street_every > 0:
		for i: int in spots:
			var by_street := _beside_road(g, i)
			if rng.randf() < (t.buildings if by_street else t.buildings * 0.5):
				_place(g, i, t, rng)
		return
	var want := int(round(g.size() * t.buildings))
	var roadside := spots.filter(func(i: int) -> bool: return _beside_road(g, i))
	for k in want:
		var pool := roadside if not roadside.is_empty() and rng.randf() < 0.75 else spots
		if pool.is_empty():
			return
		var i: int = pool[rng.randi_range(0, pool.size() - 1)]
		if g.is_open_ground(i):
			_place(g, i, t, rng)


## Rubble from earlier fighting: open ground next to buildings.
static func rubble(g: GenGrid, t: MapTheme, rng: RandomNumberGenerator) -> void:
	if t.rubble <= 0.0:
		return
	for i in g.size():
		if not g.is_open_ground(i):
			continue
		for n in g.neighbors(i):
			if g.buildings.has(n) and rng.randf() < t.rubble * 3.0:
				g.token[i] = "u"
				break


static func _beside_road(g: GenGrid, i: int) -> bool:
	for n in g.neighbors(i):
		if g.token[n] == "p":
			return true
	return false


static func _place(g: GenGrid, i: int, t: MapTheme, rng: RandomNumberGenerator) -> void:
	var type := _pick(t.building_mix, rng)
	var tall := 1 if type == "civilian" or type == "light" else 2
	var height := clampi(rng.randi_range(1, t.max_height + tall - 1), 1, t.max_height)
	g.buildings[i] = {"type": type, "height": height}


static func _pick(weights: Dictionary, rng: RandomNumberGenerator) -> String:
	var total := 0.0
	for k: String in weights:
		total += float(weights[k])
	var roll := rng.randf() * total
	var keys := weights.keys()
	keys.sort()
	for k: String in keys:
		roll -= float(weights[k])
		if roll <= 0.0:
			return k
	return keys[-1]
