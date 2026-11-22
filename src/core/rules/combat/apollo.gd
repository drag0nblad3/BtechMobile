class_name Apollo
extends RefCounted
## Apollo MRM fire-control system (book p. 197), linked to one MRM launcher.
## Standard-fire mode: the launcher loses the MRM's -1 on the Cluster Hits
## roll. A critical hit on the Apollo slot ends that. ECM doesn't affect it.
## TODO(rules): saturation mode (an area-effect attack on a hex) is not
## modelled. 1 t and 1 slot per launcher are MegaMek construction data.

const TONS := 1.0


static func working(w: MountedWeapon) -> bool:
	return w.apollo and not w.apollo_lost


## The launcher's own Cluster Hits modifier, after Apollo.
static func cluster_mod(w: MountedWeapon, d: WeaponDef) -> int:
	return 0 if working(w) and d.cluster_mod < 0 else d.cluster_mod
