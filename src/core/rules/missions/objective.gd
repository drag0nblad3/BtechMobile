class_name Objective
extends RefCounted
## An objective counter (book pp. 231-232): a hex, a control radius (0 =
## only that hex), the side that placed it (-1 = nobody) and its Victory
## Point value.

var coord: Vector2i
var radius: int = 0
var owner: int = -1
var vp: int = 1
var kind := ""  ## "" = held for VP; "intel" = scanned for intel (Urban Sweep).
var found := false  ## Intel found: the counter leaves play next turn (Scanning).
var claimed := {}  ## side -> true once that side scored its intel.


static func make(c: Vector2i, control_radius: int = 0, owner_side: int = -1, value: int = 1) -> Objective:
	var o := Objective.new()
	o.coord = c
	o.radius = control_radius
	o.owner = owner_side
	o.vp = value
	return o


## {"hex": "XXYY", "radius": 1, "owner": 0, "vp": 1}
static func from_dict(d: Dictionary) -> Objective:
	var o := make(Hex.from_label(d["hex"]), int(d.get("radius", 0)), int(d.get("owner", -1)), int(d.get("vp", 1)))
	o.kind = d.get("kind", "")
	return o


func in_radius(c: Vector2i) -> bool:
	return Hex.distance(c, coord) <= radius
