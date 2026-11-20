class_name ComponentExplosion
extends RefCounted
## An explosive component blows up on its first critical hit (p. 96, Gauss
## rifles p. 184): 2 damage per slot it fills, handled like an ammo explosion
## (20 cap, CASE, pilot hit) in the location of the slot that was hit.
## TODO(rules): Gauss rifles are always treated as activated (p. 180).

const PER_SLOT := 2


static func damage(w: MountedWeapon) -> int:
	return PER_SLOT * w.def.slots


static func explode(state: GameState, dice: Dice, emit: Callable, u: Unit, w: MountedWeapon, loc: int) -> void:
	w.exploded = true
	var base := damage(w)
	var steps := AmmoExplosion.internal(u, loc, base)
	var dmg := 0
	for s in steps:
		dmg += int(s["structure"]) + int(s["armor"])
	emit.call(GameEvent.AMMO_EXPLOSION, {"unit_id": u.id, "loc": loc, "ammo": w.def.name,
			"component": true, "damage": dmg, "base": base, "steps": steps,
			"case": steps.any(func(s: Dictionary) -> bool: return s.get("case", false))})
	PilotDamage.wound(dice, emit, u, 1, "%s explosion" % w.def.name)
	Damage.announce(emit, u)
	CriticalHits.after_damage(state, dice, emit, u, steps, false)
