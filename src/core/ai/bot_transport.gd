class_name BotTransport
extends RefCounted
## How the computer uses APCs and Mechanized battle armor (book p. 148).
## Far from the enemy, an empty transport drives to friendly infantry and
## the infantry climbs in; once the transport has moved within reach of
## the enemy, its riders get out.

const FAR := 8      ## Enemy farther than this: worth riding.
const CLOSE := 6    ## Enemy this close after the move: time to get out.


## Infantry's own turn: a transport in its hex to board if the enemy is
## far, or null.
static func ride(state: GameState, u: Unit) -> Unit:
	if not AssetStacking.is_infantry(u) or _enemy_dist(state, u, u.coord) <= FAR:
		return null
	for c in state.units_of_side(u.side):
		if c != u and not c.destroyed and AssetTransport.board_problem(state, u, c) == "":
			return c
	return null


## A transport's move: pick up friendly infantry when the enemy is far.
## Returns a BotMove-style plan, or {} to move normally.
static func pickup(state: GameState, u: Unit) -> Dictionary:
	if (u.asset == null and not u.def.omni) or (u.asset != null and u.asset.card.special("APC") == 0):
		return {}
	if not AssetTransport.riders(state, u).is_empty() or _enemy_dist(state, u, u.coord) <= FAR:
		return {}
	var opts := MovePlanner.plan(state, u, MoveMode.Kind.RUN)
	var best: Dictionary = {}
	for r in state.units_of_side(u.side):
		if r.destroyed or AssetTransport.capacity(u, r) < AssetTransport.cost(r) \
				or r.carrier_id() >= 0 or r.coord == u.coord:
			continue
		var keys := opts.end_keys_in(r.coord)
		if keys.is_empty():
			continue
		var cost: int = opts.cost[keys[0]]
		if best.is_empty() or cost < best["cost"]:
			best = {"key": keys[0], "mode": MoveMode.Kind.RUN, "cost": cost, "charge": -1,
					"reason": "drives over to pick up %s; the enemy is still far off" % Names.unit(r)}
	return best


## After a transport moves: let moved infantry in its hex climb in, or put
## its riders down if the enemy is close. Returns what it announced.
static func after_move(gc: GameController, u: Unit) -> String:
	var s := gc.state
	var riders := AssetTransport.riders(s, u)
	var parts: Array[String] = []
	if riders.is_empty() and _enemy_dist(s, u, u.coord) > FAR:
		for r in s.units_of_side(u.side):
			if r.coord == u.coord and r.has_moved and AssetTransport.board_problem(s, r, u) == "" and gc.board(r, u):
				parts.append("%s climbs aboard" % Names.unit(r))
	elif _enemy_dist(s, u, u.coord) <= CLOSE:
		for r in riders:
			if gc.deploy(r):
				parts.append("%s jumps out to fight" % Names.unit(r))
	return ", ".join(parts)


static func _enemy_dist(state: GameState, u: Unit, from: Vector2i) -> int:
	var e := BotMove.nearest_enemy(state, u, from)
	return Hex.distance(from, e.coord) if e != null else 999
