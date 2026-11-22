class_name VehicleFire
extends RefCounted
## Combat vehicle weapons: front, side and rear weapons fire into their own
## arc; turret weapons fire all round unless the turret is locked (then
## forward only). Damaged sensors add +1 per hit (4 hits: no fire), a hit
## stabilizer +1 for weapons in that location.
## TODO(rules): Total Warfare from general knowledge; a locked turret is
## taken to point forward.

const ARC_OF := {VehicleLoc.FRONT: FiringArc.FRONT, VehicleLoc.LEFT: FiringArc.LEFT,
		VehicleLoc.RIGHT: FiringArc.RIGHT, VehicleLoc.REAR: FiringArc.REAR}


## Why this weapon can't bear on the target, or "".
static func arc_problem(u: Unit, w: MountedWeapon, target: Unit) -> String:
	if u.vehicle.sensor_hits >= 4:
		return "Its sensors are wrecked"
	var arc_id := FiringArc.fire_arc(u.coord, u.facing, target.coord)
	if w.loc == VehicleLoc.TURRET:
		if not u.vehicle.turret_locked or arc_id == FiringArc.FRONT:
			return ""
		return "The turret is locked facing forward; the target is in your %s arc" % FiringArc.NAMES[arc_id]
	if ARC_OF.get(w.loc, -1) == arc_id:
		return ""
	return "Target is in your %s arc; %s points %s" % [FiringArc.NAMES[arc_id], w.def.name,
			VehicleLoc.name_of(w.loc).to_lower()]


static func add_mods(th: ToHit, u: Unit, w: MountedWeapon) -> void:
	if u.vehicle.sensor_hits > 0:
		th.add("sensor damage", u.vehicle.sensor_hits, "Its damaged sensors make every shot harder.")
	if u.vehicle.stabilizers.has(w.loc):
		th.add("stabilizer hit", 1, "The stabilizer for this weapon's location is damaged.")
	if u.vehicle.commander_hit:
		th.add("commander hurt", 1, "Its wounded commander slows the whole crew down.")
