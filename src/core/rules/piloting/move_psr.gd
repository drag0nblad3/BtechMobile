class_name MovePsr
extends RefCounted
## Piloting rolls a move costs (book pp. 46-51, 110-113).
## Action rolls happen the moment the hex is entered, and a failure ends the
## move there with a fall: running into depth 1+ water, entering rubble, a
## backward level change, landing a jump in water. Mode rolls come at the end
## of the 'Mech's move: running at least one hex with a gyro hit, a hip hit or
## a destroyed leg (one each); jumping with a gyro hit, a destroyed leg, or
## actuator damage in a leg (one per leg); any jump in odd gravity (Gravity); landing a jump in the wind (Wind).
## Jump rolls are marked "jump" so the wind's general +1 skips them.


## [{index, reason, mod, levels, back}] in path order. `index` is the path
## position of the step; `back` means a failure falls in the hex left behind.
static func action_rolls(state: GameState, u: Unit, path: Array[Vector3i], from: Vector3i,
		mode: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if mode == MoveMode.Kind.JUMP:
		if path.is_empty():
			return out
		var land := state.map.get_tile(MoveOptions.coord_of(path[-1]))
		if land != null and land.is_water():
			out.append({"index": path.size() - 1, "reason": "jumping into depth %d water" % land.depth,
					"mod": 0, "levels": land.depth, "back": false})
		return out
	var prev := from
	for i in path.size():
		var k := path[i]
		var c := MoveOptions.coord_of(k)
		var pc := MoveOptions.coord_of(prev)
		if c != pc:
			var src := state.map.get_tile(pc)
			var dst := state.map.get_tile(c)
			var backward := c == Hex.neighbor(pc, Hex.rotate(k.z, 3))
			if backward and MoveCost.level_change(src, dst) > 0:
				out.append({"index": i, "reason": "backward level change", "mod": 0, "levels": 0,
						"back": dst.floor_level() > src.floor_level()})
			if mode == MoveMode.Kind.RUN and dst.is_water():
				out.append({"index": i, "reason": "running into depth %d water" % dst.depth,
						"mod": 0, "levels": 0, "back": false})
			if dst.terrain.id == "rubble":
				out.append({"index": i, "reason": "entering rubble", "mod": 0, "levels": 0, "back": false})
		prev = k
	return out


## Rolls owed at the end of the move; added to Unit.psr_pending.
static func after_move(u: Unit, mode: int, hexes: int, c: Conditions = null, dfa := false) -> void:
	if mode == MoveMode.Kind.RUN and hexes > 0:
		if u.gyro_hits > 0:
			u.psr_pending.append({"reason": "running with a damaged gyro", "mod": 0})
		for i in u.hip_hits():
			u.psr_pending.append({"reason": "running with a broken hip", "mod": 0})
		for i in u.legs_destroyed():
			u.psr_pending.append({"reason": "running on one leg", "mod": 0})
	if mode == MoveMode.Kind.JUMP:
		for extra in [Gravity.jump_roll(c), Wind.landing_roll(c, dfa)]:
			if not extra.is_empty():
				extra["jump"] = true
				u.psr_pending.append(extra)
		if u.gyro_hits > 0:
			u.psr_pending.append({"reason": "landing a jump with a damaged gyro", "mod": 0, "jump": true})
		for loc in [Location.LL, Location.RL]:
			if u.is_location_out(loc):
				u.psr_pending.append({"reason": "landing a jump on one leg", "mod": 0, "jump": true})
			elif _leg_hits(u, loc) > 0:
				u.psr_pending.append({"reason": "landing a jump on a damaged leg", "mod": 0, "jump": true})


static func _leg_hits(u: Unit, loc: int) -> int:
	var n := 0
	for s: CritSlot in u.slots[loc]:
		if s.kind == CritSlot.Kind.ACTUATOR and s.hit:
			n += 1
	return n
