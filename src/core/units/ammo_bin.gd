class_name AmmoBin
extends RefCounted
## One ton of ammunition for one weapon type.

var weapon: WeaponDef
var loc: int
var shots: int
var destroyed: bool = false


func _init(w: WeaponDef, location: int) -> void:
	weapon = w
	loc = location
	shots = w.ammo_per_ton


## Damage if the bin explodes: every remaining shot at full damage.
func explosion_damage() -> int:
	return 0 if destroyed or not weapon.ammo_explodes else shots * weapon.max_damage()
