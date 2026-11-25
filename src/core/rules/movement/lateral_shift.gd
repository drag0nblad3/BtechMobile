class_name LateralShift
extends RefCounted
## Lateral shift (book p. 238): a four-legged 'Mech with all its legs can
## step sideways into the hex ahead-left or ahead-right (or, walking, the
## hex behind-left or behind-right) without turning, for the hex's cost +1 MP.
## A shift toward the rear counts as moving backward.

const EXTRA_MP := 1


## Maneuvering Ace (SPA, Campaign Operations p. 77) lets a two-legged
## 'Mech with both legs shift too, and a four-legged one shift for 1 MP less.
static func allowed(u: Unit) -> bool:
	var legs := Quad.intact(u) if u.def.quad else (Spa.has(u, Spa.MANEUVERING_ACE) and u.legs_destroyed() == 0 \
			and u.vehicle == null and u.ba == null and u.asset == null)
	return legs and not u.prone and not u.on_roof


static func extra_mp(u: Unit) -> int:
	return EXTRA_MP - (1 if u.def.quad and Spa.has(u, Spa.MANEUVERING_ACE) else 0)


## Is the step from `from` to `to` facing `f` a rearward one (straight back
## or a backward shift)?
static func is_backward(from: Vector2i, to: Vector2i, f: int) -> bool:
	for d in [2, 3, 4]:
		if to == Hex.neighbor(from, Hex.rotate(f, d)):
			return true
	return false


## Sideways steps from hex `c` facing `f`: [[key, mp], ...].
static func steps(state: GameState, u: Unit, c: Vector2i, f: int, mode: int, indexed: Variant = null) -> Array:
	var out := []
	if not allowed(u):
		return out
	var dirs := [-1, 1]
	if mode == MoveMode.Kind.WALK:
		dirs.append_array([-2, 2])
	for d: int in dirs:
		var to := Hex.neighbor(c, Hex.rotate(f, d))
		var back := absi(d) == 2
		var mp := MoveCost.enter_cost(state.map, c, to, mode, MovePlanner.max_level_change(u, back))
		if mp != MoveCost.PROHIBITED and MovePlanner.can_pass(state, u, to, indexed):
			out.append([MoveOptions.key(to, f), mp + extra_mp(u)])
	return out
