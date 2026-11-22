class_name GaussWeapons
extends RefCounted
## Advanced Gauss weapons. Heavy and improved heavy Gauss rifles kick hard:
## a 'Mech that moved this turn makes a piloting roll after firing one
## (+2 light, +1 medium, 0 heavy, -1 assault). A hyper-assault Gauss (HAG)
## fires a cluster of slugs: +2 to its cluster roll at short range, -2 at long.
## TODO(rules): from MegaMek's rules engine, not in the Core Rulebook.

const PSR_MOD := {"Light": 2, "Medium": 1, "Heavy": 0, "Assault": -1}
const SHORT_BONUS := 2
const LONG_PENALTY := -2


static func cluster_mod(d: WeaponDef, dist: int) -> int:
	if not d.range_cluster:
		return 0
	match d.bracket(dist):
		WeaponDef.Bracket.SHORT:
			return SHORT_BONUS
		WeaponDef.Bracket.LONG:
			return LONG_PENALTY
	return 0


## Queues the recoil roll; it is made with the end-of-phase rolls.
static func after_firing(u: Unit, d: WeaponDef) -> void:
	if d.fire_psr and u.move_mode >= 0:
		u.psr_pending.append({"reason": "fired a %s after moving" % d.name,
				"mod": int(PSR_MOD[u.def.weight_class()])})
