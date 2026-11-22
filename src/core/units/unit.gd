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
## Battlefield Support Asset (vehicle, infantry): its card state; null for 'Mechs.
var asset: AssetState = null
var vehicle: VehicleState = null  ## A combat vehicle (VehicleLoc locations).
var ba: BaState = null  ## A battle armor squad's troopers.

# Record sheet ------------------------------------------------------------
var armor: Array[int] = []
var rear_armor: Array[int] = []
var structure: Array[int] = []
## Odd points carried by hardened armor / reinforced structure (ArmorTypes, StructureTypes).
var armor_partial: Array[int] = []
var rear_partial: Array[int] = []
var structure_partial: Array[int] = []
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
var stealth_off: bool = false  ## Stealth armor switched off by choice (Stealth).
var stealth_request: int = -1  ## Stealth after the End Phase: 1 on, 0 off, -1 no change.
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
var drop_turn: int = 0  ## Turn a reserve may combat drop (CombatDrop).
var carry_arm: int = -1  ## Arm holding a mobile objective (MobileObjectives), or -1.
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
var landed: bool = false  ## Combat dropped this turn: +3 to hit it, can't act (CombatDrop).
var tmm_zero: bool = false  ## Revealed by an enemy this turn: no target movement modifier (HiddenUnits).
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
	if def.asset != null:
		_init_asset()
		return
	if def.vehicle != null:
		_init_vehicle()
		return
	if def.battle_armor != null:
		_init_ba()
		return
	for loc in Location.COUNT:
		armor.append(def.armor[loc] if def.armor.size() > loc else 0)
		rear_armor.append(def.rear_armor[loc] if def.rear_armor.size() > loc else 0)
		structure.append(StructureTable.points(def.tonnage, loc, def.quad))
		armor_partial.append(0)
		rear_partial.append(0)
		structure_partial.append(0)
	for m in def.weapon_mounts:
		var mw := MountedWeapon.new(m["weapon"], m["loc"], m["rear"])
		mw.artemis = m.get("artemis", false)
		mw.apollo = m.get("apollo", false)
		mw.capacitor = m.get("capacitor", false)
		weapons.append(mw)
	for a in def.ammo_mounts:
		var bin := AmmoBin.new(a["weapon"], a["loc"], a.get("kind", ""))
		if a.get("half", false):
			bin.shots = maxi(1, bin.shots / 2)
		ammo.append(bin)
	Narc.setup_ammo(self)
	Atm.setup_ammo(self)
	slots = CritLayout.build(def)


## An Asset has no locations: one placeholder point each keeps 'Mech checks
## (legs, head) quiet; damage goes to AssetDamage instead. Its single
## attack is mounted once per damage grouping.
func _init_asset() -> void:
	asset = AssetState.new(def.asset)
	for loc in Location.COUNT:
		armor.append(0)
		rear_armor.append(0)
		structure.append(1)
		slots.append([])
	var w := def.asset.attack_weapon(def.name)
	for i in def.asset.groupings:
		weapons.append(MountedWeapon.new(w, Location.CT, false))
	if def.asset.has("NARC"):
		weapons.append(MountedWeapon.new(AssetSpecials.narc_weapon(), Location.CT, false))
	var iw := AssetIndirect.weapon()
	for i in def.asset.special("IF"):
		weapons.append(MountedWeapon.new(iw, Location.CT, false))
	pilot.gunnery = asset.skill()


## A battle armor squad: troopers live in `ba`; the 'Mech locations hold one
## placeholder point each. Each weapon is one squad attack (BaSpec).
func _init_ba() -> void:
	ba = BaState.new(def.battle_armor)
	for loc in Location.COUNT:
		armor.append(0)
		rear_armor.append(0)
		structure.append(1)
		slots.append([])
	for i in def.battle_armor.weapons.size():
		var mw := MountedWeapon.new(def.battle_armor.weapon_def(i, ba.alive()), Location.CT, false)
		mw.on_squad = true
		weapons.append(mw)
		if mw.def.uses_ammo():
			ammo.append(AmmoBin.new(mw.def, Location.CT))
	if def.battle_armor.claw:
		for wd in [BaLegAttack.weapon(), BaSwarm.weapon(), BaSwarm.let_go_weapon()]:
			var mw := MountedWeapon.new(wd, Location.CT, false)
			mw.on_squad = true
			weapons.append(mw)


## A combat vehicle: armor and structure per VehicleLoc, no critical slots;
## damage goes to VehicleDamage. Crews start at Gunnery 4, Driving 5.
func _init_vehicle() -> void:
	vehicle = VehicleState.new(def.vehicle)
	for loc in Location.COUNT:
		var armored := loc in VehicleLoc.ARMORED and (loc != VehicleLoc.TURRET or def.vehicle.turret)
		armor.append(def.armor[loc] if armored else 0)
		rear_armor.append(0)
		# Body and the unused 'Mech leg slots: 1, never hit, so leg and ammo checks stay quiet.
		structure.append(VehicleLoc.structure(def.tonnage) if armored else 0 if loc == VehicleLoc.TURRET else 1)
		slots.append([])
	for m in def.weapon_mounts:
		var mw := MountedWeapon.new(m["weapon"], m["loc"], false)
		mw.on_vehicle = true
		weapons.append(mw)
	for a in def.ammo_mounts:
		var bin := AmmoBin.new(a["weapon"], a["loc"], a.get("kind", ""))
		if a.get("half", false):
			bin.shots = maxi(1, bin.shots / 2)
		ammo.append(bin)


func is_asset() -> bool:
	return asset != null


## Improved Skill (p. 141): lower base number, higher cost.
func set_asset_improved(on: bool) -> void:
	asset.improved = on
	pilot.gunnery = asset.skill()


func reset_for_turn() -> void:
	has_moved = false
	has_fired = false
	has_physical = false
	move_mode = -1
	hexes_moved = 0
	torso_twist = 0
	arms_flipped = false
	tmm_zero = false
	landed = false
	heat_generated = 0
	outside_heat = 0
	Masc.new_turn(self)
	Supercharger.new_turn(self)
	if vehicle != null and vehicle.crew_stunned > 0:
		vehicle.crew_stunned -= 1
	for w in weapons:
		w.fired = false
		w.engaged = 0
		w.cap_released = false


## Still on the field and able to take its turn in a phase.
func can_act() -> bool:
	return not destroyed and not shutdown and pilot.conscious and carrier_id() < 0 \
			and (vehicle == null or vehicle.crew_stunned == 0)


## Unit id of the transport or OmniMech it rides, -1 if on its own feet.
func carrier_id() -> int:
	if asset != null:
		return asset.carried_by
	return ba.carried_by if ba != null else -1


func set_carrier(id: int) -> void:
	if asset != null:
		asset.carried_by = id
	elif ba != null:
		ba.carried_by = id


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
	if asset != null:
		return 0 if asset.card.immobile() else def.walk_mp
	if vehicle != null:
		return vehicle.cruise_mp()
	if ba != null:
		return 0 if ba.swarming >= 0 else def.walk_mp
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
	if asset != null:
		return walk_mp()  # one fixed allowance every turn (p. 141)
	if vehicle != null:
		return vehicle.flank_mp()
	if ba != null:
		return walk_mp()  # battle armor doesn't run (TODO(rules))
	var slow := 1 if def.armor_type == "hardened" else 0  # hardened armor: -1 running MP (p. 202)
	if masc_active and sc_active:
		return maxi(walk_mp(), ceili(walk_mp() * 2.5) - slow)
	return maxi(walk_mp(), (walk_mp() * 2 if masc_active or sc_active else ceili(walk_mp() * 1.5)) - slow)


## Jump MP after jump jet damage.
func jump_mp() -> int:
	if ba != null and ba.swarming >= 0:
		return 0  # it rides the 'Mech it swarms
	if asset != null or vehicle != null or ba != null:
		return def.jump_mp
	var lost := {}  # jets by ref: an improved jet's two slots are one jet
	for loc in Location.COUNT:
		for s: CritSlot in slots[loc]:
			if s.kind == CritSlot.Kind.JUMP_JET and (s.hit or is_location_out(loc)):
				lost[s.ref] = true
	return maxi(0, def.jump_mp - lost.size())


## Working jump jets in the legs (they don't fire under water).
func leg_jump_jets() -> int:
	var jets := {}
	var dead := {}
	for loc in Location.legs(def):
		if is_location_destroyed(loc):
			continue
		for s: CritSlot in slots[loc]:
			if s.kind == CritSlot.Kind.JUMP_JET:
				jets[s.ref] = true
				if s.hit:
					dead[s.ref] = true
	return jets.size() - dead.size()


## Direction the torso (and arms) face: legs' facing plus any torso twist.
func torso_facing() -> int:
	return Hex.rotate(facing, torso_twist)


func ammo_for(w: WeaponDef, kind: String = "") -> int:
	var n := 0
	for a in ammo:
		if (a.weapon == w or a.weapon.id == w.id) and a.kind == kind and not a.destroyed:
			n += a.shots
	return n


## Uses one shot, from the first bin that still has some. False if empty.
func use_ammo(w: WeaponDef, kind: String = "") -> bool:
	for a in ammo:
		if (a.weapon == w or a.weapon.id == w.id) and a.kind == kind and not a.destroyed and a.shots > 0:
			a.shots -= 1
			return true
	return false


## Puts back a shot that wasn't fired after all (a Streak that didn't lock).
func refund_ammo(w: WeaponDef, kind: String = "") -> void:
	for a in ammo:
		if (a.weapon == w or a.weapon.id == w.id) and a.kind == kind and not a.destroyed:
			a.shots += 1
			return


func can_fire(w: MountedWeapon) -> bool:
	if sensor_hits >= 2 or w.destroyed or w.jammed or w.spent or is_location_out(w.loc):
		return false
	return not w.def.uses_ammo() or ammo_for(w.def, WeaponModes.ammo_kind(w)) > 0


func label() -> String:
	return def.display_name()
