class_name ProneMoves
extends RefCounted
## Prone movement (book pp. 46, 51). A prone 'Mech that can't stand may only
## turn in its hex, 1 MP a hexside; a destroyed gyro allows one hexside a turn.
## A 'Mech that didn't jump may drop prone at the end of its move for 1 MP.
## TODO(rules): a prone 'Mech that could stand can't yet choose to turn
## without standing (the planner always assumes it stands).

const DROP_MP := 1


## Turn-only options for a prone 'Mech that can't stand.
static func turn_options(unit: Unit, mode: int) -> MoveOptions:
	var opts := MoveOptions.new()
	opts.unit = unit
	opts.mode = mode
	opts.turn_only = true
	opts.budget = MoveMode.budget(unit, mode) + 2  # no standing attempt to pay for
	var start := opts.start_key()
	opts.cost[start] = 0
	opts.can_end[start] = true
	var most := 1 if unit.gyro_hits >= CritEffects.GYRO_KILL else 3
	for f in 6:
		var t := Hex.turn_cost(unit.facing, f)
		if t == 0 or t > most or t > opts.budget:
			continue
		var k := MoveOptions.key(unit.coord, f)
		opts.cost[k] = t
		opts.prev[k] = start
		opts.can_end[k] = true
	return opts


## May the unit drop prone after ending its move at `k`?
static func can_drop_after(opts: MoveOptions, k: Vector3i) -> bool:
	if opts.mode == MoveMode.Kind.JUMP or opts.turn_only or k == opts.minimum_move:
		return false
	return opts.can_reach(k) and int(opts.cost[k]) + DROP_MP <= opts.budget


static func drop(emit: Callable, unit: Unit) -> void:
	unit.prone = true
	emit.call(GameEvent.WENT_PRONE, {"unit_id": unit.id})
