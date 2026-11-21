class_name MountedWeapon
extends RefCounted
## A weapon installed on a Unit, with its runtime state.

var def: WeaponDef
var loc: int
var rear: bool
var destroyed: bool = false
var exploded: bool = false  ## An explosive weapon only blows up once.
## Firing mode (WeaponModes): "" normal, "ultra" two shots, "cluster" LB-X,
## "x2".."x6" rotary shots, "unjam" (RotaryAc).
var mode: String = ""
var artemis: bool = false       ## Linked Artemis IV fire control.
var artemis_lost: bool = false  ## Its fire control took a critical hit.
var fired: bool = false  ## Fired this turn (blocks punching with that arm).
var engaged: int = 0     ## AMS: missile attacks engaged this turn (AntiMissile).
var narc_ammo: bool = false ## The unit carries Narc-equipped missiles for it (mode "narc").
var jammed: bool = false ## Rotary AC jammed: can't fire until cleared (RotaryAc).


func _init(w: WeaponDef, location: int, rear_mounted: bool) -> void:
	def = w
	loc = location
	rear = rear_mounted


func label() -> String:
	return "%s (%s%s)" % [def.name, Location.code(loc), "R" if rear else ""]
