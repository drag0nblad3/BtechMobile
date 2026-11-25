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


static func costs(m: BattleMap, starts: Array[Vector2i], limit: int = STEP_LIMIT) -> Dictionary:
	var dist := {}
	var heap := MinHeap.new()
	for c in starts:
		if usable(m.get_tile(c)):
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
			if not usable(m.get_tile(n)):
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


static func axis(m: BattleMap, side: int, center: Array[Vector2i]) -> Dictionary:
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
	return {"deploy_a": a.size(), "deploy_b": b.size(), "shared": float(common) / maxi(1, usable_count),
		"exits": mini(exit_bands(m, da, side + 1), exit_bands(m, db, side)),
		"center_a": ca, "center_b": cb, "center_balance": ratio, "shared_center": shared_center,
		"cross_mp": maxi(nearest(da, b), nearest(db, a))}
