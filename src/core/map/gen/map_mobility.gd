class_name MapMobility
extends RefCounted
## Conservative ground-route audit: ordinary standing 'Mech, no jumps,
## building entry, deep-water travel, facing costs or combat occupancy.
## Uses the real per-hex MoveCost; results are lower bounds, not turn counts.

const UNREACHABLE := 1 << 28
const STEP_LIMIT := 4


static func usable(t: MapTile) -> bool:
	return t != null and t.building == null and (t.bridge != null or t.depth < 2)


static func edge(m: BattleMap, side: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c: Vector2i in m.coords():
		var o := Hex.to_offset(c)
		if (side == 0 and o.y < 2 or side == 1 and o.y >= m.height - 2
				or side == 2 and o.x < 2 or side == 3 and o.x >= m.width - 2):
			if usable(m.get_tile(c)):
				out.append(c)
	return out


static func costs(m: BattleMap, starts: Array[Vector2i], limit: int = STEP_LIMIT, axis_side := -1, band := -1) -> Dictionary:
	var dist := {}
	var heap := MinHeap.new()
	for c in starts:
		if usable(m.get_tile(c)) and _in_band(m, c, axis_side, band):
			dist[c] = 0
			heap.push(0, c)
	while not heap.is_empty():
		var entry := heap.pop()
		var d: int = entry[0]
		var c: Vector2i = entry[1]
		if d != dist[c]:
			continue
		for f in 6:
			var n := Hex.neighbor(c, f)
			if not usable(m.get_tile(n)) or not _in_band(m, n, axis_side, band):
				continue
			var step := MoveCost.enter_cost(m, c, n, MoveMode.Kind.WALK)
			if step <= 0 or step > limit:
				continue
			if d + step < int(dist.get(n, UNREACHABLE)):
				dist[n] = d + step
				heap.push(d + step, n)
	return dist


## Count independent-ish approach bands: each third of the opposite edge
## must be reachable. This measures exits, not disjoint graph paths.
static func exit_bands(m: BattleMap, dist: Dictionary, side: int) -> int:
	var bands := {}
	for c in edge(m, side):
		if dist.has(c):
			var o := Hex.to_offset(c)
			var along := o.x if side < 2 else o.y
			var size := m.width if side < 2 else m.height
			bands[mini(2, floori(3.0 * along / maxi(1, size)))] = true
	return bands.size()


static func nearest(dist: Dictionary, cells: Array[Vector2i]) -> int:
	var best := UNREACHABLE
	for c in cells:
		best = mini(best, int(dist.get(c, UNREACHABLE)))
	return best


static func center_cells(m: BattleMap) -> Array[Vector2i]:
	var center := Hex.from_offset(Vector2i(m.width / 2, m.height / 2))
	var out: Array[Vector2i] = []
	for c: Vector2i in m.coords():
		if Hex.distance(center, c) <= 2 and usable(m.get_tile(c)):
			out.append(c)
	return out


## Count traversable, non-overlapping thirds perpendicular to the advance.
## A genuine alternative route in a different band cannot share a choke hex.
static func _in_band(m: BattleMap, c: Vector2i, side: int, band: int) -> bool:
	if side < 0 or band < 0:
		return true
	var o := Hex.to_offset(c)
	var along := o.x if side < 2 else o.y
	var size := m.width if side < 2 else m.height
	return mini(2, floori(3.0 * along / maxi(1, size))) == band


static func routes(m: BattleMap, side: int, starts: Array[Vector2i], ends: Array[Vector2i]) -> int:
	var count := 0
	var goals := {}
	for c in ends:
		goals[c] = true
	for band in 3:
		if _band_crosses(m, side, band, starts, goals):
			count += 1
	return count


static func _band_crosses(m: BattleMap, side: int, band: int, starts: Array[Vector2i], goals: Dictionary) -> bool:
	var queue: Array[Vector2i] = []
	var seen := {}
	for c in starts:
		if _in_band(m, c, side, band):
			seen[c] = true
			queue.append(c)
	var i := 0
	while i < queue.size():
		var c := queue[i]
		i += 1
		if goals.has(c):
			return true
		for f in 6:
			var n := Hex.neighbor(c, f)
			if seen.has(n) or not usable(m.get_tile(n)) or not _in_band(m, n, side, band):
				continue
			var forward := MoveCost.enter_cost(m, c, n, MoveMode.Kind.WALK)
			var reverse := MoveCost.enter_cost(m, n, c, MoveMode.Kind.WALK)
			if forward > 0 and reverse > 0 and maxi(forward, reverse) <= STEP_LIMIT:
				seen[n] = true
				queue.append(n)
	return false


static func axis(m: BattleMap, side: int, center: Array[Vector2i], detailed := false) -> Dictionary:
	var a := edge(m, side)
	var b := edge(m, side + 1)
	var da := costs(m, a)
	var db := costs(m, b)
	var common := 0
	var usable_count := 0
	for c: Vector2i in m.coords():
		if usable(m.get_tile(c)):
			usable_count += 1
			if da.has(c) and db.has(c):
				common += 1
	var ca := nearest(da, center)
	var cb := nearest(db, center)
	var ratio := 0.0 if maxi(ca, cb) >= UNREACHABLE else float(mini(ca, cb) + 1) / float(maxi(ca, cb) + 1)
	var shared_center := 0
	for c in center:
		if da.has(c) and db.has(c):
			shared_center += 1
	var out := {"deploy_a": a.size(), "deploy_b": b.size(), "shared": float(common) / maxi(1, usable_count),
		"exits": mini(exit_bands(m, da, side + 1), exit_bands(m, db, side)),
		"center_a": ca, "center_b": cb, "center_balance": ratio, "shared_center": shared_center,
		"cross_mp": maxi(nearest(da, b), nearest(db, a))}
	out["independent_bands"] = routes(m, side, a, b)
	if detailed:
		var slow_a := costs(m, a, 3)
		var slow_b := costs(m, b, 3)
		out["slow_cross_mp"] = maxi(nearest(slow_a, b), nearest(slow_b, a))
		out["slow_center_a"] = nearest(slow_a, center)
		out["slow_center_b"] = nearest(slow_b, center)
	return out
