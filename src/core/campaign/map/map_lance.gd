class_name MapLance
extends RefCounted
## One formation on the campaign map (Campaign Operations p. 148): a lance
## of one side's roster 'Mechs, where it stands, and this turn's order.

const ATTACK := "attack"
const SCOUT := "scout"
const DEFEND := "defend"
const MOVE := "move"
const FAST_MOVE := "fast_move"
const REPAIR := "repair"
const ORDERS := [ATTACK, SCOUT, DEFEND, MOVE, FAST_MOVE, REPAIR]
const COMBAT := [ATTACK, SCOUT, DEFEND]
const NAMES := {ATTACK: "Attack", SCOUT: "Scout", DEFEND: "Defend", MOVE: "Move", FAST_MOVE: "Fast Move", REPAIR: "Repair"}

var id := ""
var name := ""
var side := 0
var zone := Vector2i.ZERO
var mech_ids: Array[String] = []
var order := DEFEND
var target := Vector2i(-1, -1)  ## Where a Move, Fast Move, Attack or Scout order goes.
var fast_moved := false  ## Made a Fast Move last turn: no Move order now.


## Zones this order may travel. TODO(rules): Attack and Scout may step
## into a neighboring zone (our pick; the book leaves it to the GM).
func reach() -> int:
	match order:
		MOVE:
			return 1
		FAST_MOVE:
			return 2  # 1.5 x a Move of 1, rounded up
		ATTACK, SCOUT:
			return 1
	return 0


func to_dict() -> Dictionary:
	return {"id": id, "name": name, "side": side, "zone": [zone.x, zone.y], "mechs": Array(mech_ids),
		"order": order, "target": [target.x, target.y], "fast_moved": fast_moved}


static func from_dict(d: Dictionary) -> MapLance:
	var l := MapLance.new()
	l.id = String(d.get("id", ""))
	l.name = String(d.get("name", ""))
	l.side = int(d.get("side", 0))
	l.zone = Vector2i(int(d["zone"][0]), int(d["zone"][1]))
	for m in d.get("mechs", []):
		l.mech_ids.append(String(m))
	l.order = String(d.get("order", DEFEND))
	var t: Array = d.get("target", [-1, -1])
	l.target = Vector2i(int(t[0]), int(t[1]))
	l.fast_moved = bool(d.get("fast_moved", false))
	return l
