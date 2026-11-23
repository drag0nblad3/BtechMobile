class_name BaSwarm
extends RefCounted
## Swarm attacks: battle armor with claws climbs all over an enemy 'Mech in
## its own hex. To attach: anti-'Mech skill (Piloting) + the Swarm Attacks
## table (4-6 troopers +2, 1-3 +5) + the target's movement, -2 if it is
## prone, -4 if it can't move, and more for friendly battle armor riding it
## (Swarm Attack Modifiers table). One squad per 'Mech. Once on, the squad
## moves with it and can't walk; every later Weapon Attack Phase its weapons
## hit that 'Mech automatically, each hit on the Swarm Attacks Hit Location
## table. It comes off when the 'Mech is destroyed or brushes it off
## (BaBrushOff), throws it off (BaShakeOff), or the squad lets go as its
## attack. TODO(rules): Total Warfare from general knowledge.

const ID := "ba_swarm"
const LET_GO := "ba_let_go"
## 2D6 2-12 → [location, rear], from the sheets' Swarm Attacks Hit Location table.
const BIPED := [[Location.HEAD, false], [Location.CT, true], [Location.RT, true], [Location.RT, false],
		[Location.RA, false], [Location.CT, false], [Location.LA, false], [Location.LT, false],
		[Location.LT, true], [Location.CT, true], [Location.HEAD, false]]
const QUAD := [[Location.HEAD, false], [Location.RT, false], [Location.CT, true], [Location.RT, true],
		[Location.RT, false], [Location.CT, false], [Location.LT, false], [Location.LT, true],
		[Location.CT, true], [Location.LT, false], [Location.HEAD, false]]


static func weapon() -> WeaponDef:
	return WeaponDef.from_dict({"id": ID, "name": "Swarm attack", "type": "physical", "damage": 0,
			"short": 0, "medium": 0, "long": 0})


static func is_swarm(w: MountedWeapon) -> bool:
	return w.def.id == ID


## Letting go of the 'Mech it swarms: its only attack that turn.
static func let_go_weapon() -> WeaponDef:
	return WeaponDef.from_dict({"id": LET_GO, "name": "Let go", "type": "physical", "damage": 0,
			"short": 0, "medium": 0, "long": 0})


static func is_let_go(w: MountedWeapon) -> bool:
	return w.def.id == LET_GO


## Id of the 'Mech squad `u` is swarming, -1 if none.
static func on(u: Unit) -> int:
	return u.ba.swarming if u != null and u.ba != null else -1


static func swarmers(state: GameState, t: Unit) -> Array[Unit]:
	var out: Array[Unit] = []
	for u in state.units:
		if not u.destroyed and on(u) == t.id:
			out.append(u)
	return out


static func to_hit(state: GameState, a: Unit, t: Unit) -> ToHit:
	var th := ToHit.new()
	if a.ba == null or not a.def.battle_armor.anti_mech:
		th.impossible = "Only light and medium battle armor swarms 'Mechs"
	elif on(a) >= 0:
		th.impossible = "It is already swarming a 'Mech"
	elif t.def.is_support():
		th.impossible = "Swarm attacks only work against 'Mechs"
	elif t.coord != a.coord:
		th.impossible = "Move into the 'Mech's hex to swarm it"
	elif not swarmers(state, t).is_empty():
		th.impossible = "Another squad is already swarming it"
	if th.impossible != "":
		return th
	th.add("anti-'Mech skill", a.pilot.piloting, "Battle armor uses its anti-'Mech skill to climb onto a 'Mech.")
	th.add("%d troopers" % a.ba.alive(), 2 if a.ba.alive() >= 4 else 5, "Swarm Attacks table: 4-6 troopers +2, 1-3 +5.")
	var guards := 0
	for r in AssetTransport.riders(state, t):
		guards += r.ba.alive() if r.ba != null else 0
	if guards > 0:
		th.add("%d riders" % guards, maxi(0, guards - a.ba.alive() + 2), "Friendly battle armor riding the 'Mech fights them off.")
	add_magnets(th, a)
	ToHitCalc.add_movement(th, a, t)
	if t.prone:
		th.add("target prone", -2, "A 'Mech on the ground is easier to climb: -2.")
	if ToHitCalc.is_immobile(t):
		th.add("target immobile", -4, "A 'Mech that can't move can't shake them off: -4.")
	return th


## While swarming, the squad's weapons can only hit its 'Mech, and always
## do. Null when `a` isn't swarming.
static func fire_check(state: GameState, a: Unit, w: MountedWeapon, t: Unit) -> ToHit:
	var th := ToHit.new()
	if on(a) < 0:
		if not is_let_go(w):
			return null
		th.impossible = "It isn't swarming anything"
	elif t.id != on(a):
		th.impossible = "Swarming troopers can only attack the 'Mech they are on"
	elif is_let_go(w):
		var tile := state.map.get_tile(a.coord)
		if tile != null and not BaMoveCost.may_enter(tile):
			th.impossible = "Letting go here would drop them into the water"  # TODO(rules)
		else:
			th.auto_hit = "they let go and drop off"
	elif is_swarm(w) or BaLegAttack.is_leg_attack(w):
		th.impossible = "It is already swarming a 'Mech"
	elif not a.can_fire(w):
		th.impossible = "%s can't fire (no ammo)" % w.def.name
	else:
		th.auto_hit = "swarming troopers fire point-blank"
	return th


static func add_magnets(th: ToHit, a: Unit) -> void:
	if a.def.battle_armor.magnets:
		th.add("magnetic claws", -1, "Magnets in the claws help them hold on: -1.")


## +1 for a 'Mech trying to get magnet-clawed troopers off.
static func grip_mod(state: GameState, t: Unit) -> int:
	for sq in swarmers(state, t):
		if sq.def.battle_armor.magnets:
			return 1
	return 0


static func location(dice: Dice, t: Unit) -> Dictionary:
	var r := dice.roll_2d6()
	var spot: Array = (QUAD if t.def.quad else BIPED)[r - 2]
	return {"loc": spot[0], "rear": spot[1], "tac": false, "no_cover": true, "roll": r}


## A swarm attempt is the squad's whole attack, like a leg attack.
static func filter(decl: Array[Dictionary], attacker: Unit) -> Array[Dictionary]:
	for d in decl:
		var w := attacker.weapons[d["weapon_index"]]
		if is_swarm(w) or is_let_go(w):
			return [d] as Array[Dictionary]
	return decl


static func resolve(state: GameState, dice: Dice, emit: Callable, a: Unit, w: MountedWeapon,
		t: Unit, th: ToHit) -> void:
	w.fired = true
	var roll := dice.roll_2d6()
	var need := th.target()
	emit.call(GameEvent.WEAPON_FIRED, {"attacker_id": a.id, "target_id": t.id, "weapon": w.def.name,
			"weapon_id": ID, "roll": roll, "need": need, "hit": roll >= need, "mods": th.mods, "missiles": 0})
	if roll >= need and swarmers(state, t).is_empty():
		a.ba.swarming = t.id
		emit.call(GameEvent.TRANSPORT, {"unit_id": a.id, "carrier_id": t.id, "kind": "swarm"})


static func let_go(emit: Callable, a: Unit, w: MountedWeapon, t: Unit) -> void:
	w.fired = true
	a.ba.swarming = -1
	emit.call(GameEvent.TRANSPORT, {"unit_id": a.id, "carrier_id": t.id, "kind": "let_go"})


## Swarmers go where their 'Mech goes; they drop off when it is destroyed.
static func update(state: GameState, emit: Callable) -> void:
	for u in state.units:
		if on(u) < 0:
			continue
		var t := state.unit_by_id(on(u))
		if u.destroyed or t == null or t.destroyed:
			u.ba.swarming = -1
			if not u.destroyed and t != null:
				emit.call(GameEvent.TRANSPORT, {"unit_id": u.id, "carrier_id": t.id, "kind": "swarm_off"})
		else:
			u.coord = t.coord
