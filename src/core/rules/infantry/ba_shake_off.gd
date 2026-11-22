class_name BaShakeOff
extends RefCounted
## A swarmed 'Mech throwing battle armor off (Total Warfare, as MegaMek plays it):
## - Any fall knocks the swarmers off: 2D6 to the squad (one trooper), or the
##   whole squad drowns if the 'Mech falls into water.
## - Dropping prone on purpose takes a piloting roll; made, the 'Mech falls
##   (with fall damage) and the swarmers come off as above; missed, it just
##   lies down and they hang on.
## - Landing a jump takes a piloting roll at +4; made, the swarmers come off
##   and every trooper takes 1 damage per jump MP spent (water: they drown).
## TODO(rules): Total Warfare p. 222 via MegaMek; magnetic clamps (+1) aren't in the game.

const JUMP_MOD := 4


## After any fall of 'Mech `u`.
static func on_fall(state: GameState, dice: Dice, emit: Callable, u: Unit) -> void:
	for sq in BaSwarm.swarmers(state, u):
		sq.ba.swarming = -1
		emit.call(GameEvent.TRANSPORT, {"unit_id": sq.id, "carrier_id": u.id, "kind": "thrown_off"})
		if _drowns(state, u):
			Damage.destroy_unit(sq, "it fell into the water")
			Damage.announce(emit, sq)
		else:
			BaDamage.take(dice, emit, sq, dice.roll_2d6(), u.id, "thrown off")


## `u` just went prone by choice.
static func drop_prone(state: GameState, dice: Dice, emit: Callable, u: Unit) -> void:
	if BaSwarm.swarmers(state, u).is_empty() or u.destroyed:
		return
	if Psr.roll(dice, emit, u, "throwing itself down onto the swarming troopers", 0, state):
		Fall.fall(state, dice, emit, u, 0, "it threw itself down to crush the troopers swarming it")


## `u` just landed a jump that cost `mp` jump MP.
static func after_jump(state: GameState, dice: Dice, emit: Callable, u: Unit, mp: int) -> void:
	if BaSwarm.swarmers(state, u).is_empty() or u.destroyed or u.prone:
		return
	if not Psr.roll(dice, emit, u, "shaking off swarming troopers with a jump", JUMP_MOD, state, true):
		return
	for sq in BaSwarm.swarmers(state, u):
		sq.ba.swarming = -1
		emit.call(GameEvent.TRANSPORT, {"unit_id": sq.id, "carrier_id": u.id, "kind": "thrown_off"})
		if _drowns(state, u):
			Damage.destroy_unit(sq, "it fell into the water")
			Damage.announce(emit, sq)
			continue
		for i in sq.ba.troopers.size():
			if sq.ba.is_alive(i) and not sq.destroyed:
				BaDamage.hit_trooper(emit, sq, i, mp, u.id, "thrown off")


static func _drowns(state: GameState, u: Unit) -> bool:
	var tile := state.map.get_tile(u.coord)
	return tile != null and tile.is_water() and tile.depth >= 1 and not u.on_bridge
