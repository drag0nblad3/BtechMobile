class_name Gyro
extends RefCounted
## Gyro types (pp. 98, 204). Standard, compact and XL gyros follow the usual
## rules: the first hit is +2 to piloting rolls and forces a roll, running or
## jumping with it forces one too, and the second hit destroys it. A
## heavy-duty gyro is +1 per destroyed slot, forces no roll when hit or when
## running, a +2 roll when jumping, and is destroyed by its fourth hit.
## TODO(rules): slots (standard 4, XL 6, compact 2, heavy-duty 4) and weight
## (rating / 100 rounded up; XL half, compact 1.5x, heavy-duty 2x, each
## rounded up to the half ton) are construction data.

const SLOTS := {"standard": 4, "xl": 6, "compact": 2, "heavy_duty": 4}
const WEIGHT := {"standard": 1.0, "xl": 0.5, "compact": 1.5, "heavy_duty": 2.0}


static func slots(def: UnitDef) -> int:
	return SLOTS.get(def.gyro_type, 4)


static func tons(def: UnitDef) -> float:
	var base := float(ceili(def.tonnage * def.walk_mp / 100.0))
	return ceilf(snappedf(base * WEIGHT.get(def.gyro_type, 1.0) * 2.0, 0.0001)) / 2.0


static func heavy_duty(def: UnitDef) -> bool:
	return def.gyro_type == "heavy_duty"


## Hits that destroy it.
static func kill_hits(def: UnitDef) -> int:
	return 4 if heavy_duty(def) else 2


static func destroyed(u: Unit) -> bool:
	return u.gyro_hits >= kill_hits(u.def)


## Lasting piloting modifier from gyro damage.
static func psr_mod(u: Unit) -> int:
	if u.gyro_hits == 0:
		return 0
	return u.gyro_hits if heavy_duty(u.def) else 2


## Does a gyro hit (not the killing one) force a roll right away? Does
## running with gyro damage?
static func hit_forces_roll(def: UnitDef) -> bool:
	return not heavy_duty(def)


static func run_forces_roll(u: Unit) -> bool:
	return u.gyro_hits > 0 and not heavy_duty(u.def)


## Modifier on the roll for landing a jump with gyro damage (heavy-duty +2).
static func jump_roll_mod(u: Unit) -> int:
	return 2 if heavy_duty(u.def) else 0
