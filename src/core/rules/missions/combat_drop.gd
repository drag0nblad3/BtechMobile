class_name CombatDrop
extends RefCounted
## Combat drops (book pp. 227-228). 'Mechs held in reserve (`state.reserves`)
## arrive from their drop turn on, in the Movement Phase, when their turn to
## move comes: aim at any hex and make a piloting roll (no modifiers from the
## hex; wind +1). Success lands it there, shoving aside anyone in the way.
## Failure scatters it 1D3 x the margin of failure in a random direction and
## it falls as many levels as the margin (+1 in wind); failing by 4 or more,
## or scattering off the map, destroys it. A 'Mech that dropped can't act
## that turn and counts as having moved fast (+3 to hit it).
## TODO(rules): landings happen at once (the book lands successful drops at
## the end of the Movement Phase); scattering onto a 'Mech is a normal fall
## plus a shove, not a fall from above onto it.

const LANDED_MOD := 3
const DEADLY_MARGIN := 4


static func reserve(state: GameState, u: Unit, turn: int) -> void:
	state.units.erase(u)
	if not state.reserves.has(u):
		state.reserves.append(u)
	u.drop_turn = turn
	u.coord = Hex.INVALID


static func ready(state: GameState, u: Unit) -> bool:
	return state.reserves.has(u) and state.turn >= u.drop_turn and state.phase == Phase.Kind.MOVEMENT


## Ready reserves of `side`.
static func ready_units(state: GameState, side: int) -> Array[Unit]:
	var out: Array[Unit] = []
	for u in state.reserves:
		if u.side == side and ready(state, u):
			out.append(u)
	return out


## Drops `u` aiming at `c` with `facing`. Returns false if it can't.
static func drop(state: GameState, dice: Dice, emit: Callable, u: Unit, c: Vector2i, facing: int) -> bool:
	if not ready(state, u) or state.map.get_tile(c) == null:
		return false
	var th := Psr.standing_mods(u)
	Wind.add(th, state, u)  # off the map: only the wind applies
	var roll := dice.roll_2d6()
	var margin := th.target() - roll
	emit.call(GameEvent.PSR, {"unit_id": u.id, "roll": roll, "need": th.target(), "ok": margin <= 0,
			"reason": "combat drop landing", "mods": th.mods})
	var at := c
	var last := c  # last hex on the map, where an off-map scatter is shown
	if margin > 0:
		var dir := dice.d6() - 1
		var dist := (1 + dice.pick(3)) * margin
		for i in dist:
			at = Hex.neighbor(at, dir)
			if state.map.get_tile(at) != null:
				last = at
	state.reserves.erase(u)
	state.units.append(u)
	u.coord = at if state.map.get_tile(at) != null else last
	u.facing = facing
	u.landed = true
	u.has_moved = true
	u.has_fired = true
	u.has_physical = true
	emit.call(GameEvent.COMBAT_DROP, {"unit_id": u.id, "aim": c, "hex": u.coord, "margin": maxi(0, margin),
			"off_map": state.map.get_tile(at) == null})
	if margin >= DEADLY_MARGIN or state.map.get_tile(at) == null:
		at = u.coord
		u.destroyed = true
		u.destroyed_reason = "combat drop went wrong" if margin >= DEADLY_MARGIN else "scattered off the battlefield"
		Damage.announce(emit, u)
		return true
	for other in state.units.duplicate():
		if other != u and other.coord == at and not other.destroyed:
			Displacement.push_nearest(state, dice, emit, other, dice.d6() - 1)
	if margin > 0:
		Fall.fall(state, dice, emit, u, margin + (1 if state.conditions.wind else 0), "botched combat drop")
		PilotDamage.resolve_owed(state, dice, emit)
	return true
