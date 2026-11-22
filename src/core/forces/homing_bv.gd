class_name HomingBv
extends RefCounted
## Errata v0.2 TAG surcharge: each TAG a 'Mech carries adds 50 BV for every
## homing-capable Arrow IV launcher in its force, before skill and C3.
## Homing-capable here: an Arrow IV on a design that carries homing ammo.
## TODO(rules): a rear-facing TAG should count half; Assets with TAG.

const PER_LAUNCHER := 50


## Arrow IV launchers loaded with homing ammo across `defs`.
static func launchers(defs: Array) -> int:
	var n := 0
	for d: UnitDef in defs:
		if d.ammo_mounts.any(func(a: Dictionary) -> bool: return a["weapon"].artillery and a["kind"] == ArrowHoming.KIND):
			n += d.weapon_mounts.filter(func(m: Dictionary) -> bool: return m["weapon"].artillery).size()
	return n


## TAG instances on a design.
static func tags(def: UnitDef) -> int:
	var n := def.inert.filter(func(g: Dictionary) -> bool: return Tag.RANGES.has(g["kind"])).size()
	return n + (1 if def.c3_master_loc >= 0 else 0)


## Base BV this design adds in a force with `n` homing launchers.
static func surcharge(def: UnitDef, n: int) -> int:
	return PER_LAUNCHER * n * tags(def) if def.asset == null else 0
