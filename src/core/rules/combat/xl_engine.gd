class_name XlEngine
extends RefCounted
## Extra-light engines (p. 87, p. 99): the engine reaches into both side
## torsos. Engine slots in a destroyed side torso count as destroyed and add
## engine hits, so losing either side torso of an Inner Sphere XL 'Mech
## (3 slots there) is the third engine hit and kills it. Half the weight of
## a standard engine; BV structure counts less (easier to kill).

const BV_STRUCTURE_MULT := 0.75


## Called when a side torso is destroyed; returns the engine hits it added.
static func on_torso_lost(u: Unit, loc: int) -> int:
	if not u.def.is_xl():
		return 0
	var n := 0
	for s: CritSlot in u.slots[loc]:
		if s.kind == CritSlot.Kind.ENGINE and not s.hit:
			s.hit = true
			n += 1
	u.engine_hits += n
	if u.engine_hits >= CritEffects.ENGINE_KILL:
		Damage.destroy_unit(u, "XL engine lost with the %s" % Location.name_of(loc).to_lower())
	return n


## Tons of the engine for a rating: an XL weighs half a standard one,
## rounded up to the half ton. TODO(rules): construction data, not in the
## Core Rulebook.
static func tons(standard_tons: float, xl: bool) -> float:
	if not xl or standard_tons < 0:
		return standard_tons
	return ceilf(standard_tons / 2.0 * 2.0) / 2.0
