class_name VehicleState
extends RefCounted
## A combat vehicle's live damage beyond armor and structure (Unit.vehicle):
## motive system damage, critical hit effects and the crew.
## TODO(rules): Total Warfare vehicle rules, not in the Core Rulebook.

var spec: VehicleSpec
var cruise_lost := 0       ## Cruising MP lost to moderate motive damage.
var half_cruise := false   ## Heavy motive damage: half Cruising MP.
var immobile := false      ## Major motive damage or an engine hit.
var driving_mod := 0       ## Added to Driving Skill rolls.
var sensor_hits := 0       ## Each +1 to its attacks (up to 4 = no fire).
var stabilizers: Dictionary = {}  ## VehicleLoc -> true: +1 for weapons there.
var turret_locked := false
var turret_lost := false
var crew_stunned := 0      ## Turns left the crew can't act.
var commander_hit := false ## +1 to all its rolls.
var driver_hit := false    ## +2 to Driving Skill rolls.
var engine_hit := false


func _init(s: VehicleSpec) -> void:
	spec = s


func cruise_mp() -> int:
	if immobile:
		return 0
	var mp := maxi(spec.cruise_mp - cruise_lost, 0)
	return mp / 2 if half_cruise else mp


func flank_mp() -> int:
	return ceili(cruise_mp() * 1.5)
