class_name Unit
extends RefCounted
## A unit on the battlefield: its design plus everything that changes in play.
## This is the live record sheet. Rules in src/core/rules/ change it; only the
## GameController calls those rules.

var id: int
var def: UnitDef
var side: int
var coord: Vector2i
var facing: int
var pilot: Pilot

# Record sheet ------------------------------------------------------------
var armor: Array[int] = []
var rear_armor: Array[int] = []
var structure: Array[int] = []
var weapons: Array[MountedWeapon] = []
var ammo: Array[AmmoBin] = []
var slots: Array = []  ## Per Location: Array[CritSlot].
var heat: int = 0
var engine_hits: int = 0
var gyro_hits: int = 0
var sensor_hits: int = 0
var heat_sinks_lost: int = 0

# Condition ---------------------------------------------------------------
var destroyed: bool = false
var destroyed_reason: String = ""
var prone: bool = false
var shutdown: bool = false

# This turn ---------------------------------------------------------------
var has_moved: bool = false
var has_fired: bool = false
var has_physical: bool = false
var move_mode: int = -1  ## MoveMode.Kind used this turn, -1 if not moved.
var hexes_moved: int = 0
var heat_generated: int = 0   ## Heat built up this turn, applied in the Heat Phase.
var damage_this_phase: int = 0


func _init(unit_id: int, unit_def: UnitDef, unit_side: int, at: Vector2i, face: int,
		mech_pilot: Pilot = null) -> void:
	id = unit_id
	def = unit_def
	side = unit_side
	coord = at
	facing = face
	pilot = mech_pilot if mech_pilot else Pilot.new()
	for loc in Location.COUNT:
		armor.append(def.armor[loc] if def.armor.size() > loc else 0)
		rear_armor.append(def.rear_armor[loc] if def.rear_armor.size() > loc else 0)
		structure.append(StructureTable.points(def.tonnage, loc))
	for m in def.weapon_mounts:
		weapons.append(MountedWeapon.new(m["weapon"], m["loc"], m["rear"]))
	for a in def.ammo_mounts:
		ammo.append(AmmoBin.new(a["weapon"], a["loc"]))
	slots = CritLayout.build(def)


func reset_for_turn() -> void:
	has_moved = false
	has_fired = false
	has_physical = false
	move_mode = -1
	hexes_moved = 0
	heat_generated = 0
	for w in weapons:
		w.fired = false


## Still on the field and able to take its turn in a phase.
func can_act() -> bool:
	return not destroyed and not shutdown and pilot.conscious


func is_location_destroyed(loc: int) -> bool:
	return structure[loc] <= 0


## Undamaged actuator of that name in a location (e.g. "hand" in LA).
func has_working_actuator(loc: int, actuator: String) -> bool:
	if is_location_destroyed(loc):
		return false
	for s: CritSlot in slots[loc]:
		if s.kind == CritSlot.Kind.ACTUATOR and s.name == actuator:
			return not s.hit
	return false


func leg_actuator_hits() -> int:
	var n := 0
	for loc in [Location.LL, Location.RL]:
		for s: CritSlot in slots[loc]:
			if s.kind == CritSlot.Kind.ACTUATOR and s.hit:
				n += 1
	return n


func legs_destroyed() -> int:
	return int(is_location_destroyed(Location.LL)) + int(is_location_destroyed(Location.RL))


func hip_hits() -> int:
	var n := 0
	for loc in [Location.LL, Location.RL]:
		if not has_working_actuator(loc, "hip") and not is_location_destroyed(loc):
			n += 1
	return n


func working_heat_sinks() -> int:
	return maxi(0, def.heat_sinks - heat_sinks_lost)


## Walking MP after heat and leg damage.
## TODO(rules): hip halving and leg loss are simplified (see rules-coverage).
func walk_mp() -> int:
	var mp := def.walk_mp - HeatScale.mp_penalty(heat)
	if hip_hits() > 0:
		mp = ceili(mp / 2.0)
	mp -= leg_actuator_hits() - hip_hits()
	if legs_destroyed() > 0:
		mp = 1 if legs_destroyed() == 1 else 0
	return maxi(0, mp)


func run_mp() -> int:
	if legs_destroyed() > 0:
		return walk_mp()
	return ceili(walk_mp() * 1.5)


func ammo_for(w: WeaponDef) -> int:
	var n := 0
	for a in ammo:
		if a.weapon == w and not a.destroyed:
			n += a.shots
	return n


## Uses one shot, from the first bin that still has some. False if empty.
func use_ammo(w: WeaponDef) -> bool:
	for a in ammo:
		if a.weapon == w and not a.destroyed and a.shots > 0:
			a.shots -= 1
			return true
	return false


func can_fire(w: MountedWeapon) -> bool:
	if w.destroyed or is_location_destroyed(w.loc):
		return false
	return not w.def.uses_ammo() or ammo_for(w.def) > 0


func label() -> String:
	return def.display_name()
