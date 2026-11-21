class_name MobileObjectives
extends RefCounted
## Mobile objectives (book pp. 232-233). A standing, mobile 'Mech with a
## working hand picks one up when it ends its move on the counter; that arm
## can't shoot or punch while it carries it, and a carried counter is held
## by its carrier wherever it goes. The counter is dropped in the carrier's
## hex when the 'Mech falls, goes prone, is destroyed, can't move or loses
## that hand; after a phase in which it took damage it rolls to hang on
## (piloting, -2 with two working hands; failing doesn't make it fall).
## Only one counter fits in a hex: one dropped onto another pushes it a hex.
## TODO(rules): picking up from the hex next door, choosing to set a counter
## down in the End Phase, and choosing which arm carries it.


static func carrier(state: GameState, o: Objective) -> Unit:
	return state.unit_by_id(o.carrier_id) if o.carrier_id >= 0 else null


static func carried_by(state: GameState, u: Unit) -> Objective:
	if state.mission.def == null:
		return null
	for o in state.mission.def.objectives:
		if o.carrier_id == u.id:
			return o
	return null


## The arm `u` would carry with (a working hand), or -1.
static func free_hand(u: Unit) -> int:
	for arm in [Location.LA, Location.RA]:
		if u.has_working_actuator(arm, "hand"):
			return arm
	return -1


## After `u` moves: picks up a free mobile counter in its hex.
static func after_move(state: GameState, emit: Callable, u: Unit) -> void:
	if state.mission.def == null or u.destroyed or u.prone or ToHitCalc.is_immobile(u) \
			or carried_by(state, u) != null or free_hand(u) < 0:
		return
	for o in state.mission.def.objectives:
		if o.mobile and o.carrier_id < 0 and not o.destroyed and o.coord == u.coord:
			o.carrier_id = u.id
			u.carry_arm = free_hand(u)
			u.club = ""  # a club is dropped to free the hand
			emit.call(GameEvent.OBJECTIVE, {"kind": "picked_up", "unit_id": u.id, "hex": o.coord})
			return


## After any action: carried counters follow their carriers, and are dropped
## (and may break) when the carrier can't hold on any more.
static func check(state: GameState, dice: Dice, emit: Callable) -> void:
	if state.mission.def == null:
		return
	for o in state.mission.def.objectives:
		var c := carrier(state, o)
		if c == null:
			continue
		if state.mission.exited.has(c.id):
			continue  # carried off the map: it stays theirs
		o.coord = c.coord
		if c.destroyed:
			drop(state, dice, emit, o, "its carrier was destroyed", true)
		elif not c.has_working_actuator(c.carry_arm, "hand"):
			drop(state, dice, emit, o, "the carrying hand was knocked out", true)
		elif c.prone:
			drop(state, dice, emit, o, "its carrier fell", true)  # going prone on purpose drops it first (drop_prone)
		elif ToHitCalc.is_immobile(c):
			drop(state, dice, emit, o, "its carrier can't move", true)


## End of a phase: carriers that took damage roll to keep hold.
static func end_of_phase(state: GameState, dice: Dice, emit: Callable) -> void:
	if state.mission.def == null:
		return
	for o in state.mission.def.objectives:
		var c := carrier(state, o)
		if c == null or c.destroyed or c.damage_this_phase <= 0 or state.mission.exited.has(c.id):
			continue
		var both := c.has_working_actuator(Location.LA, "hand") and c.has_working_actuator(Location.RA, "hand")
		if not Psr.roll(dice, emit, c, "took damage while carrying an objective", -2 if both else 0, state):
			drop(state, dice, emit, o, "it was knocked loose", true)


## `u` goes prone on purpose: it sets its counter down without risking it.
static func drop_prone(state: GameState, dice: Dice, emit: Callable, u: Unit) -> void:
	var o := carried_by(state, u)
	if o != null:
		drop(state, dice, emit, o, "its carrier lay down", false)


## Puts `o` down in its carrier's hex, pushing aside any counter already there.
static func drop(state: GameState, dice: Dice, emit: Callable, o: Objective, why: String, risky: bool) -> void:
	var c := carrier(state, o)
	if c != null:
		o.coord = c.coord
		c.carry_arm = -1
	o.carrier_id = -1
	emit.call(GameEvent.OBJECTIVE, {"kind": "dropped", "hex": o.coord, "why": why})
	if risky:
		FragileObjectives.check(state, dice, emit, o, why)
	for other in state.mission.def.objectives:
		if other != o and not other.destroyed and other.carrier_id < 0 and other.coord == o.coord:
			var to := Hex.neighbor(o.coord, c.facing if c else 0)
			if state.map.get_tile(to) == null:
				continue  # TODO(rules): pushed off the map: stays in the last hex
			var lvl := state.map.get_tile(other.coord).floor_level()
			other.coord = to
			emit.call(GameEvent.OBJECTIVE, {"kind": "pushed", "hex": to})
			if other.mobile and state.map.get_tile(to).floor_level() != lvl:
				FragileObjectives.check(state, dice, emit, other, "it was knocked down a level")
