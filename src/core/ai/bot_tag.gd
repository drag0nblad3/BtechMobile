class_name BotTag
extends RefCounted
## Bot TAG: before firing, designates the enemy that the most friendly
## 'Mechs still to fire could hit with indirect fire but can't see.


## The enemy to TAG, or null.
static func choose(state: GameState, u: Unit) -> Unit:
	if Tag.problem(state, u) != "":
		return null
	var best: Unit = null
	var best_score := 0.0
	for e in state.units:
		if e.side == u.side or e.destroyed or Tag.designator(state, u.side, e) != null:
			continue
		var helpers := _helpers(state, u, e)
		if helpers == 0:
			continue
		var th := Tag.to_hit(state, u, e)
		var score := helpers * th.chance()
		if th.possible() and score > best_score:
			best = e
			best_score = score
	return best


## Friendly 'Mechs yet to fire with an indirect weapon in range of `e` but no sight of it.
static func _helpers(state: GameState, u: Unit, e: Unit) -> int:
	var n := 0
	for f in state.units_of_side(u.side):
		if f == u or f.destroyed or f.has_fired or f.asset != null:
			continue
		if not LineOfSight.check(state.map, f, e)["blocked"]:
			continue
		var dist := Hex.distance(f.coord, e.coord)
		if f.weapons.any(func(w: MountedWeapon) -> bool:
				var p := Atm.profile(w)
				return p.indirect and f.can_fire(w) and dist <= p.long_range):
			n += 1
	return n
