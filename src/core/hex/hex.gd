class_name Hex
extends RefCounted
## Axial hex math for flat-topped hexes (BattleTech mapsheet orientation).
## Coordinates are Vector2i(q, r). Facing 0..5 runs clockwise from north,
## and each facing points at a hexside, as on a BattleTech record sheet.

const INVALID := Vector2i(1 << 30, 1 << 30)

const DIRECTIONS: Array[Vector2i] = [
	Vector2i(0, -1),  # 0 N
	Vector2i(1, -1),  # 1 NE
	Vector2i(1, 0),   # 2 SE
	Vector2i(0, 1),   # 3 S
	Vector2i(-1, 1),  # 4 SW
	Vector2i(-1, 0),  # 5 NW
]


static func neighbor(c: Vector2i, facing: int) -> Vector2i:
	return c + DIRECTIONS[posmod(facing, 6)]


static func distance(a: Vector2i, b: Vector2i) -> int:
	var d := a - b
	return (absi(d.x) + absi(d.y) + absi(d.x + d.y)) / 2


static func rotate(facing: int, steps: int) -> int:
	return posmod(facing + steps, 6)


## Hexsides turned to go from one facing to another (0..3).
static func turn_cost(from_facing: int, to_facing: int) -> int:
	var d := posmod(to_facing - from_facing, 6)
	return mini(d, 6 - d)


## Facing from a to an adjacent hex b, or -1 if not adjacent.
static func direction_to(a: Vector2i, b: Vector2i) -> int:
	return DIRECTIONS.find(b - a)


## Hexes on the straight line from a to b, inclusive (for line of sight).
## Hexes on the straight line from a to b. `side` (+1 or -1) picks which
## hex wins when the line runs exactly along a hexside (divided LOS).
static func line(a: Vector2i, b: Vector2i, side: float = 1.0) -> Array[Vector2i]:
	var n := distance(a, b)
	var out: Array[Vector2i] = []
	if n == 0:
		out.append(a)
		return out
	var e := 1e-6 * side
	var ac := Vector3(a.x + e, a.y + e, -a.x - a.y - 2 * e)
	var bc := Vector3(b.x + e, b.y + e, -b.x - b.y - 2 * e)
	for i in n + 1:
		out.append(cube_round(ac.lerp(bc, float(i) / n)))
	return out


static func cube_round(c: Vector3) -> Vector2i:
	var rx := roundf(c.x)
	var ry := roundf(c.y)
	var rz := roundf(c.z)
	var dx := absf(rx - c.x)
	var dy := absf(ry - c.y)
	var dz := absf(rz - c.z)
	if dx > dy and dx > dz:
		rx = -ry - rz
	elif dy > dz:
		ry = -rx - rz
	return Vector2i(int(rx), int(ry))


## Axial -> 0-based (col, row), "odd-q": odd columns sit half a hex lower,
## matching printed BattleTech mapsheets.
static func to_offset(c: Vector2i) -> Vector2i:
	return Vector2i(c.x, c.y + (c.x - (c.x & 1)) / 2)


static func from_offset(o: Vector2i) -> Vector2i:
	return Vector2i(o.x, o.y - (o.x - (o.x & 1)) / 2)


## Mapsheet label, e.g. "0805" (1-based column then row).
static func label(c: Vector2i) -> String:
	var o := to_offset(c)
	return "%02d%02d" % [o.x + 1, o.y + 1]


## Inverse of label(): "0805" -> axial coordinate.
static func from_label(s: String) -> Vector2i:
	return from_offset(Vector2i(int(s.substr(0, 2)) - 1, int(s.substr(2, 2)) - 1))
