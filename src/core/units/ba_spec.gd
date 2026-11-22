class_name BaSpec
extends RefCounted
## What a battle armor record sheet adds to a design (UnitDef.battle_armor):
## troopers, armor per trooper, ground and jump MP, and the squad's weapons
## (WeaponDef dictionaries, one entry per weapon each trooper carries).
## TODO(rules): Total Warfare battle armor, not in the Core Rulebook.

var troopers := 4
var armor := 0         ## Armor points per trooper (each also has 1 for the trooper).
var ground_mp := 1
var jump_mp := 0
var claw := false      ## Battle claws: leg and swarm attacks, rides OmniMechs (TODO(rules)).
var weapons: Array[Dictionary] = []


static func from_dict(d: Dictionary) -> BaSpec:
	var b := BaSpec.new()
	b.troopers = int(d["troopers"])
	b.armor = int(d["armor"])
	b.ground_mp = int(d.get("ground_mp", 1))
	b.jump_mp = int(d.get("jump_mp", 0))
	b.claw = bool(d.get("claw", false))
	for w: Dictionary in d.get("weapons", []):
		b.weapons.append(w)
	return b


## Mechanized: it can ride an OmniMech (AssetTransport). TODO(rules): every
## squad we have is humanoid medium-or-lighter armor with claws; gated on claws.
func mechanized() -> bool:
	return claw


## The squad's attack with weapon `i` while `alive` troopers can fire it:
## one cluster roll, one missile (or one weapon's damage) per trooper.
func weapon_def(i: int, alive: int) -> WeaponDef:
	var d: Dictionary = weapons[i].duplicate()
	d["id"] = "ba_" + String(d["id"])
	d["heat"] = 0
	var w := WeaponDef.from_dict(d)
	w.missiles = per_trooper(i) * maxi(alive, 0)
	w.group = 1
	return w


## Missiles (or shots) one trooper adds to weapon `i`'s cluster roll.
func per_trooper(i: int) -> int:
	return maxi(1, int(weapons[i].get("missiles", 0)))
