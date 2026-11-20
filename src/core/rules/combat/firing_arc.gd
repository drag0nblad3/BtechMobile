class_name FiringArc
extends RefCounted
## Arcs around a 'Mech, measured from its facing. The six hexside wedges
## (0 = straight ahead, clockwise) group into front, sides and rear.
## TODO(rules): front = forward hexside plus both forward-diagonal hexsides;
## a line exactly along a hex corner counts as the more forward wedge.

enum { FRONT, RIGHT, REAR, LEFT }

const NAMES := ["front", "right side", "rear", "left side"]


## Wedge 0..5 (relative to `facing`) that `to` lies in, seen from `from`.
static func wedge(from: Vector2i, facing: int, to: Vector2i) -> int:
	var a := _world(from)
	var b := _world(to)
	var d := b - a
	# Facing 0 points to -y (north); angle grows clockwise.
	var ang := rad_to_deg(atan2(d.x, -d.y))
	var rel := fposmod(ang - facing * 60.0, 360.0)
	# Wedges are centered on hexside directions; nudge ties toward the front.
	var eps := -0.01 if rel < 180.0 else 0.01
	return int(floor((rel + 30.0 + eps) / 60.0)) % 6


static func arc_of_wedge(w: int) -> int:
	match w:
		0, 1, 5:
			return FRONT
		2:
			return RIGHT
		4:
			return LEFT
	return REAR


static func arc(from: Vector2i, facing: int, to: Vector2i) -> int:
	return arc_of_wedge(wedge(from, facing, to))


## Can a weapon in `loc` fire into `arc_id`? Torso, head and leg weapons fire
## forward (or backward if rear-mounted); arms also cover their own side.
## TODO(rules): torso twist not implemented.
static func weapon_covers(loc: int, rear: bool, arc_id: int) -> bool:
	if rear:
		return arc_id == REAR
	if arc_id == FRONT:
		return true
	if loc == Location.LA:
		return arc_id == LEFT
	if loc == Location.RA:
		return arc_id == RIGHT
	return false


static func _world(c: Vector2i) -> Vector2:
	return Vector2(1.5 * c.x, sqrt(3.0) * (c.y + c.x * 0.5))
