class_name Displacement
extends RefCounted
## Pushing a 'Mech into the next hex (charges, DFAs, pushes).
## TODO(rules): no domino effect, no falling off cliffs; blocked = stays put.


## Moves `u` one hex in `dir` if that hex is on the map, empty, not deep
## water and at most one level up. Returns true if it moved.
static func push(state: GameState, emit: Callable, u: Unit, dir: int) -> bool:
	if u.destroyed or dir < 0:
		return false
	var to := Hex.neighbor(u.coord, dir)
	var src := state.map.get_tile(u.coord)
	var dst := state.map.get_tile(to)
	if dst == null or state.unit_at(to) != null or dst.depth >= 2 or dst.level > src.level + 1:
		return false
	move_to(state, emit, u, to)
	return true


static func move_to(_state: GameState, emit: Callable, u: Unit, to: Vector2i) -> void:
	var from := MoveOptions.key(u.coord, u.facing)
	u.coord = to
	emit.call(GameEvent.DISPLACED, {"unit_id": u.id, "from": from,
			"path": [MoveOptions.key(to, u.facing)]})
