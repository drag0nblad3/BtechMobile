class_name GaussWeapons
extends RefCounted
## Hyper-assault Gauss rifles (HAG, p. 184) fire a cluster of slugs: +2 to
## the Cluster Hits roll at short range, -2 at long (results stay 2-12).
## Heavy, improved heavy and light Gauss rifles have no special rules beyond
## the Gauss rifle's (p. 184). TODO(rules): HAG flak attacks not modelled.

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
