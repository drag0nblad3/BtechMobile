class_name C3Boosted
extends RefCounted
## Boosted C3 (C3BS, p. 199): works like standard C3, but only Angel ECM
## (EcmTypes) can degrade a boosted member's link. In a mixed
## network a standard member is still degraded by hostile ECM around it, and
## a standard Master in any hostile ECM degrades the whole network.
## TODO(rules): sizes (boosted Master 6 t / 6 slots, Slave 3 t / 2 slots) are
## construction data, not in the Core Rulebook.

const MASTER_TONS := 6.0
const MASTER_SLOTS := 6
const SLAVE_TONS := 3.0
const SLAVE_SLOTS := 2


static func master_slots(def: UnitDef) -> int:
	return MASTER_SLOTS if def.c3_boosted else C3.MASTER_SLOTS


static func slave_slots(def: UnitDef) -> int:
	return SLAVE_SLOTS if def.c3_boosted else 1


static func tons(def: UnitDef) -> float:
	if def.c3_master_loc >= 0:
		return MASTER_TONS if def.c3_boosted else C3.MASTER_TONS
	if def.c3_slave_loc >= 0:
		return SLAVE_TONS if def.c3_boosted else C3.SLAVE_TONS
	return C3i.TONS if def.c3i_loc >= 0 else 0.0


## Hostile ECM at `u` degrades its link (never for a boosted member).
static func jammed(state: GameState, side: int, u: Unit) -> bool:
	if u.def.c3_boosted:
		return Ecm.hostile_angel_at(state, side, u.coord)
	return Ecm.hostile_at(state, side, u.coord)
