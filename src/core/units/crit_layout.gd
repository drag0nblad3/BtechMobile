class_name CritLayout
extends RefCounted
## Builds the critical-slot table of a design: fixed components first
## (engine, gyro, cockpit, actuators), then equipment in listed order. A
## weapon with "spill" puts its last slots in the next location in.
## TODO(rules): split slots are construction rules, not in the Core Rulebook.

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
		var spill: int = m.get("spill", 0)
		for s in w.slots:
			var loc: int = Location.transfer(m["loc"]) if s >= w.slots - spill else m["loc"]
			_place(out[loc], CritSlot.new(CritSlot.Kind.WEAPON, w.name, i), def)
		if m.get("artemis", false):
			_place(out[m["loc"]], CritSlot.new(CritSlot.Kind.ARTEMIS, "Artemis IV FCS", i), def)
	for i in def.ammo_mounts.size():
		var a: Dictionary = def.ammo_mounts[i]
		var aw: WeaponDef = a["weapon"]
		var kind: String = a.get("kind", "")
		_place(out[a["loc"]], CritSlot.new(CritSlot.Kind.AMMO, aw.name + (" Cluster" if kind == "cluster" else "") + " Ammo" + (" (Half)" if a.get("half", false) else ""), i), def)
	var sink := 0
	for loc: int in def.other_items:
		for item: String in def.other_items[loc]:
			if item == "jump_jet":
				_place(out[loc], CritSlot.new(CritSlot.Kind.JUMP_JET, "Jump Jet"), def)
				continue
			# Each heat sink gets its own ref so the slots of a double share it.
			var n := "Double Heat Sink" if def.double_heat_sinks else "Heat Sink"
			for s in (ClanTech.dhs_slots(def) if def.double_heat_sinks else 1):
				_place(out[loc], CritSlot.new(CritSlot.Kind.HEAT_SINK, n, sink), def)
			sink += 1
	for i in def.melee.size():
		var m: Dictionary = def.melee[i]
		for s in def.melee_slots(m["kind"]):
			_place(out[m["loc"]], CritSlot.new(CritSlot.Kind.MELEE, String(m["kind"]).capitalize(), i), def)
	if def.ecm_loc >= 0:
		for s in Ecm.slots(def):
			_place(out[def.ecm_loc], CritSlot.new(CritSlot.Kind.ECM, "Guardian ECM"), def)
	if def.masc_loc >= 0:
		for s in Masc.size(def):
			_place(out[def.masc_loc], CritSlot.new(CritSlot.Kind.MASC, "MASC"), def)
	if def.supercharger_loc >= 0:
		_place(out[def.supercharger_loc], CritSlot.new(CritSlot.Kind.SUPERCHARGER, "Supercharger"), def)
	if def.c3_master_loc >= 0:
		for s in C3.MASTER_SLOTS:
			_place(out[def.c3_master_loc], CritSlot.new(CritSlot.Kind.C3, "C3 Master"), def)
	if def.c3_slave_loc >= 0:
		_place(out[def.c3_slave_loc], CritSlot.new(CritSlot.Kind.C3, "C3 Slave"), def)
	for g: Dictionary in def.inert:
		for s in InertGear.KINDS[g["kind"]]["slots"]:
			_place(out[g["loc"]], CritSlot.new(CritSlot.Kind.GEAR, InertGear.KINDS[g["kind"]]["name"]), def)
	if def.probe != "":
		for s in ActiveProbe.KINDS[def.probe]["slots"]:
			_place(out[def.probe_loc], CritSlot.new(CritSlot.Kind.PROBE, ActiveProbe.KINDS[def.probe]["name"]), def)
	if def.tc_loc >= 0:
		for s in TargetingComputer.size(def):
			_place(out[def.tc_loc], CritSlot.new(CritSlot.Kind.TARGETING, "Targeting Computer"), def)
	for loc in def.case_locs:
		_place(out[loc], CritSlot.new(CritSlot.Kind.CASE, "CASE"), def)
	for loc in def.case2_locs:
		_place(out[loc], CritSlot.new(CritSlot.Kind.CASE, "CASE II"), def)
	for loc: int in def.bulk_slots:
		for item: String in def.bulk_slots[loc]:
			_place(out[loc], CritSlot.new(CritSlot.Kind.BULK, BULK_NAMES[item]), def)
	return out


const BULK_NAMES := {"endo_steel": "Endo Steel", "ferro_fibrous": "Ferro-Fibrous", "light_ferro": "Light Ferro-Fibrous", "heavy_ferro": "Heavy Ferro-Fibrous", "tsm": "Triple-Strength Myomer"}


static func _fixed(def: UnitDef, loc: int) -> Array[CritSlot]:
	var slots: Array[CritSlot] = []
	var names := []
	if loc == Location.HEAD:
		names = HEAD
	elif loc == Location.CT:
		names = ["Engine", "Engine", "Engine"]
		for s in Gyro.slots(def):
			names.append("Gyro")
		if def.engine_type != "compact":
			names.append_array(["Engine", "Engine", "Engine"])
	elif XlEngine.side_slots(def) > 0 and (loc == Location.LT or loc == Location.RT):
		for s in XlEngine.side_slots(def):
			names.append("Engine")
	elif Location.is_arm_of(def, loc):
		for a in ARM_ACTUATORS:
			names.append(a if def.has_actuator(loc, a) else "")
	elif Location.is_leg_of(def, loc):
		names = LEG_ACTUATORS
	for n: String in names:
		slots.append(_fixed_slot(n))
	while slots.size() < slot_count(def, loc):
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


## Critical slots in a location: a quad's front legs have 6, like any leg.
static func slot_count(def: UnitDef, loc: int) -> int:
	return 6 if Location.is_leg_of(def, loc) else SLOTS[loc]
