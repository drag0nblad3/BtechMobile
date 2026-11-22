class_name BaRiders
extends RefCounted
## Battle armor riding an OmniMech sits on its torso, one trooper per spot
## (the Transport Positions table on the sheets): 1 right torso, 2 left
## torso, 3 right torso rear, 4 left torso rear, 5 center torso rear,
## 6 center torso. A hit on a spot with a living trooper strikes that
## trooper first; what it doesn't soak goes on to the 'Mech.
## TODO(rules): Total Warfare mechanized battle armor from general knowledge;
## here damage past the trooper's armor carries on to the 'Mech.

const SPOTS := [[Location.RT, false], [Location.LT, false], [Location.RT, true],
		[Location.LT, true], [Location.CT, true], [Location.CT, false]]


## The riding squad's trooper (0-based) at `loc`/`rear` of `carrier`.
static func at(state: GameState, carrier: Unit, loc: int, rear: bool) -> Dictionary:
	for r in AssetTransport.riders(state, carrier):
		if r.ba == null:
			continue
		for i in r.ba.troopers.size():
			if i < SPOTS.size() and SPOTS[i][0] == loc and SPOTS[i][1] == rear and r.ba.is_alive(i):
				return {"squad": r, "trooper": i}
	return {}


## Damage left for the 'Mech after a rider in the way soaks what it can.
static func shield(state: GameState, emit: Callable, carrier: Unit, loc: int, rear: bool,
		amount: int, source_id: int, source: String) -> int:
	var hit := at(state, carrier, loc, rear)
	if hit.is_empty():
		return amount
	var sq: Unit = hit["squad"]
	var soak: int = sq.ba.troopers[hit["trooper"]] + 1  # its armor, then the trooper
	BaDamage.hit_trooper(emit, sq, hit["trooper"], amount, source_id, source)
	return maxi(0, amount - soak)
