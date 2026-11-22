class_name BaDamage
extends RefCounted
## Damage to a battle armor squad: each packet strikes one living trooper
## (1D6, rerolled until it names one). It strips that trooper's armor; any
## damage past the armor kills the trooper, and the rest is lost. When the
## last trooper falls the squad is destroyed, and every kill shrinks the
## squad's cluster rolls.
## TODO(rules): Total Warfare battle armor damage from general knowledge.


static func take(dice: Dice, emit: Callable, u: Unit, amount: int, source_id: int, source: String) -> void:
	if u.ba.alive() == 0:
		return
	var i := dice.d6() - 1
	while not u.ba.is_alive(i):
		i = dice.d6() - 1
	hit_trooper(emit, u, i, amount, source_id, source)


## `amount` damage to trooper `i` (0-based).
static func hit_trooper(emit: Callable, u: Unit, i: int, amount: int, source_id: int, source: String) -> void:
	var left: int = u.ba.troopers[i]
	var killed := amount > left
	u.ba.troopers[i] = BaState.DEAD if killed else left - amount
	emit.call(GameEvent.DAMAGE, {"unit_id": u.id, "source_id": source_id, "source": source,
			"amount": amount, "ba": true, "trooper": i + 1, "killed": killed,
			"armor_left": maxi(u.ba.troopers[i], 0), "alive": u.ba.alive(), "steps": []})
	if killed:
		resize_weapons(u)
		if u.ba.alive() == 0:
			Damage.destroy_unit(u, "every trooper is down")
	Damage.announce(emit, u)


## Fewer troopers, fewer shots in each of the squad's cluster rolls.
static func resize_weapons(u: Unit) -> void:
	var spec := u.def.battle_armor
	for i in mini(u.weapons.size(), spec.weapons.size()):  # the leg attack comes after
		u.weapons[i].def.missiles = spec.per_trooper(i) * u.ba.alive()
