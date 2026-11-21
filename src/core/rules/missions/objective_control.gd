class_name ObjectiveControl
extends RefCounted
## Who holds an objective (book p. 232): the side with more non-crippled
## 'Mechs inside its control radius. Prone, immobile and withdrawing 'Mechs
## don't count. Ties mean nobody.


static func controller(state: GameState, o: Objective) -> int:
	var counts := {}
	for u in state.units:
		if counts_for_control(state, u) and o.in_radius(u.coord):
			counts[u.side] = int(counts.get(u.side, 0)) + 1
	var best := -1
	var best_n := 0
	var tie := false
	for side: int in counts:
		if counts[side] > best_n:
			best = side
			best_n = counts[side]
			tie = false
		elif counts[side] == best_n:
			tie = true
	return -1 if tie else best


static func counts_for_control(state: GameState, u: Unit) -> bool:
	var ms := state.mission
	if u.destroyed or ms.exited.has(u.id) or ms.crippled.has(u.id):
		return false
	return not u.prone and not ToHitCalc.is_immobile(u)


## Victory Points `side` earns this End Phase from the objectives it holds.
static func score(state: GameState, side: int) -> int:
	var m := state.mission.def
	var held := 0
	var held_own := 0
	var held_enemy := 0
	var vp := 0
	for o in m.objectives:
		if controller(state, o) != side:
			continue
		held += 1
		vp += o.vp
		if o.owner == side:
			held_own += 1
		elif o.owner >= 0:
			held_enemy += 1
	match m.scoring:
		"each":
			return vp
		"pairs":
			return mini(held_own, held_enemy)
		"threshold":
			return 2 if held >= 3 else (1 if held == 2 else 0)
	return 0
