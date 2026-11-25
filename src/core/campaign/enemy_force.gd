class_name EnemyForce
extends RefCounted
## Picks an opposing lance of official Inner Sphere 'Mech designs whose
## Battle Value comes closest to a target (Chaos Campaign tracks size the
## enemy as a share of the player's BV, p. 158). Random Assignment Tables
## aren't in the app, so any catalog design may appear. TODO(rules)

const LANCE := 4
const TRIES := 80


## Design ids for side 1 of `fb` (uses that side's skill for BV).
static func pick(fb: ForceBuilder, target_bv: int, rng: RandomNumberGenerator,
		allowed: Array[UnitDef] = []) -> Array[String]:
	var pool := allowed if not allowed.is_empty() else designs(fb.units)
	var best: Array[String] = []
	var best_gap := 1 << 30
	for t in TRIES:
		var ids: Array[String] = []
		var bv := 0
		for i in LANCE:
			var def: UnitDef = pool[rng.randi_range(0, pool.size() - 1)]
			ids.append(def.id)
			bv += fb.unit_bv(1, def)
		var gap := absi(bv - target_bv)
		if gap < best_gap:
			best = ids
			best_gap = gap
	return best


## Inner Sphere 'Mechs from the catalog, OmniMechs and quads left out.
static func designs(db: UnitDb) -> Array[UnitDef]:
	var out: Array[UnitDef] = []
	for def: UnitDef in db.by_id.values():
		if not def.is_support() and not def.is_clan() and not def.omni and not def.quad and not def.id.begins_with("test_"):
			out.append(def)
	out.sort_custom(func(a: UnitDef, b: UnitDef) -> bool: return a.id < b.id)
	return out
