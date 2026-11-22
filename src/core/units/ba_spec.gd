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
var claw := false      ## Battle claws (shown on the sheet).
var mechanized_ok := false  ## Can ride OmniMechs (MegaMek's canDoMechanizedBA).
var anti_mech := false  ## Can make leg and swarm attacks (light or medium, humanoid, unburdened).
var magnets := false    ## Claws with magnets: -1 to leg and swarm attacks, +1 to shake off.
var weapons: Array[Dictionary] = []


static func from_dict(d: Dictionary) -> BaSpec:
	var b := BaSpec.new()
	b.troopers = int(d["troopers"])
	b.armor = int(d["armor"])
	b.ground_mp = int(d.get("ground_mp", 1))
	b.jump_mp = int(d.get("jump_mp", 0))
	b.claw = bool(d.get("claw", false))
	b.mechanized_ok = bool(d.get("mechanized", b.claw))
	b.anti_mech = bool(d.get("anti_mech", b.claw))
	b.magnets = bool(d.get("magnets", false))
	for w: Dictionary in d.get("weapons", []):
		b.weapons.append(w)
	return b


## Mechanized: it can ride an OmniMech (AssetTransport). TODO(rules): taken from
## MegaMek per design; squads burdened by body-mounted missiles stay unable to
## make anti-'Mech attacks after their ammo is gone.
func mechanized() -> bool:
	return mechanized_ok


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
