class_name AssetStacking
extends RefCounted
## Who may share a hex (book pp. 49, 143). One 'Mech or vehicle per hex.
## Infantry Assets can join it: a 'Mech or vehicle hex holds at most one
## friendly and one enemy infantry Asset; an infantry-only hex two of each.
## 'Mechs move through hexes holding Assets of either side; Assets move
## through friends only, and VTOLs through anything (errata).


static func is_infantry(u: Unit) -> bool:
	return u.ba != null or (u.asset != null and u.asset.card.is_infantry())


## One synchronous movement search: positions cannot change during the plan.
static func occupancy(state: GameState, u: Unit) -> Dictionary:
	var out := {}
	for o: Unit in state.units:
		if o != u and not o.destroyed and o.carrier_id() < 0 and BaSwarm.on(o) < 0:
			out.get_or_add(o.coord, []).append(o)
	return out


## Living units in a hex other than `u` (riders inside an APC don't count).
static func others(state: GameState, u: Unit, c: Vector2i, indexed: Variant = null) -> Array[Unit]:
	var out: Array[Unit] = []
	if indexed != null:
		out.assign(indexed.get(c, []))
		return out
	for o in state.units:
		if o != u and o.coord == c and not o.destroyed and o.carrier_id() < 0 and BaSwarm.on(o) < 0:
			out.append(o)
	return out


## May `u` finish its move in hex `c`?
static func can_end(state: GameState, u: Unit, c: Vector2i, indexed: Variant = null) -> bool:
	var big := 0
	var inf_friend := 0
	var inf_enemy := 0
	for o in others(state, u, c, indexed):
		if is_infantry(o):
			if o.side == u.side:
				inf_friend += 1
			else:
				inf_enemy += 1
		else:
			big += 1
	if not is_infantry(u):
		return big == 0 and inf_friend <= 1 and inf_enemy <= 1
	var cap := 1 if big > 0 else 2
	return big <= 1 and inf_friend < cap and inf_enemy <= cap


## May `u` move through hex `c` on its way somewhere else?
static func can_pass(state: GameState, u: Unit, c: Vector2i, indexed: Variant = null) -> bool:
	if u.asset != null and u.asset.card.kind == AssetCard.VTOL:
		return true
	for o in others(state, u, c, indexed):
		if o.side == u.side:
			continue
		if u.asset == null and o.asset != null:
			continue  # no Asset hinders an enemy 'Mech (p. 143)
		return false
	return true
