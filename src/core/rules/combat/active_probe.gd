class_name ActiveProbe
extends RefCounted
## Active probes (book pp. 196-197): Beagle (Inner Sphere, 4 hexes), Clan
## active probe (5) and light active probe (3). In this game a working probe
## lets its 'Mech ignore the to-hit modifiers of smoke and fog (not their
## line-of-sight blocking, p. 124) and the low visibility +1 (p. 121) when
## the target is within the probe's range and the probe isn't inside hostile
## ECM. Hidden units and minefields, which probes also reveal, aren't in the
## game. TODO(rules): weights and slots are construction data (not in the
## Core Rulebook); probes are activated items but are always on here.

const KINDS := {
	"beagle_probe": {"name": "Beagle Active Probe", "range": 4, "tons": 1.5, "slots": 2},
	"c_active_probe": {"name": "Active Probe", "range": 5, "tons": 1.0, "slots": 1},
	"c_light_active_probe": {"name": "Light Active Probe", "range": 3, "tons": 0.5, "slots": 1},
}


static func range_of(def: UnitDef) -> int:
	return int(KINDS[def.probe]["range"]) if def.probe != "" else EcmTypes.probe_range(def)


static func working(u: Unit) -> bool:
	if u.def.probe == "" and EcmTypes.probe_range(u.def) > 0:
		return Ecm.working(u)  # Watchdog CEWS
	return u.def.probe != "" and not u.probe_lost and not u.destroyed and not u.shutdown \
			and not u.is_location_destroyed(u.def.probe_loc)


## Does the attacker's probe cut through smoke, fog and murk to this target?
static func clears(state: GameState, attacker: Unit, target: Unit) -> bool:
	return target != null and working(attacker) \
			and Hex.distance(attacker.coord, target.coord) <= range_of(attacker.def) \
			and not Ecm.jammed(state, attacker)


## Line of sight with the to-hit points of intervening smoke/fog removed when
## the probe clears them (blocking stays as it was).
static func strip_smoke(los: Dictionary, state: GameState, attacker: Unit, target: Unit) -> Dictionary:
	if int(los.get("obs_pts", 0)) == 0 or not clears(state, attacker, target):
		return los
	var out := los.duplicate()
	out["woods"] = int(los["woods"]) - int(los["obs_pts"])
	return out
