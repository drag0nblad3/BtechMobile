class_name WeaponDef
extends RefCounted
## Static weapon stats from data/weapons.json. Ranges are the upper bound of
## each bracket in hexes; `min` > 0 means a minimum-range penalty applies.

enum Bracket { OUT, SHORT, MEDIUM, LONG }

var id: String
var name: String
var type: String       ## "energy", "ballistic" or "missile".
var heat: int
var damage: int        ## Per shot, or per missile for missile weapons.
var missiles: int      ## 0 for non-missile weapons.
var group: int         ## Missile damage cluster size (LRM 5, SRM 1).
var min_range: int
var short_range: int
var medium_range: int
var long_range: int
var slots: int
var tons: float          ## Weight in tons (book weapon tables).
var ammo_per_ton: int  ## 0 = no ammo needed.
var bv: int           ## Battle Value of the weapon.
var ammo_bv: int       ## Battle Value of one ton of its ammo.
var heat_damage: bool  ## A hit also adds its damage as heat to the target (flamers).
var indirect: bool     ## May fire without line of sight via a spotter (LRMs).
var to_hit_mod: int    ## The weapon's own to-hit modifier (pulse lasers -2).
var explodes: bool     ## Blows up on its first critical hit (Gauss rifles, p. 184).
var ammo_explodes: bool = true  ## False for Gauss slugs.


static func from_dict(d: Dictionary) -> WeaponDef:
	var w := WeaponDef.new()
	w.id = d["id"]
	w.name = d["name"]
	w.type = d.get("type", "energy")
	w.heat = int(d.get("heat", 0))
	w.damage = int(d["damage"])
	w.missiles = int(d.get("missiles", 0))
	w.group = int(d.get("group", 1))
	w.min_range = int(d.get("min", 0))
	w.short_range = int(d["short"])
	w.medium_range = int(d["medium"])
	w.long_range = int(d["long"])
	w.slots = int(d.get("slots", 1))
	w.tons = float(d.get("tons", 0.0))
	w.ammo_per_ton = int(d.get("ammo_per_ton", 0))
	w.bv = int(d.get("bv", 0))
	w.ammo_bv = int(d.get("ammo_bv", 0))
	w.indirect = bool(d.get("indirect", false))
	w.heat_damage = bool(d.get("heat_damage", false))
	w.to_hit_mod = int(d.get("to_hit", 0))
	w.explodes = bool(d.get("explodes", false))
	w.ammo_explodes = bool(d.get("ammo_explodes", true))
	return w


func uses_ammo() -> bool:
	return ammo_per_ton > 0


func is_cluster() -> bool:
	return missiles > 0


## Damage if every shot/missile hits (for advice and record sheets).
func max_damage() -> int:
	return damage * missiles if is_cluster() else damage


func bracket(range_hexes: int) -> int:
	if range_hexes <= short_range:
		return Bracket.SHORT
	if range_hexes <= medium_range:
		return Bracket.MEDIUM
	if range_hexes <= long_range:
		return Bracket.LONG
	return Bracket.OUT


func range_text() -> String:
	var s := "%d/%d/%d" % [short_range, medium_range, long_range]
	return ("min %d, " % min_range + s) if min_range > 0 else s
