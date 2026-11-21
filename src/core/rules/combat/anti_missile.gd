class_name AntiMissile
extends RefCounted
## Anti-missile systems (p. 206). When a missile weapon hits a 'Mech whose
## AMS covers the attack direction, the AMS engages: -4 to the attacker's
## Cluster Hits roll (below 2: every missile is shot down), and a Streak
## counts as a roll of 7. Each engagement uses one shot and makes 1 heat.
## One AMS per attack; each AMS engages up to two attacks a turn; none
## while the MechWarrior is unconscious.
## TODO(rules): the defender always engages (the book lets them choose);
## single-missile weapons and laser AMS aren't modelled.

const CLUSTER_MOD := -4
const STREAK_ROLL := 7
const PER_TURN := 2


## The AMS that would engage a missile hit from `attacker`, or null.
static func engaging(target: Unit, attacker: Unit, w: MountedWeapon) -> MountedWeapon:
	if w.def.type != "missile" or w.def.beacon or not target.pilot.conscious or target.shutdown:
		return null
	for a in target.weapons:
		if not a.def.ams or a.engaged >= PER_TURN or not target.can_fire(a):
			continue
		var arc_id := FiringArc.fire_arc(target.coord, FiringArc.weapon_facing(target, a.loc), attacker.coord)
		if FiringArc.weapon_covers(a.loc, a.rear, arc_id):
			return a
	return null


## Engages: spends a shot, adds heat. Returns false if it had no ammo left.
static func engage(target: Unit, a: MountedWeapon) -> bool:
	if not target.use_ammo(a.def):
		return false
	a.engaged += 1
	target.heat_generated += a.def.heat
	return true
