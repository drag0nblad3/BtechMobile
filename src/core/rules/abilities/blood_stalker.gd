class_name BloodStalker
extends RefCounted
## Blood Stalker SPA (Campaign Operations p. 73): one enemy per battle is
## the quarry. Ranged attacks on it are -1 to hit, on anything else +2,
## until the quarry is destroyed or leaves the field; then the ability ends.
## TODO(rules): the player names the quarry; the app takes the first
## primary target the MechWarrior shoots at (our pick).

const USED := -2


## Adds the modifier for an attack by `u` on `target` (`primary`: not a
## secondary target, so it would become the quarry if none is set).
static func add(th: ToHit, state: GameState, u: Unit, target: Unit, primary: bool) -> void:
	if not Spa.has(u, Spa.BLOOD_STALKER):
		return
	var q := quarry(state, u)
	if q == USED:
		return
	if q == target.id or (q < 0 and primary):
		th.add("Blood Stalker", -1, "%s is this MechWarrior's quarry: -1 to hit it." % target.def.name)
	else:
		th.add("Blood Stalker", 2, "Blood Stalker: +2 against anything but the quarry.")


## The quarry's unit id, -1 if none is picked yet, USED once it's gone.
static func quarry(state: GameState, u: Unit) -> int:
	var q := u.pilot.quarry
	if q >= 0:
		var t := state.unit_by_id(q)
		if t == null or t.destroyed or state.mission.exited.has(q):
			u.pilot.quarry = USED
			return USED
	return q


## After `u` fires at its primary target: that becomes the quarry if none is set.
static func mark(state: GameState, u: Unit, target: Unit) -> void:
	if Spa.has(u, Spa.BLOOD_STALKER) and quarry(state, u) == -1:
		u.pilot.quarry = target.id
