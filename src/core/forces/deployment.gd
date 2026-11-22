class_name Deployment
extends RefCounted
## Places a side's 'Mechs before turn 1. Each zone is a line some hexes in
## from an edge ({"edge": "south", "depth": 1}) or the hexes around a point
## ({"near": "0809", "radius": 2}). Units split evenly across the zones and
## face the middle of the map. Deep water and occupied hexes are skipped.


static func place(state: GameState, units: Array[Unit], zones: Array) -> void:
	if zones.is_empty() or units.is_empty():
		return
	var groups := []
	for z in zones.size():
		groups.append([])
	for i in units.size():
		groups[i % zones.size()].append(units[i])
	var centre := center(state.map)
	for z in zones.size():
		var spots := _spots(state, zones[z], groups[z].size())
		for i in groups[z].size():
			var u: Unit = groups[z][i]
			u.coord = spots[i] if i < spots.size() else u.coord
			if u.asset != null or u.vehicle != null:
				u.coord = _asset_spot(state, u)
			if u.coord != centre:
				u.facing = Hex.direction_to(u.coord, centre)


## The middle hex of the map.
static func center(map: BattleMap) -> Vector2i:
	@warning_ignore("integer_division")
	return Hex.from_offset(Vector2i((map.width - 1) / 2, (map.height - 1) / 2))


static func _spots(state: GameState, zone: Dictionary, n: int) -> Array[Vector2i]:
	var cands: Array[Vector2i] = []
	for c: Vector2i in state.map.coords():
		if _usable(state, c) and _in_zone(state.map, c, zone):
			cands.append(c)
	var out: Array[Vector2i] = []
	if zone.has("near"):
		var p := Hex.from_label(zone["near"])
		cands.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return Hex.distance(a, p) < Hex.distance(b, p))
		return cands.slice(0, n)
	var vertical: bool = zone["edge"] in ["west", "east"]
	cands.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			var oa := Hex.to_offset(a)
			var ob := Hex.to_offset(b)
			return oa.y < ob.y if vertical else oa.x < ob.x)
	for i in n:
		var idx := int(round((i + 1) * cands.size() / float(n + 1))) - 1
		var c := cands[clampi(idx, 0, cands.size() - 1)] if not cands.is_empty() else Hex.INVALID
		while out.has(c) and not cands.is_empty():
			idx = (idx + 1) % cands.size()
			c = cands[idx]
		out.append(c)
	return out


## An Asset needs a hex its movement type may be in: the nearest such free hex.
static func _asset_spot(state: GameState, u: Unit) -> Vector2i:
	var best := u.coord
	var best_d := 999
	for c: Vector2i in state.map.coords():
		var d := Hex.distance(c, u.coord)
		if d < best_d and _may_be(u, state.map.get_tile(c)) \
				and state.units.all(func(o: Unit) -> bool: return o == u or o.coord != c):
			best = c
			best_d = d
	return best


static func _may_be(u: Unit, tile: MapTile) -> bool:
	if u.vehicle != null:
		return VehicleMoveCost.may_enter(u.def.vehicle.motive, tile)
	return AssetMoveCost.may_enter(u.asset.card, tile)


static func _usable(state: GameState, c: Vector2i) -> bool:
	var t := state.map.get_tile(c)
	return t.depth < 2 and state.unit_at(c) == null and t.building == null


static func _in_zone(map: BattleMap, c: Vector2i, zone: Dictionary) -> bool:
	if zone.has("near"):
		return Hex.distance(c, Hex.from_label(zone["near"])) <= int(zone.get("radius", 2))
	var d := MapEdges.distance(map, c, zone["edge"])
	return d >= int(zone.get("depth", 1)) and d <= int(zone.get("to_depth", zone.get("depth", 1)))
