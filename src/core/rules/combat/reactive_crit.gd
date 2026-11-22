class_name ReactiveCrit
extends RefCounted
## Reactive armor slots under a critical hit (book p. 202). Like other armor
## slots they can't be damaged, so the hit is rolled again, but first a 2D6
## roll: on a 2 the location's armor (front and rear) blows off and its
## internal structure takes 1 extra point. A location holding nothing but
## reactive slots makes that roll once; anything but a 2 moves the hit inward.
## TODO(rules): picking a reactive slot is weighted by the slot count, the
## same as rerolling a slot we otherwise skip.

const NAME := "Reactive"


static func slots(u: Unit, loc: int) -> int:
	if u.def.armor_type != "reactive":
		return 0
	return u.slots[loc].filter(func(s: CritSlot) -> bool: return s.kind == CritSlot.Kind.BULK and s.name == NAME).size()


## Does this critical hit land on a reactive slot? `hittable` = other slots.
static func lands(dice: Dice, u: Unit, loc: int, hittable: int) -> bool:
	var r := slots(u, loc)
	if r == 0:
		return false
	return hittable == 0 or dice.pick(hittable + r) >= hittable


## The second roll; true if the armor blew off.
static func roll(state: GameState, dice: Dice, emit: Callable, u: Unit, loc: int) -> bool:
	var r := dice.roll_2d6()
	var blew := r == 2
	emit.call(GameEvent.CRITICAL, {"unit_id": u.id, "loc": loc, "slot": NAME, "reactive_roll": r,
			"effect": "reactive armor detonates: all armor here is gone (+1 internal damage)" if blew
			else "reactive armor holds (roll %d, only a 2 sets it off)" % r})
	if not blew:
		return false
	u.armor[loc] = 0
	u.armor_partial[loc] = 0
	if Location.is_torso(loc):
		u.rear_armor[loc] = 0
		u.rear_partial[loc] = 0
	var steps: Array[Dictionary] = [Damage.apply_internal_one(u, loc, 1)]
	emit.call(GameEvent.DAMAGE, {"unit_id": u.id, "source_id": -1, "source": "reactive armor",
			"amount": 1, "loc": loc, "steps": steps, "covered": false})
	Damage.announce(emit, u)
	CriticalHits.after_damage(state, dice, emit, u, steps, false)
	return true
