class_name BotHidden
extends RefCounted
## How the computer plays hidden units: wait in ambush until a shot is worth
## giving its position away, come out to hunt if nobody has come near by
## turn 4, and answer point-blank chances when the volley does real damage.

const SHOOT_VALUE := 2.0  ## Expected damage that's worth breaking cover for.
const POINT_BLANK_VALUE := 1.0
const HUNT_TURN := 4
const HUNT_RANGE := 12


## Reveals the hidden units of `side` that should act this phase. Returns
## true if it revealed one.
static func reveal(gc: GameController, side: int) -> bool:
	var s := gc.state
	for h in s.hidden.duplicate():
		if h.side != side or not HiddenUnits.may_reveal(s, h):
			continue
		var why := _reason(s, h)
		if why != "":
			gc.reveal(h)
			gc.announce(h, why)
			return true
	return false


static func _reason(s: GameState, h: Unit) -> String:
	if s.phase == Phase.Kind.WEAPON_ATTACK:
		var f := BotFire.plan(s, h)
		if float(f["value"]) >= SHOOT_VALUE:
			return "breaks cover to open fire: about %.1f damage is worth giving its position away" % f["value"]
		return ""
	var e := BotMove.nearest_enemy(s, h, h.coord)
	if s.turn >= HUNT_TURN and (e == null or Hex.distance(h.coord, e.coord) > HUNT_RANGE):
		return "comes out of hiding to hunt: no enemy has come within %d hexes" % HUNT_RANGE
	return ""


## Answers the point-blank chance owed by a unit of `side`. Returns true if it did.
static func answer(gc: GameController, side: int) -> bool:
	var s := gc.state
	if s.point_blank.is_empty():
		return false
	var h := s.unit_by_id(int(s.point_blank[0]["unit_id"]))
	var t := s.unit_by_id(int(s.point_blank[0]["target_id"]))
	if h == null or h.side != side:
		return false
	var p := PointBlank.plan(s, h, t, true) if t else {"shots": [], "twist": 0, "expected": 0.0}
	if float(p["expected"]) >= POINT_BLANK_VALUE:
		gc.announce(h, "springs its ambush: point-blank volley, about %.1f damage, at the cost of the rest of its turn" % p["expected"])
		return gc.point_blank(h, p["shots"], p["twist"])
	gc.announce(h, "holds its fire: the point-blank volley isn't worth giving up its turn")
	return gc.point_blank(h, [])
