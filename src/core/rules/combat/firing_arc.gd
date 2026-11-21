class_name FiringArc
extends RefCounted
## Arcs around a 'Mech, measured from its facing. Two different shapes:
## - firing arcs (book p. 60), which weapons can shoot into: forward 120°,
##   each side 60°, rear 120°; a line through a neighbor's center counts
##   as the more forward arc. See `fire_arc`.
## - attack direction (p. 73), which hit table a hit uses: the six hexside
##   wedges (0 = straight ahead, clockwise); front is three of them. See `arc`.

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


## Attack direction: the side of a 'Mech at `from` that a shot from `to` hits.
static func arc(from: Vector2i, facing: int, to: Vector2i) -> int:
	return arc_of_wedge(wedge(from, facing, to))


## Firing arc of `to` seen from a 'Mech at `from` facing `facing`.
static func fire_arc(from: Vector2i, facing: int, to: Vector2i) -> int:
	var rel := relative_angle(from, facing, to)
	var mag := absf(rel)
	if mag <= 60.01:
		return FRONT
	if mag <= 120.01:
		return RIGHT if rel > 0.0 else LEFT
	return REAR


## Angle of `to` from the facing direction, -180..180, positive clockwise.
static func relative_angle(from: Vector2i, facing: int, to: Vector2i) -> float:
	var d := _world(to) - _world(from)
	var ang := rad_to_deg(atan2(d.x, -d.y))
	return wrapf(ang - facing * 60.0, -180.0, 180.0)


## Can a weapon in `loc` fire into `arc_id`? Torso, head and leg weapons fire
## forward (or backward if rear-mounted); arms also cover their own side
## (a quad's front legs don't: `quad`).
static func weapon_covers(loc: int, rear: bool, arc_id: int, quad := false) -> bool:
	if rear:
		return arc_id == REAR
	if arc_id == FRONT:
		return true
	if quad:
		return false
	if loc == Location.LA:
		return arc_id == LEFT
	if loc == Location.RA:
		return arc_id == RIGHT
	return false


## Facing a weapon's arcs are measured from: legs use the legs' facing,
## everything else turns with the torso.
static func weapon_facing(u: Unit, loc: int) -> int:
	return u.facing if Location.is_leg_of(u.def, loc) else u.torso_facing()


static func _world(c: Vector2i) -> Vector2:
	return Vector2(1.5 * c.x, sqrt(3.0) * (c.y + c.x * 0.5))
