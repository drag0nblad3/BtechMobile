class_name HexLayout
extends RefCounted
## Converts between hex coordinates and 3D world space.
## North (facing 0) is -Z. One hex = HEX_SIZE (center to corner).

const HEX_SIZE := 1.0
const LEVEL_HEIGHT := 0.45  ## World units per BattleTech level (exaggerated).
const BASE_Y := -1.5        ## Bottom of terrain prisms.
const SQRT3 := 1.7320508


static func to_world(c: Vector2i, level: float = 0.0) -> Vector3:
	var x := HEX_SIZE * 1.5 * c.x
	var z := HEX_SIZE * SQRT3 * (c.y + c.x * 0.5)
	return Vector3(x, level * LEVEL_HEIGHT, z)


static func from_world(p: Vector3) -> Vector2i:
	var q := (2.0 / 3.0 * p.x) / HEX_SIZE
	var r := (-1.0 / 3.0 * p.x + SQRT3 / 3.0 * p.z) / HEX_SIZE
	return Hex.cube_round(Vector3(q, r, -q - r))


static func level_y(level: float) -> float:
	return level * LEVEL_HEIGHT


## Y rotation that makes a -Z-forward model face a hex facing.
static func facing_yaw(facing: int) -> float:
	return -facing * PI / 3.0


static func tile_top(t: MapTile) -> Vector3:
	return to_world(t.coord, t.floor_level())


## World-space bounds of a map (min corner, max corner) on the XZ plane.
static func map_bounds(m: BattleMap) -> AABB:
	var box := AABB(to_world(m.coords()[0]), Vector3.ZERO)
	for c: Vector2i in m.coords():
		box = box.expand(to_world(c))
	return box.grow(HEX_SIZE)
