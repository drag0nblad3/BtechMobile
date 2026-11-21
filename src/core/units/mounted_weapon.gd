class_name MountedWeapon
extends RefCounted
## A weapon installed on a Unit, with its runtime state.

var def: WeaponDef
var loc: int
var rear: bool
var destroyed: bool = false
var exploded: bool = false  ## An explosive weapon only blows up once.
## Firing mode (WeaponModes): "" normal, "ultra" two shots, "cluster" LB-X.
var mode: String = ""
var artemis: bool = false       ## Linked Artemis IV fire control.
var artemis_lost: bool = false  ## Its fire control took a critical hit.
var fired: bool = false  ## Fired this turn (blocks punching with that arm).
var engaged: int = 0     ## AMS: missile attacks engaged this turn (AntiMissile).


func _init(w: WeaponDef, location: int, rear_mounted: bool) -> void:
	def = w
	loc = location
	rear = rear_mounted


func label() -> String:
	return "%s (%s%s)" % [def.name, Location.code(loc), "R" if rear else ""]
