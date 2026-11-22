class_name BaLegAttack
extends RefCounted
## Leg attacks: battle armor with claws climbs onto the legs of an enemy
## 'Mech in its own hex and tears at them. It is the squad's whole attack
## for the turn. To hit: its anti-'Mech skill (Piloting) plus the Leg
## Attacks table for troopers left (4-6 +0, 3 +2, 2 +5, 1 +7), the target's
## movement, and -4 if the 'Mech can't move. A hit does 4 damage to one leg
## with a chance of a critical hit (as a through-armor roll).
## TODO(rules): Total Warfare anti-'Mech attacks from general knowledge.

const ID := "ba_leg_attack"
const DAMAGE := 4
const TROOPER_MOD := {1: 7, 2: 5, 3: 2}


static func weapon() -> WeaponDef:
	return WeaponDef.from_dict({"id": ID, "name": "Leg attack", "type": "physical", "damage": DAMAGE,
			"short": 0, "medium": 0, "long": 0})


static func is_leg_attack(w: MountedWeapon) -> bool:
	return w.def.id == ID


static func to_hit(state: GameState, a: Unit, t: Unit) -> ToHit:
	var th := ToHit.new()
	if a.ba == null or not a.def.battle_armor.claw:
		th.impossible = "Only battle armor with claws makes leg attacks"
	elif t.def.is_support():
		th.impossible = "Leg attacks only work against 'Mechs"
	elif t.coord != a.coord:
		th.impossible = "Move into the 'Mech's hex to attack its legs"
	elif t.legs_destroyed() >= Location.legs(t.def).size():
		th.impossible = "It has no legs left to attack"
	if th.impossible != "":
		return th
	th.add("anti-'Mech skill", a.pilot.piloting, "Battle armor uses its anti-'Mech skill to climb a 'Mech's legs.")
	var mod: int = TROOPER_MOD.get(a.ba.alive(), 0)
	if mod > 0:
		th.add("%d troopers left" % a.ba.alive(), mod, "Fewer troopers can't swarm the legs as well (4-6 +0, 3 +2, 2 +5, 1 +7).")
	ToHitCalc.add_movement(th, a, t)
	if ToHitCalc.is_immobile(t):
		th.add("target immobile", -4, "A 'Mech that can't move can't shake them off: -4.")
	return th


## A leg attack is the squad's only attack that turn: keep it, drop the rest.
static func filter(decl: Array[Dictionary], attacker: Unit) -> Array[Dictionary]:
	for d in decl:
		if is_leg_attack(attacker.weapons[d["weapon_index"]]):
			return [d] as Array[Dictionary]
	return decl


static func resolve(state: GameState, dice: Dice, emit: Callable, a: Unit, w: MountedWeapon,
		t: Unit, th: ToHit) -> void:
	w.fired = true
	var roll := dice.roll_2d6()
	var need := th.target()
	emit.call(GameEvent.WEAPON_FIRED, {"attacker_id": a.id, "target_id": t.id, "weapon": w.def.name,
			"weapon_id": ID, "roll": roll, "need": need, "hit": roll >= need, "mods": th.mods, "missiles": 0})
	if roll < need:
		return
	var legs := Location.legs(t.def).filter(func(l: int) -> bool: return not t.is_location_destroyed(l))
	var leg: int = legs[dice.pick(legs.size())]
	var hl := {"loc": leg, "rear": false, "tac": true, "no_cover": true}
	WeaponFire.hit_with(state, dice, emit, t, FiringArc.FRONT, DAMAGE, a.id, "leg attack", hl)
