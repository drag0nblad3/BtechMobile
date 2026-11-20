class_name AmmoExplosion
extends RefCounted
## An ammo bin explodes: all remaining shots hit its location's internal
## structure (armor doesn't help), and the pilot takes 2 hits.


static func explode(state: GameState, dice: Dice, emit: Callable, u: Unit, bin: AmmoBin) -> void:
	var dmg := bin.explosion_damage()
	bin.shots = 0
	bin.destroyed = true
	if dmg <= 0:
		return
	var saved := u.armor[bin.loc]
	var saved_rear := u.rear_armor[bin.loc]
	u.armor[bin.loc] = 0
	u.rear_armor[bin.loc] = 0
	var steps := Damage.apply(u, bin.loc, dmg)
	# Armor is bypassed only in the exploding location.
	if not u.is_location_destroyed(bin.loc):
		u.armor[bin.loc] = saved
		u.rear_armor[bin.loc] = saved_rear
	emit.call(GameEvent.AMMO_EXPLOSION, {"unit_id": u.id, "loc": bin.loc,
			"ammo": bin.weapon.name, "damage": dmg, "steps": steps})
	PilotDamage.wound(dice, emit, u, 2, "ammo explosion")
	Damage.announce(emit, u)
	CriticalHits.after_damage(state, dice, emit, u, steps, false)
