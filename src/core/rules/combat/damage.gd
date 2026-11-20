class_name Damage
extends RefCounted
## Applies damage to a 'Mech: armor first, then internal structure, then
## whatever is left transfers inward (arm/leg -> side torso -> center torso).
## Rear hits use rear armor; structure is shared front and back.
## Pips actually marked off count toward the 20-damage piloting roll.


## Returns one step per location touched:
## {loc, rear, armor, structure, destroyed (location), breached (structure hit)}.
static func apply(u: Unit, loc: int, amount: int, rear: bool = false) -> Array[Dictionary]:
	var steps: Array[Dictionary] = []
	while amount > 0 and loc >= 0 and not u.destroyed:
		var step := {"loc": loc, "rear": rear, "armor": 0, "structure": 0,
				"destroyed": false, "breached": false}
		if not u.is_location_destroyed(loc):
			var arm := u.rear_armor if rear and Location.HAS_REAR.has(loc) else u.armor
			var a := mini(arm[loc], amount)
			arm[loc] -= a
			amount -= a
			step["armor"] = a
			var s := mini(u.structure[loc], amount)
			u.structure[loc] -= s
			amount -= s
			step["structure"] = s
			step["breached"] = s > 0
			u.damage_this_phase += a + s
			if u.structure[loc] <= 0:
				step["destroyed"] = true
				destroy_location(u, loc)
		steps.append(step)
		loc = Location.transfer(loc)
		rear = false
	return steps


## Internal damage (explosions): straight to internal structure, and any
## excess goes to the next location's structure, skipping armor.
static func apply_internal(u: Unit, loc: int, amount: int) -> Array[Dictionary]:
	var steps: Array[Dictionary] = []
	while amount > 0 and loc >= 0 and not u.destroyed:
		var step := apply_internal_one(u, loc, amount)
		amount -= int(step["structure"])
		steps.append(step)
		loc = Location.transfer(loc)
	return steps


## Internal damage to one location only; returns its step.
static func apply_internal_one(u: Unit, loc: int, amount: int) -> Dictionary:
	var step := {"loc": loc, "rear": false, "armor": 0, "structure": 0,
			"destroyed": false, "breached": false}
	if not u.is_location_destroyed(loc):
		var s := mini(u.structure[loc], amount)
		u.structure[loc] -= s
		u.damage_this_phase += s
		step["structure"] = s
		step["breached"] = s > 0
		if u.structure[loc] <= 0:
			step["destroyed"] = true
			destroy_location(u, loc)
	return step


## Marks a location (and anything that goes with it) destroyed.
static func destroy_location(u: Unit, loc: int) -> void:
	u.structure[loc] = 0
	u.armor[loc] = 0
	u.rear_armor[loc] = 0
	for w in u.weapons:
		if w.loc == loc:
			w.destroyed = true
	for a in u.ammo:
		if a.loc == loc:
			a.destroyed = true
	if loc == Location.HEAD:
		destroy_unit(u, "head destroyed")
	elif loc == Location.CT:
		destroy_unit(u, "center torso destroyed")
	else:
		var arm := Location.arm_of_torso(loc)
		if arm >= 0 and not u.is_location_destroyed(arm):
			destroy_location(u, arm)
		if arm >= 0:
			XlEngine.on_torso_lost(u, loc)


static func destroy_unit(u: Unit, reason: String) -> void:
	if u.destroyed:
		return
	u.destroyed = true
	u.destroyed_reason = reason


## Emits UNIT_DESTROYED once, the first time a destroyed unit is reported.
static func announce(emit: Callable, u: Unit) -> void:
	if u.destroyed and not u.destroyed_announced:
		u.destroyed_announced = true
		emit.call(GameEvent.UNIT_DESTROYED, {"unit_id": u.id, "reason": u.destroyed_reason})


## Splits damage into clusters (e.g. LRMs in groups of 5).
static func clusters(total: int, size: int) -> Array[int]:
	var out: Array[int] = []
	while total > 0:
		out.append(mini(size, total))
		total -= size
	return out
