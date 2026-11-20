class_name MovePsr
extends RefCounted
## Piloting rolls a move can cost: wading into deep water, running on a
## damaged gyro or hip, landing a jump on damaged legs or gyro. They join
## Unit.psr_pending and are rolled with the others at the end of the phase.
## TODO(rules): verify triggers and modifiers; TW rolls some during the move,
## and skidding on pavement is not modeled.


static func after_move(state: GameState, u: Unit, path: Array[Vector3i], mode: int) -> void:
	var last := Vector2i(-9999, -9999)
	for i in path.size():
		var c := MoveOptions.coord_of(path[i])
		if c == last or (mode == MoveMode.Kind.JUMP and i < path.size() - 1):
			continue
		last = c
		var tile := state.map.get_tile(c)
		if tile != null and tile.is_water():
			u.psr_pending.append({"reason": "entering depth %d water" % tile.depth,
					"mod": clampi(tile.depth - 2, -1, 1)})
	if mode == MoveMode.Kind.RUN and (u.gyro_hits > 0 or u.hip_hits() > 0):
		u.psr_pending.append({"reason": "running on a damaged %s" % ("gyro" if u.gyro_hits > 0 else "hip"), "mod": 0})
	if mode == MoveMode.Kind.JUMP and (u.gyro_hits > 0 or u.leg_actuator_hits() > 0 or u.legs_destroyed() > 0):
		u.psr_pending.append({"reason": "landing a jump on damaged %s" % ("gyro" if u.gyro_hits > 0 else "legs"), "mod": 0})
