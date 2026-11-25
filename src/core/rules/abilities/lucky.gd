class_name Lucky
extends RefCounted
## Lucky SPA (Campaign Operations p. 77): each point is one reroll per
## battle of a failed attack roll or piloting roll; the new roll stands.
## TODO(rules): the player picks which rolls to reroll; the app spends a
## point on every failed piloting roll and on a missed attack that needed
## 10 or less from a weapon doing 5 or more damage (our pick).

const WORTH_DAMAGE := 5
const WORTH_NEED := 10


## A reroll for a failed piloting roll, or -1 if no luck is left.
static func psr(dice: Dice, u: Unit) -> int:
	return _spend(dice, u) if Spa.has(u, Spa.LUCKY) and u.pilot.lucky > 0 else -1


## A reroll for a missed attack worth spending luck on, or -1.
static func attack(dice: Dice, u: Unit, w: MountedWeapon, need: int) -> int:
	if not Spa.has(u, Spa.LUCKY) or u.pilot.lucky <= 0 or need > WORTH_NEED:
		return -1
	if w.def.max_damage() < WORTH_DAMAGE:
		return -1
	return _spend(dice, u)


static func _spend(dice: Dice, u: Unit) -> int:
	u.pilot.lucky -= 1
	return dice.roll_2d6()
