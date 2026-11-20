class_name AmmoExplosion
extends RefCounted
## An ammo bin explodes (book pp. 95-96): its remaining shots' damage, capped
## at 20, goes straight into internal structure and transfers inward
## structure-to-structure. If the uncapped damage was over 20 and the last
## location hit survives, it loses its armor (rear armor for a torso).
## The MechWarrior takes 1 hit from the feedback.

const CAP := 20


static func explode(state: GameState, dice: Dice, emit: Callable, u: Unit, bin: AmmoBin) -> void:
	var base := bin.explosion_damage()
	bin.shots = 0
	bin.destroyed = true
	if base <= 0:
		return
	var dmg := mini(base, CAP)
	var steps := Damage.apply_internal(u, bin.loc, dmg)
	if base > CAP and not steps.is_empty() and not u.destroyed:
		var last: int = steps[-1]["loc"]
		if not u.is_location_destroyed(last):
			if Location.HAS_REAR.has(last):
				u.rear_armor[last] = 0
			else:
				u.armor[last] = 0
	emit.call(GameEvent.AMMO_EXPLOSION, {"unit_id": u.id, "loc": bin.loc,
			"ammo": bin.weapon.name, "damage": dmg, "base": base, "steps": steps})
	PilotDamage.wound(dice, emit, u, 1, "ammo explosion")
	Damage.announce(emit, u)
	CriticalHits.after_damage(state, dice, emit, u, steps, false)
