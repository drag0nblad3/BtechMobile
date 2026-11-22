class_name DestroyCheck
extends RefCounted
## End Phase Destroy Checks for Assets (book pp. 146-147). An Asset that
## took at least its Threshold in damage this turn is checked once: 2D6,
## +1 for 11+ damage and +1 more per further 10 full points, against its
## Check number. Surviving lowers the Check by 1 (Degradation; 2 for
## conventional infantry hit by AI weapons or fire). At 2 or less the next
## check is failed whatever the roll.


## Roll bonus for a turn's damage: 1-10 +0, 11-20 +1, 21-30 +2 ...
static func damage_bonus(damage: int) -> int:
	return 0 if damage <= 10 else (damage - 1) / 10


## The Check number this turn, with an infantry building bonus (p. 145).
static func target(state: GameState, u: Unit) -> int:
	var b := InfantryCover.check_bonus(state, u)
	return mini(11, u.asset.check + b) if b > 0 else u.asset.check


static func run(state: GameState, dice: Dice, emit: Callable) -> void:
	for u in state.units:
		if u.asset == null or u.destroyed:
			continue
		var a := u.asset
		if a.damage > 0 and a.damage >= a.card.threshold:
			resolve(state, dice, emit, u)
		a.new_turn()


static func resolve(state: GameState, dice: Dice, emit: Callable, u: Unit) -> void:
	var a := u.asset
	var roll := dice.roll_2d6()
	var bonus := damage_bonus(a.damage)
	var need := target(state, u)
	var killed := a.auto_fail or roll + bonus >= need
	var data := {"unit_id": u.id, "damage": a.damage, "roll": roll, "bonus": bonus,
			"need": need, "destroyed": killed, "auto": a.auto_fail, "by": a.last_attacker}
	if killed:
		Damage.destroy_unit(u, "failed its Destroy Check")
	else:
		var loss := 2 if a.ai_hit else 1
		a.check -= loss
		a.auto_fail = a.check <= 2
		data["degraded"] = loss
		data["check"] = a.check
	emit.call(GameEvent.DESTROY_CHECK, data)
	Damage.announce(emit, u)
