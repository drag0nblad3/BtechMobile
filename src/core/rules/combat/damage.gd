class_name Damage
extends RefCounted
## Applies damage to a 'Mech: armor first, then internal structure, then
## whatever is left transfers inward (arm/leg -> side torso -> center torso).
## Rear hits use rear armor; structure is shared front and back.
## Pips actually marked off count toward the 20-damage piloting roll.
## `attack` tags the source ("DB", "M", "DE", "P", "AE", "heat", "physical",
## "fall", "collapse") for special armor and structure (ArmorTypes, StructureTypes).


## Returns one step per location touched:
## {loc, rear, armor, structure, destroyed (location), breached (structure hit)}.
static func apply(u: Unit, loc: int, amount: int, rear: bool = false, attack: Array = []) -> Array[Dictionary]:
	var steps: Array[Dictionary] = []
	while amount > 0 and loc >= 0 and not u.destroyed:
		var step := {"loc": loc, "rear": rear, "armor": 0, "structure": 0,
				"destroyed": false, "breached": false}
		if not u.is_location_destroyed(loc):
			var back := rear and Location.HAS_REAR.has(loc)
			var arm := u.rear_armor if back else u.armor
			var part := u.rear_partial if back else u.armor_partial
			if arm[loc] > 0 and ArmorTypes.is_special(u.def):
				amount = ArmorTypes.reduce(u.def, amount, attack)
				step["tac_mod"] = ArmorTypes.tac_mod(u.def) if amount > 0 else null  # a hit cut to 0 can't TAC
			var ab := ArmorTypes.absorb(u.def, arm[loc], part[loc], amount, attack) if arm[loc] > 0 \
					else {"used": 0, "pips": 0, "partial": part[loc]}
			arm[loc] -= int(ab["pips"])
			part[loc] = int(ab["partial"])
			amount -= int(ab["used"])
			step["armor"] = ab["pips"]
			var sb := StructureTypes.absorb(u.def, u.structure[loc], u.structure_partial[loc], amount)
			u.structure[loc] -= int(sb["pips"])
			u.structure_partial[loc] = int(sb["partial"])
			amount -= int(sb["used"])
			step["structure"] = sb["pips"]
			step["breached"] = int(sb["pips"]) > 0
			u.damage_this_phase += int(ab["pips"]) + int(sb["pips"])
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
		amount -= int(step.get("used", step["structure"]))
		steps.append(step)
		loc = Location.transfer(loc)
	return steps


## Internal damage to one location only; returns its step.
static func apply_internal_one(u: Unit, loc: int, amount: int) -> Dictionary:
	var step := {"loc": loc, "rear": false, "armor": 0, "structure": 0,
			"destroyed": false, "breached": false}
	if not u.is_location_destroyed(loc):
		var sb := StructureTypes.absorb(u.def, u.structure[loc], u.structure_partial[loc], amount)
		var s := int(sb["pips"])
		u.structure[loc] -= s
		u.structure_partial[loc] = int(sb["partial"])
		u.damage_this_phase += s
		step["structure"] = s
		step["used"] = sb["used"]
		step["breached"] = s > 0
		if u.structure[loc] <= 0:
			step["destroyed"] = true
			destroy_location(u, loc)
	return step


## Marks a location (and anything that goes with it) destroyed.
static func destroy_location(u: Unit, loc: int) -> void:
	if Location.is_leg_of(u.def, loc) and not u.prone:
		u.psr_pending.append({"reason": "leg destroyed", "auto_fall": true, "mod": 0})  # p. 90, p. 238
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
