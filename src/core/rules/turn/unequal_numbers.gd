class_name UnequalNumbers
extends RefCounted
## Who acts when in an alternating phase (book p. 41, Unequal Numbers).
## Sides take turns in initiative order (loser first). When one side has more
## eligible 'Mechs, it spreads them over the smaller side's turns as evenly as
## possible, extra 'Mechs first: 18 against 10 is eight double turns, then
## singles; 14 against 5 is 3, 3, 3, 3, 2.


## Activation list for one phase: one side id per unit activation.
## counts: side -> eligible 'Mechs at the start of the phase.
static func order(counts: Dictionary, initiative_order: Array[int]) -> Array[int]:
	var out: Array[int] = []
	var turns := 0
	for s: int in initiative_order:
		var n: int = counts.get(s, 0)
		if n > 0 and (turns == 0 or n < turns):
			turns = n
	for t in turns:
		for s: int in initiative_order:
			for i in group_size(counts.get(s, 0), turns, t):
				out.append(s)
	return out


## Units a side with `units` 'Mechs moves on turn t of `turns`.
static func group_size(units: int, turns: int, t: int) -> int:
	if units <= 0 or turns <= 0:
		return 0
	@warning_ignore("integer_division")
	var base := units / turns
	return base + (1 if t < units % turns else 0)


## Eligible 'Mechs per side: alive and not yet done this phase.
static func eligible(state: GameState, done: Callable) -> Dictionary:
	var counts := {}
	for u in state.units:
		if u.can_act() and not done.call(u):
			counts[u.side] = int(counts.get(u.side, 0)) + 1
	for u in state.reserves:  # combat drops take a movement turn
		if CombatDrop.ready(state, u):
			counts[u.side] = int(counts.get(u.side, 0)) + 1
	return counts
