class_name CombatIntuition
extends RefCounted
## Combat Intuition (Campaign Operations p. 73): the player can have the
## warrior focus in the End Phase. It costs 1 pilot hit (no consciousness
## roll), and next turn the unit acts after every other unit in each phase.
## TODO(rules): the alternative, pre-empting one chosen enemy unit, is not offered.

const WHY := "focusing on the enemy (Combat Intuition)"


## Why the unit can't focus now, or "".
static func problem(u: Unit) -> String:
	if u == null or not Spa.has(u, Spa.COMBAT_INTUITION):
		return "No Combat Intuition."
	if u.destroyed or u.pilot.is_dead() or not u.pilot.conscious:
		return "The MechWarrior can't focus."
	return ""


## End Phase: pays for a requested focus and marks next turn.
static func apply(state: GameState, dice: Dice, emit: Callable, u: Unit) -> void:
	if not u.intuition_request:
		return
	u.intuition_request = false
	if problem(u) != "":
		return
	var owed := u.pilot.roll_owed
	PilotDamage.wound(dice, emit, u, 1, WHY)
	u.pilot.roll_owed = owed  # no consciousness roll for this hit
	if not u.destroyed:
		u.intuition_turn = state.turn + 1


static func waiting(state: GameState, u: Unit) -> bool:
	return u.intuition_turn == state.turn and state.turn > 0


## Takes waiting units out of `counts` and returns their sides, one entry
## per unit, in Initiative order (loser first).
static func late_sides(state: GameState, done: Callable, counts: Dictionary) -> Array[int]:
	var out: Array[int] = []
	for s: int in state.initiative_order:
		for u in state.units_of_side(s):
			if waiting(state, u) and u.can_act() and not done.call(u):
				counts[s] = int(counts.get(s, 0)) - 1
				out.append(s)
	for s: int in counts.keys():
		if int(counts[s]) <= 0:
			counts.erase(s)
	return out


## May `u` act at this point of the phase?
static func may_go(state: GameState, u: Unit) -> bool:
	return not waiting(state, u) or state.late_from < 0 or state.order_index >= state.late_from
