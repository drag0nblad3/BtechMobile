class_name C3i
extends RefCounted
## Improved C3 (C3i): no Master. Up to six 'Mechs of a side with C3i
## computers share one network and its range bracket (C3.improve). A
## member's network is down while fewer than two members work; hostile ECM
## around a member degrades its link like standard C3.
## Book p. 199. TODO(rules): 2.5 t / 2 slots each is MegaMek construction
## data; a side with both C3 and C3i only networks its C3.

const TONS := 2.5
const SLOTS := 2
const MAX_MEMBERS := 6


static func has(def: UnitDef) -> bool:
	return def.c3i_loc >= 0


## Roster indexes of the C3i network (first six with C3i), [] for fewer than two.
static func form(defs: Array) -> Array[int]:
	var out: Array[int] = []
	for i in defs.size():
		if has(defs[i]) and out.size() < MAX_MEMBERS:
			out.append(i)
	if out.size() < 2:
		out.clear()
	return out


static func network(state: GameState, u: Unit) -> Array[Unit]:
	var side: Array = state.units.filter(func(o: Unit) -> bool: return o.side == u.side)
	var out: Array[Unit] = []
	for i in form(side.map(func(o: Unit) -> UnitDef: return o.def)):
		out.append(side[i])
	if not out.has(u) or out.filter(func(m: Unit) -> bool: return C3.working(m)).size() < 2:
		out.clear()
	return out
