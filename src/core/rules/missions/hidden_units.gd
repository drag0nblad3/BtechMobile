class_name HiddenUnits
extends RefCounted
## Hidden units (book pp. 230-231). A hidden 'Mech waits off `state.units`
## (in `state.hidden`), so nothing can see, target or count it for turn order.
## It comes out when its owner reveals it at the start of a Movement or Weapon
## Attack Phase to act, when an enemy tries to walk into its hex or ends a
## move next to it, when an enemy jumps onto it, or when its hex burns.
## Found by an enemy, it can't move that phase and has no movement modifier
## that turn; it may answer with a point-blank attack (PointBlank).

const OPEN_GROUND := ["clear", "pavement"]
const PLACE_RADIUS := 6


## Why `u` can't hide at `c`, or "" if it can.
static func problem(state: GameState, u: Unit, c: Vector2i) -> String:
	var tile := state.map.get_tile(c)
	if tile == null:
		return "off the map"
	if state.unit_at(c) != null and state.unit_at(c) != u or hidden_at(state, c) != null:
		return "the hex is taken"
	if tile.building != null:
		return ""  # inside it, never on the roof
	if tile.is_water():
		return "" if tile.depth >= 2 else "the water isn't deep enough to cover a 'Mech"
	if tile.terrain.id in OPEN_GROUND or tile.on_fire:
		return "there's nothing to hide behind in %s" % tile.terrain.name.to_lower()
	return ""


static func hide(state: GameState, u: Unit) -> void:
	state.units.erase(u)
	if not state.hidden.has(u):
		state.hidden.append(u)


## Hides every 'Mech of `side` in the nearest hiding place on its own half
## of the field (nearer its own start than any enemy), facing the enemy.
## A 'Mech with nowhere to hide stays in the open.
## TODO(rules): players pick their own hexes; we pick the nearest one.
static func place_side(state: GameState, side: int) -> void:
	var enemies: Array[Vector2i] = []
	for e in state.units:
		if e.side != side:
			enemies.append(e.coord)
	for u in state.units_of_side(side).duplicate():
		var best := Hex.INVALID
		for c: Vector2i in state.map.coords():
			var d := Hex.distance(u.coord, c)
			if d > PLACE_RADIUS or problem(state, u, c) != "" or not _own_half(c, u.coord, enemies):
				continue
			if best == Hex.INVALID or d < Hex.distance(u.coord, best):
				best = c
		if best != Hex.INVALID:
			u.coord = best
			if not enemies.is_empty():
				u.facing = Hex.direction_to(best, enemies[0])
			hide(state, u)


static func _own_half(c: Vector2i, home: Vector2i, enemies: Array[Vector2i]) -> bool:
	for e in enemies:
		if Hex.distance(c, e) <= Hex.distance(c, home):
			return false
	return true


static func hidden_at(state: GameState, c: Vector2i) -> Unit:
	for h in state.hidden:
		if h.coord == c:
			return h
	return null


## A hidden enemy of `side` in hex `c`, or null.
static func enemy_at(state: GameState, side: int, c: Vector2i) -> Unit:
	var h := hidden_at(state, c)
	return h if h != null and h.side != side else null


## May its owner reveal `u` now? Only before anyone has acted this phase.
static func may_reveal(state: GameState, u: Unit) -> bool:
	return state.hidden.has(u) and not state.game_over and state.order_index == 0 \
			and state.point_blank.is_empty() \
			and state.phase in [Phase.Kind.MOVEMENT, Phase.Kind.WEAPON_ATTACK]


## Puts `u` on the field. `by_enemy`: an enemy found it (no move this phase,
## no target movement modifier this turn).
static func reveal(state: GameState, emit: Callable, u: Unit, why: String, by_enemy := false) -> void:
	if not state.hidden.has(u):
		return
	state.hidden.erase(u)
	state.units.append(u)
	if by_enemy:
		u.tmm_zero = true
		if state.phase == Phase.Kind.MOVEMENT:
			u.has_moved = true
	emit.call(GameEvent.UNIT_REVEALED, {"unit_id": u.id, "why": why, "by_enemy": by_enemy})


## How far along `path` a ground move gets before bumping into a hidden
## enemy: {keep: keys kept, hidden: Unit}, or {} if nothing is in the way.
## Jumps fly over hidden units; landing on one is handled by the caller.
static func blocked_path(state: GameState, u: Unit, path: Array[Vector3i], mode: int) -> Dictionary:
	if mode == MoveMode.Kind.JUMP:
		return {}
	var at := u.coord
	for i in path.size():
		var c := MoveOptions.coord_of(path[i])
		if c != at:
			var h := enemy_at(state, u.side, c)
			if h != null:
				return {"keep": i, "hidden": h}
			at = c
	return {}


## Hidden enemies next to (or under) `u` after its move, revealed.
static func reveal_around(state: GameState, emit: Callable, u: Unit) -> Array[Unit]:
	var found: Array[Unit] = []
	for h in state.hidden.duplicate():
		if h.side != u.side and Hex.distance(h.coord, u.coord) <= 1:
			reveal(state, emit, h, "an enemy came next to it", true)
			found.append(h)
	return found


## End of a phase: hidden units in burning hexes are driven out.
static func reveal_burning(state: GameState, emit: Callable) -> void:
	for h in state.hidden.duplicate():
		var tile := state.map.get_tile(h.coord)
		if tile and tile.on_fire:
			reveal(state, emit, h, "its hex caught fire")
