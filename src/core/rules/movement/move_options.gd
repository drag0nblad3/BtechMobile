class_name MoveOptions
extends RefCounted
## Result of MovePlanner: every (hex, facing) a unit can reach this phase.
## Keys are Vector3i(q, r, facing).

var unit: Unit
var mode: int
var budget: int
var cost: Dictionary = {}    # Vector3i -> MP spent to get there
var prev: Dictionary = {}    # Vector3i -> Vector3i (previous step)
var can_end: Dictionary = {} # Vector3i -> bool (legal place to stop)


static func key(c: Vector2i, facing: int) -> Vector3i:
	return Vector3i(c.x, c.y, facing)


static func coord_of(k: Vector3i) -> Vector2i:
	return Vector2i(k.x, k.y)


func start_key() -> Vector3i:
	return key(unit.coord, unit.facing)


## Cheapest legal end state per hex: Vector2i -> int MP.
func reachable_hexes() -> Dictionary:
	var out := {}
	for k: Vector3i in cost:
		if not can_end.get(k, false):
			continue
		var c := coord_of(k)
		if not out.has(c) or cost[k] < out[c]:
			out[c] = cost[k]
	return out


## Legal end facings in a hex, cheapest first.
func end_keys_in(c: Vector2i) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	for f in 6:
		var k := key(c, f)
		if can_end.get(k, false):
			out.append(k)
	out.sort_custom(func(a, b): return cost[a] < cost[b])
	return out


func can_reach(k: Vector3i) -> bool:
	return can_end.get(k, false)


## Steps from the start (exclusive) to k (inclusive).
func path_to(k: Vector3i) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	if not cost.has(k):
		return out
	var cur := k
	var start := start_key()
	while cur != start:
		out.push_front(cur)
		cur = prev[cur]
	return out


## Hexes entered along a path (for "hexes moved" modifiers).
static func hexes_entered(path: Array[Vector3i], from: Vector2i) -> int:
	var n := 0
	var last := from
	for k in path:
		var c := coord_of(k)
		if c != last:
			n += 1
			last = c
	return n
