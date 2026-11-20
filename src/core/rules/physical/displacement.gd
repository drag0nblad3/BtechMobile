class_name Displacement
extends RefCounted
## Forcing a 'Mech into the next hex (charges, DFAs, pushes), book pp. 113-114.
## - It can't be pushed 3+ levels up: nothing moves.
## - Pushed 2+ levels down: it falls that far in the new hex.
## - Off the map: destroyed.
## - Into another 'Mech (domino effect): that one rolls piloting. On a pass it
##   steps one hex straight forward or back if it can; otherwise it is pushed
##   on in the same direction (and falls if it failed). With nowhere to go,
##   the last 'Mech in the chain is destroyed.
## TODO(rules): accidental falls from above (2+ levels down onto a 'Mech) are
## treated as a domino effect.

const MAX_UP := 2


## Moves `u` one hex in `dir`. Returns true if it moved.
static func push(state: GameState, dice: Dice, emit: Callable, u: Unit, dir: int) -> bool:
	if u.destroyed or dir < 0:
		return false
	var to := Hex.neighbor(u.coord, dir)
	var src := state.map.get_tile(u.coord)
	var dst := state.map.get_tile(to)
	if dst == null:
		move_to(state, emit, u, to)
		Damage.destroy_unit(u, "pushed off the battlefield")
		Damage.announce(emit, u)
		return true
	if _level(dst) - _level(src) > MAX_UP:
		return false
	var other := state.unit_at(to)
	if other != null and other != u and not _make_room(state, dice, emit, other, dir):
		return false
	move_to(state, emit, u, to)
	var drop := _level(src) - _level(dst)
	if drop >= 2:
		Fall.fall(state, dice, emit, u, drop, "pushed off a ledge")
	return true


## Domino effect: `t` gets out of the way, or is pushed on. False if the
## chain can't move at all (then nobody moves).
static func _make_room(state: GameState, dice: Dice, emit: Callable, t: Unit, dir: int) -> bool:
	if t.destroyed:
		return true
	var ok := not t.prone and Psr.roll(dice, emit, t, "a 'Mech was shoved into its hex", 0)
	if ok:
		for step in _dodges(t):
			var c := Hex.neighbor(t.coord, step)
			if _can_step(state, t, c, dir):
				move_to(state, emit, t, c)
				return true
	var moved := push(state, dice, emit, t, dir)
	if not moved:
		Damage.destroy_unit(t, "crushed with nowhere to go")
		Damage.announce(emit, t)
		return true
	if not ok and not t.destroyed and not t.prone:
		Fall.fall(state, dice, emit, t, 0, "knocked over by a domino effect")
	return true


## Directions a domino target may step: straight forward, or back if it didn't run.
static func _dodges(t: Unit) -> Array[int]:
	var out: Array[int] = [t.facing]
	if t.move_mode != MoveMode.Kind.RUN:
		out.append(Hex.rotate(t.facing, 3))
	return out


static func _can_step(state: GameState, t: Unit, c: Vector2i, push_dir: int) -> bool:
	if c == Hex.neighbor(t.coord, Hex.rotate(push_dir, 3)):
		return false  # the hex the shoved 'Mech comes from counts as occupied
	var cost := MoveCost.enter_cost(state.map, t.coord, c, MoveMode.Kind.WALK)
	return cost != MoveCost.PROHIBITED and state.unit_at(c) == null


static func _level(tile: MapTile) -> int:
	return tile.floor_level()


static func move_to(_state: GameState, emit: Callable, u: Unit, to: Vector2i) -> void:
	var from := MoveOptions.key(u.coord, u.facing)
	u.coord = to
	emit.call(GameEvent.DISPLACED, {"unit_id": u.id, "from": from,
			"path": [MoveOptions.key(to, u.facing)]})
