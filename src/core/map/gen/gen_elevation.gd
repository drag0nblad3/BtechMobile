class_name GenElevation
extends RefCounted
## Ground levels and lakes. One smooth field ranks every hex: the lowest
## `theme.water` share floods into lakes (deepest in the middle), and the
## dry land is split into levels by the theme's level shares.

const MAX_STEP := 2  ## Steepest step between neighbours ('Mechs climb at most 2).


static func apply(g: GenGrid, t: MapTheme, seed_value: int) -> void:
	var e := GenNoise.field(g, seed_value, t.hill_scale, 4)
	var all: Array = range(g.size())
	var order := GenNoise.ranked(e, all)  # high -> low
	var n_water := int(round(g.size() * t.water))
	var land := order.slice(0, g.size() - n_water)
	land.reverse()  # low -> high
	_assign_levels(g, land, t.levels)
	relax(g)
	if n_water > 0:
		_flood(g, order.slice(g.size() - n_water), e, t.deep)


static func _assign_levels(g: GenGrid, land_low_to_high: Array, shares: Array[float]) -> void:
	var total := 0.0
	for s in shares:
		total += s
	var cum: Array[float] = []
	var run := 0.0
	for s in shares:
		run += s / total
		cum.append(run)
	for k in land_low_to_high.size():
		var frac := (k + 0.5) / land_low_to_high.size()
		var lvl := 0
		while lvl < cum.size() - 1 and frac > cum[lvl]:
			lvl += 1
		g.level[land_low_to_high[k]] = lvl


## Lower any dry hex standing more than MAX_STEP above a neighbour,
## which also cuts valley sides down to a river.
static func relax(g: GenGrid) -> void:
	var changed := true
	while changed:
		changed = false
		for i in g.size():
			if g.token[i] == "w":
				continue
			for n in g.neighbors(i):
				if g.level[i] > g.level[n] + MAX_STEP:
					g.level[i] = g.level[n] + MAX_STEP
					changed = true


## Each lake's surface sits at its lowest shore; the lowest-ranked share
## `deep` of all lake hexes is Depth 2, the bottom quarter of those Depth 3.
static func _flood(g: GenGrid, lake: Array, e: PackedFloat32Array, deep: float) -> void:
	var is_lake := {}
	for i: int in lake:
		is_lake[i] = true
	var seen := {}
	for start: int in lake:
		if seen.has(start):
			continue
		var comp: Array = [start]
		seen[start] = true
		var shore := 99
		var k := 0
		while k < comp.size():
			for n in g.neighbors(comp[k]):
				if is_lake.has(n):
					if not seen.has(n):
						seen[n] = true
						comp.append(n)
				else:
					shore = mini(shore, g.level[n])
			k += 1
		for i: int in comp:
			g.make_water(i, 0 if shore == 99 else shore, 1)
	var low_first := GenNoise.ranked(e, lake)
	low_first.reverse()
	var n2 := int(round(lake.size() * deep))
	@warning_ignore("integer_division")
	var n3 := n2 / 4
	for k in n2:
		g.depth[low_first[k]] = 3 if k < n3 else 2
