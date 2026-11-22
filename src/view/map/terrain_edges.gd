class_name TerrainEdges
extends RefCounted
## Hex-local edge indices match HexMesh.corners(): center outward at
## 30, 90, 150, 210, 270, 330 degrees. Shared by soil and shoreline FX.
const NORMALS := [
	Vector2(0.8660254, 0.5), Vector2(0.0, 1.0),
	Vector2(-0.8660254, 0.5), Vector2(-0.8660254, -0.5),
	Vector2(0.0, -1.0), Vector2(0.8660254, -0.5)
]


static func edge_index(from: Vector2i, to: Vector2i) -> int:
	var delta := HexLayout.to_world(to) - HexLayout.to_world(from)
	var direction := Vector2(delta.x, delta.z).normalized()
	var best := -INF
	var index := 0
	for i in NORMALS.size():
		var score := direction.dot(NORMALS[i])
		if score > best:
			best = score
			index = i
	return index


static func shore_mask(map: BattleMap, t: MapTile) -> int:
	var mask := 0
	for dir in 6:
		var n := Hex.neighbor(t.coord, dir)
		var other := map.get_tile(n)
		if other == null or not other.is_water():
			mask |= 1 << edge_index(t.coord, n)
	return mask


## Blend only against genuinely different adjacent non-water terrain.
## Returns RGB of neighbor mix + alpha with six packed boundary bits.
static func land_mix(map: BattleMap, t: MapTile) -> Color:
	var mask := 0
	var palette := Color(0, 0, 0)
	var count := 0
	for dir in 6:
		var n := Hex.neighbor(t.coord, dir)
		var other := map.get_tile(n)
		if other == null or other.is_water() or other.terrain.id == t.terrain.id:
			continue
		mask |= 1 << edge_index(t.coord, n)
		palette += other.terrain.top_color
		count += 1
	if count == 0:
		return Color(0, 0, 0, 0)
	palette /= float(count)
	return Color(palette.r, palette.g, palette.b, float(mask) / 63.0)
