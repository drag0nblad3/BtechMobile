class_name CritLayout
extends RefCounted
## Builds the critical-slot table of a design: fixed components first
## (engine, gyro, cockpit, actuators), then equipment in listed order.

const SLOTS := [6, 12, 12, 12, 12, 12, 6, 6]
const HEAD := ["Life Support", "Sensors", "Cockpit", "", "Sensors", "Life Support"]
const ARM_ACTUATORS := ["shoulder", "upper_arm", "lower_arm", "hand"]
const LEG_ACTUATORS := ["hip", "upper_leg", "lower_leg", "foot"]


## Returns Array (per Location) of Array[CritSlot].
static func build(def: UnitDef) -> Array:
	var out := []
	for loc in Location.COUNT:
		out.append(_fixed(def, loc))
	for i in def.weapon_mounts.size():
		var m: Dictionary = def.weapon_mounts[i]
		var w: WeaponDef = m["weapon"]
		for s in w.slots:
			_place(out[m["loc"]], CritSlot.new(CritSlot.Kind.WEAPON, w.name, i), def)
		if m.get("artemis", false):
			_place(out[m["loc"]], CritSlot.new(CritSlot.Kind.ARTEMIS, "Artemis IV FCS", i), def)
	for i in def.ammo_mounts.size():
		var a: Dictionary = def.ammo_mounts[i]
		var aw: WeaponDef = a["weapon"]
		var kind: String = a.get("kind", "")
		_place(out[a["loc"]], CritSlot.new(CritSlot.Kind.AMMO, aw.name + (" Cluster" if kind == "cluster" else "") + " Ammo", i), def)
	var sink := 0
	for loc: int in def.other_items:
		for item: String in def.other_items[loc]:
			if item == "jump_jet":
				_place(out[loc], CritSlot.new(CritSlot.Kind.JUMP_JET, "Jump Jet"), def)
				continue
			# Each heat sink gets its own ref so the 3 slots of a double share it.
			var n := "Double Heat Sink" if def.double_heat_sinks else "Heat Sink"
			for s in (3 if def.double_heat_sinks else 1):
				_place(out[loc], CritSlot.new(CritSlot.Kind.HEAT_SINK, n, sink), def)
			sink += 1
	for loc in def.case_locs:
		_place(out[loc], CritSlot.new(CritSlot.Kind.CASE, "CASE"), def)
	return out


static func _fixed(def: UnitDef, loc: int) -> Array[CritSlot]:
	var slots: Array[CritSlot] = []
	var names := []
	if loc == Location.HEAD:
		names = HEAD
	elif loc == Location.CT:
		names = ["Engine", "Engine", "Engine", "Gyro", "Gyro", "Gyro", "Gyro",
				"Engine", "Engine", "Engine"]
	elif Location.is_arm(loc):
		for a in ARM_ACTUATORS:
			names.append(a if def.has_actuator(loc, a) else "")
	elif Location.is_leg(loc):
		names = LEG_ACTUATORS
	for n: String in names:
		slots.append(_fixed_slot(n))
	while slots.size() < SLOTS[loc]:
		slots.append(CritSlot.new(CritSlot.Kind.EMPTY, ""))
	return slots


static func _fixed_slot(n: String) -> CritSlot:
	match n:
		"":
			return CritSlot.new(CritSlot.Kind.EMPTY, "")
		"Engine":
			return CritSlot.new(CritSlot.Kind.ENGINE, n)
		"Gyro":
			return CritSlot.new(CritSlot.Kind.GYRO, n)
		"Cockpit":
			return CritSlot.new(CritSlot.Kind.COCKPIT, n)
		"Sensors":
			return CritSlot.new(CritSlot.Kind.SENSORS, n)
		"Life Support":
			return CritSlot.new(CritSlot.Kind.LIFE_SUPPORT, n)
	return CritSlot.new(CritSlot.Kind.ACTUATOR, n)


static func _place(slots: Array, s: CritSlot, def: UnitDef) -> void:
	for i in slots.size():
		if slots[i].kind == CritSlot.Kind.EMPTY:
			slots[i] = s
			return
	push_error("%s: no free critical slot for %s" % [def.id, s.name])
