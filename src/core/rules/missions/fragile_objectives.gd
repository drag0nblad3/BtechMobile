class_name FragileObjectives
extends RefCounted
## Fragile objectives (book p. 232): each time one is dropped by force, its
## carrier falls or is destroyed, it is pushed down a level, or its hex is
## burning in the End Phase, roll 1D6: on 1-4 it is destroyed.
## TODO(rules): hits from heat-causing weapons and area-effect damage on its
## hex (no area-effect weapons in the game yet).

const BREAKS_ON := 4


## Rolls for `o` if it is fragile. Returns true if it broke.
static func check(state: GameState, dice: Dice, emit: Callable, o: Objective, why: String) -> bool:
	if not o.fragile or o.destroyed:
		return false
	var r := dice.d6()
	var broke := r <= BREAKS_ON
	emit.call(GameEvent.OBJECTIVE, {"kind": "fragile", "hex": o.coord, "roll": r, "broke": broke, "why": why})
	if broke:
		o.destroyed = true
		var c := state.unit_by_id(o.carrier_id) if o.carrier_id >= 0 else null
		if c != null:
			c.carry_arm = -1
		o.carrier_id = -1
	return broke


## End Phase: counters in burning hexes.
static func end_phase(state: GameState, dice: Dice, emit: Callable) -> void:
	var m := state.mission.def
	if m == null:
		return
	for o in m.objectives:
		var t := state.map.get_tile(o.coord)
		if t != null and t.on_fire and not o.destroyed:
			check(state, dice, emit, o, "its hex is on fire")
	var keep: Array[Objective] = []
	for o in m.objectives:
		if not o.destroyed:
			keep.append(o)
	m.objectives = keep
