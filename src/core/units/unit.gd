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
var sinks_off: int = 0  ## Heat sinks switched off by choice (HeatSinkSwitch).
var sinks_off_request: int = -1  ## Sinks to have off after the End Phase, -1 none.
## Physical weapons destroyed by critical hits: index into def.melee -> true.
var melee_lost: Dictionary = {}
## Club carried: "" none, "tree" or "girder" (MeleeWeapons).
var club: String = ""

# Condition ---------------------------------------------------------------
var destroyed: bool = false
var destroyed_reason: String = ""
var destroyed_announced: bool = false
var prone: bool = false
var flooded: Dictionary = {}  ## Location -> true once a hull breach floods it (HullBreach).
var ecm_lost: bool = false  ## ECM suite destroyed by a critical hit.
var probe_lost := false  ## Active probe destroyed by a critical hit.
var tc_lost: bool = false  ## Targeting computer destroyed by a critical hit.
var narc_pods: Array[Dictionary] = []  ## Narc homing pods on it: [{side, loc, turn}] (Narc).
var on_roof: bool = false  ## Standing on the roof of its hex's building (Roofs).
var on_bridge: bool = false  ## On the deck of its hex's bridge, not underneath (Bridges).
var shutdown: bool = false
var voluntary_shutdown: bool = false  ## Shut down by choice: stays down until restarted (VoluntaryShutdown).
var power_request: String = ""  ## "off" / "on" at the next Heat Phase (VoluntaryShutdown).
var masc_level: int = 0  ## Turns of MASC use in a row, less one per rest turn (Masc).
var sc_level: int = 0  ## The same for the supercharger (Supercharger).
var sc_lost: bool = false  ## Supercharger wrecked by a failed roll.

# This turn ---------------------------------------------------------------
var has_moved: bool = false
var has_fired: bool = false
var has_physical: bool = false
var move_mode: int = -1  ## MoveMode.Kind used this turn, -1 if not moved.
var hexes_moved: int = 0
var masc_used: bool = false    ## MASC engaged this turn (worked or not).
var masc_active: bool = false  ## MASC worked: running MP is twice walking MP.
var masc_failed: bool = false  ## MASC failed: leg criticals owed after the move.
var sc_used: bool = false  ## Supercharger engaged this turn; sc_active it worked,
var sc_active: bool = false  ## sc_failed engine criticals are owed after the move.
var sc_failed: bool = false
var torso_twist: int = 0  ## -1 left, 0, +1 right (one hexside), weapon phase only.
var arms_flipped := false  ## Arms reversed this turn (ArmFlip).
var heat_generated: int = 0   ## Heat built up this turn, applied in the Heat Phase.
var outside_heat: int = 0     ## Heat from flamers etc. this turn (capped in the Heat Phase).
var damage_this_phase: int = 0
## Piloting rolls owed at the end of this phase: [{reason, mod, auto_fall?}].
var psr_pending: Array[Dictionary] = []


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
		structure.append(StructureTable.points(def.tonnage, loc, def.quad))
	for m in def.weapon_mounts:
		var mw := MountedWeapon.new(m["weapon"], m["loc"], m["rear"])
		mw.artemis = m.get("artemis", false)
		weapons.append(mw)
	for a in def.ammo_mounts:
		var bin := AmmoBin.new(a["weapon"], a["loc"], a.get("kind", ""))
		if a.get("half", false):
			bin.shots = maxi(1, bin.shots / 2)
		ammo.append(bin)
	Narc.setup_ammo(self)
	Atm.setup_ammo(self)
	slots = CritLayout.build(def)


func reset_for_turn() -> void:
	has_moved = false
	has_fired = false
	has_physical = false
	move_mode = -1
	hexes_moved = 0
	torso_twist = 0
	arms_flipped = false
	heat_generated = 0
	outside_heat = 0
	Masc.new_turn(self)
	Supercharger.new_turn(self)
	for w in weapons:
		w.fired = false
		w.engaged = 0


## Still on the field and able to take its turn in a phase.
func can_act() -> bool:
	return not destroyed and not shutdown and pilot.conscious


func is_location_destroyed(loc: int) -> bool:
	return structure[loc] <= 0


## Destroyed or flooded: nothing in it works.
func is_location_out(loc: int) -> bool:
	return structure[loc] <= 0 or flooded.get(loc, false)


## Undamaged actuator of that name in a location (e.g. "hand" in LA).
func has_working_actuator(loc: int, actuator: String) -> bool:
	if is_location_out(loc):
		return false
	for s: CritSlot in slots[loc]:
		if s.kind == CritSlot.Kind.ACTUATOR and s.name == actuator:
			return not s.hit
	return false


func leg_actuator_hits() -> int:
	var n := 0
	for loc in Location.legs(def):
		for s: CritSlot in slots[loc]:
			if s.kind == CritSlot.Kind.ACTUATOR and s.hit:
				n += 1
	return n


func legs_destroyed() -> int:
	return Location.legs(def).filter(func(l: int) -> bool: return is_location_out(l)).size()


## Hip hits with a biped's effects (a quad's first one doesn't count, Quad).
func hip_hits() -> int:
	if def.quad:
		return Quad.counted_hips(self)
	var n := 0
	for loc in [Location.LL, Location.RL]:
		if not has_working_actuator(loc, "hip") and not is_location_out(loc):
			n += 1
	return n


func has_hit_slot(kind: int) -> bool:
	for loc in Location.COUNT:
		for s: CritSlot in slots[loc]:
			if s.kind == kind and s.hit:
				return true
	return false


func working_heat_sinks() -> int:
	return maxi(0, def.heat_sinks - heat_sinks_lost - sinks_off)


## Heat removed each Heat Phase by the working heat sinks.
func dissipation() -> int:
	return working_heat_sinks() * def.heat_per_sink()


## A critical hit on a heat sink slot. Returns false when that sink (one of a
## double's other slots) was already destroyed.
func lose_heat_sink(slot: CritSlot) -> bool:
	for loc in Location.COUNT:
		for s: CritSlot in slots[loc]:
			if s != slot and s.hit and s.kind == CritSlot.Kind.HEAT_SINK and s.ref == slot.ref:
				return false
	heat_sinks_lost += 1
	return true


## Walking MP after leg damage, then heat (book pp. 90, 99): each hip, upper
## leg, lower leg or foot hit is -1, but leg damage can't go below 1; a
## destroyed leg sets the base to 1; both legs gone is 0.
func walk_mp() -> int:
	if def.quad:
		var qb := Quad.walk_base(self)
		return maxi(0, qb + (Tsm.mp_bonus(self) if qb > 0 else 0) - HeatScale.mp_penalty(heat))
	if legs_destroyed() >= 2:
		return 0
	var base := mini(def.walk_mp, 1) if legs_destroyed() == 1 \
			else maxi(mini(def.walk_mp, 1), def.walk_mp - leg_actuator_hits())
	if base > 0:
		base += Tsm.mp_bonus(self)
	return maxi(0, base - HeatScale.mp_penalty(heat))


func run_mp() -> int:
	if masc_active and sc_active:
		return ceili(walk_mp() * 2.5)
	return walk_mp() * 2 if masc_active or sc_active else ceili(walk_mp() * 1.5)


## Jump MP after jump jet damage.
func jump_mp() -> int:
	var lost := 0
	for loc in Location.COUNT:
		for s: CritSlot in slots[loc]:
			if s.kind == CritSlot.Kind.JUMP_JET and (s.hit or is_location_out(loc)):
				lost += 1
	return maxi(0, def.jump_mp - lost)


## Working jump jets in the legs (they don't fire under water).
func leg_jump_jets() -> int:
	var n := 0
	for loc in Location.legs(def):
		if is_location_destroyed(loc):
			continue
		for s: CritSlot in slots[loc]:
			if s.kind == CritSlot.Kind.JUMP_JET and not s.hit:
				n += 1
	return n


## Direction the torso (and arms) face: legs' facing plus any torso twist.
func torso_facing() -> int:
	return Hex.rotate(facing, torso_twist)


func ammo_for(w: WeaponDef, kind: String = "") -> int:
	var n := 0
	for a in ammo:
		if a.weapon == w and a.kind == kind and not a.destroyed:
			n += a.shots
	return n


## Uses one shot, from the first bin that still has some. False if empty.
func use_ammo(w: WeaponDef, kind: String = "") -> bool:
	for a in ammo:
		if a.weapon == w and a.kind == kind and not a.destroyed and a.shots > 0:
			a.shots -= 1
			return true
	return false


## Puts back a shot that wasn't fired after all (a Streak that didn't lock).
func refund_ammo(w: WeaponDef, kind: String = "") -> void:
	for a in ammo:
		if a.weapon == w and a.kind == kind and not a.destroyed:
			a.shots += 1
			return


func can_fire(w: MountedWeapon) -> bool:
	if sensor_hits >= 2 or w.destroyed or w.jammed or w.spent or is_location_out(w.loc):
		return false
	return not w.def.uses_ammo() or ammo_for(w.def, WeaponModes.ammo_kind(w)) > 0


func label() -> String:
	return def.display_name()
