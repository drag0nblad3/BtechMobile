class_name AmmoBin
extends RefCounted
## One ton of ammunition for one weapon type.

var weapon: WeaponDef
var loc: int
var shots: int
var destroyed: bool = false
var kind: String = ""  ## "" standard, "cluster" for LB-X, "narc" Narc-equipped missiles.


func _init(w: WeaponDef, location: int, ammo_kind: String = "") -> void:
	weapon = w
	loc = location
	kind = ammo_kind
	shots = w.munitions[ammo_kind].ammo_per_ton if w.munitions.has(ammo_kind) else w.ammo_per_ton


## Damage if the bin explodes: every remaining shot at full damage.
func explosion_damage() -> int:
	var p: WeaponDef = weapon.munitions.get(kind, weapon)  # MML SRMs: 2 a missile
	var per := p.ammo_damage if p.ammo_damage > 0 else p.max_damage()
	return 0 if destroyed or not weapon.ammo_explodes else shots * per
