class_name MountedWeapon
extends RefCounted
## A weapon installed on a Unit, with its runtime state.

var def: WeaponDef
var loc: int
var rear: bool
var destroyed: bool = false
var exploded: bool = false  ## An explosive weapon only blows up once.
## Firing mode (WeaponModes): "" normal, "ultra" two shots, "cluster" LB-X,
## "x2".."x6" rotary shots, "unjam" (RotaryAc), "er"/"he" ATM munitions (Atm).
var mode: String = ""
var artemis: bool = false       ## Linked Artemis IV fire control.
var artemis_lost: bool = false  ## Its fire control took a critical hit.
var apollo: bool = false  ## Linked Apollo MRM fire control (Apollo).
var apollo_lost: bool = false
var fired: bool = false  ## Fired this turn (blocks punching with that arm).
var engaged: int = 0     ## AMS: missile attacks engaged this turn (AntiMissile).
var narc_ammo: bool = false ## The unit carries Narc-equipped missiles for it (mode "narc").
var ammo_kinds: Array[String] = []  ## ATM munitions it has ammo for (Atm).
var jammed: bool = false ## Rotary AC jammed: can't fire until cleared (RotaryAc).
var spent: bool = false  ## A one-shot weapon has fired its shot.
var crit_hits: int = 0   ## Critical hits taken (an autocannon survives one, AutocannonCrit).
var on_vehicle: bool = false  ## Mounted on a combat vehicle: `loc` is a VehicleLoc.
var on_squad: bool = false  ## A battle armor squad's attack: every trooper fires it.


func _init(w: WeaponDef, location: int, rear_mounted: bool) -> void:
	def = w
	loc = location
	rear = rear_mounted


func label() -> String:
	if on_squad:
		return "%s (squad)" % def.name
	return "%s (%s%s)" % [def.name, VehicleLoc.CODES[loc] if on_vehicle else Location.code(loc), "R" if rear else ""]
