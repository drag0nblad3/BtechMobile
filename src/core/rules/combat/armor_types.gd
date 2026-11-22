class_name ArmorTypes
extends RefCounted
## Special armor (book pp. 201-202). Its effects apply only while the struck
## location (or torso facing) has armor left when the hit lands.
## Ballistic-reinforced (DB, M), laser-reflective (lasers, PPCs, flamers,
## plasma) and reactive (M, AE) armor: each pip absorbs 2 points of those
## attacks; an odd point still takes a pip. Reflective armor loses 2 pips a
## point to area-effect, collapse, fall and physical damage. Hardened: a pip
## needs 2 full points (odd points are carried), -2 on TAC rolls, +1 to
## piloting and -1 running MP. Ferro-lamellor: -1 damage per 5 (or part) of
## each hit; a hit cut to 0 can't wound the pilot or roll a TAC.
## Impact-resistant: falls and collapses halved (round down), physical attacks
## -1 per 3 (or part), at least 1. Heat-dissipating: flamer and plasma damage
## halved (round up), no outside heat. Anti-penetrative ablation: no TAC.
## Stealth armor stops damage like standard armor; its effects are in Stealth.
## TODO(rules): weights and slots are MegaMek construction data; reactive
## armor's critical reroll on its slots and AP ammo are not modelled.

## Points per ton relative to standard armor (MegaMek), and bulky slots.
const KINDS := {
	"hardened": {"name": "Hardened", "mult": 0.5, "about": "each pip takes 2 points; -2 TAC; +1 piloting, -1 running MP"},
	"ferro_lamellor": {"name": "Ferro-Lamellor", "mult": 0.875, "about": "-1 damage per 5 of each hit"},
	"reflective": {"name": "Reflective", "mult": 1.0, "about": "halves laser, PPC, flamer and plasma damage; doubles physical, fall and collapse damage"},
	"reactive": {"name": "Reactive", "mult": 1.0, "about": "halves missile damage"},
	"ballistic_reinforced": {"name": "Ballistic-Reinforced", "mult": 0.75, "about": "halves autocannon, Gauss and missile damage"},
	"anti_penetrative": {"name": "Anti-Penetrative Ablation", "mult": 0.75, "about": "no through-armor criticals"},
	"impact_resistant": {"name": "Impact-Resistant", "mult": 0.875, "about": "halves fall and collapse damage, -1 per 3 from physical attacks"},
	"heat_dissipating": {"name": "Heat-Dissipating", "mult": 0.625, "about": "halves flamer and plasma damage; no outside heat"},
	"stealth": {"name": "Stealth", "mult": 1.0, "about": "while on: +1 to hit it at medium range, +2 at long, 10 heat a turn, its ECM and C3 off (Stealth)"},
}
const COLLISION := ["fall", "collapse"]


## Record-sheet line, e.g. "hardened armor (each pip takes 2 points; ...)".
static func describe(def: UnitDef) -> String:
	var k: Dictionary = KINDS[def.armor_type]
	return "%s armor (%s)" % [String(k["name"]).to_lower(), k["about"]]


static func is_special(def: UnitDef) -> bool:
	return KINDS.has(def.armor_type)


## The packet after armor that reduces whole hits.
static func reduce(def: UnitDef, amount: int, attack: Array) -> int:
	match def.armor_type:
		"ferro_lamellor":
			return amount - ceili(amount / 5.0)
		"impact_resistant":
			if attack.has("physical"):
				return maxi(1, amount - ceili(amount / 3.0))
			if _collision(attack):
				return maxi(1, amount / 2)
		"heat_dissipating":
			if attack.has("heat"):
				return ceili(amount / 2.0)
	return amount


## How much of `amount` the armor takes and how many pips it loses:
## {used, pips, partial}. `pips` armor left, `partial` odd points carried.
static func absorb(def: UnitDef, pips: int, partial: int, amount: int, attack: Array) -> Dictionary:
	match def.armor_type:
		"hardened":
			var total := amount + partial
			var gone := mini(pips, total / 2)
			if gone < pips:
				return {"used": amount, "pips": gone, "partial": total - gone * 2}
			return {"used": pips * 2 - partial, "pips": pips, "partial": 0}
		"reflective":
			if attack.has("DE") or attack.has("P"):
				return _double(pips, amount)
			if attack.has("physical") or attack.has("AE") or _collision(attack):
				var lost := mini(pips, amount * 2)
				return {"used": ceili(lost / 2.0), "pips": lost, "partial": partial}
		"ballistic_reinforced":
			if attack.has("DB") or attack.has("M"):
				return _double(pips, amount)
		"reactive":
			if attack.has("M") or attack.has("AE"):
				return _double(pips, amount)
	var a := mini(pips, amount)
	return {"used": a, "pips": a, "partial": partial}


## TAC roll change while the location still had armor: null for no TAC.
static func tac_mod(def: UnitDef) -> Variant:
	match def.armor_type:
		"anti_penetrative":
			return null
		"hardened":
			return -2
	return 0


static func no_outside_heat(def: UnitDef) -> bool:
	return def.armor_type == "heat_dissipating"


## Hardened armor slows a 'Mech: +1 to piloting rolls.
static func add_psr(th: ToHit, u: Unit) -> void:
	if u.def.armor_type == "hardened":
		th.add("hardened armor", 1, "Hardened armor is heavy and stiff: +1 to piloting rolls.")


## Attack tags for a weapon (its attack types plus "heat" for flamers and plasma).
static func weapon_attack(d: WeaponDef) -> Array:
	var out: Array = d.attack_types()
	if d.heat_damage or d.heat_dice > 0:
		out.append("heat")
	return out


static func _double(pips: int, amount: int) -> Dictionary:
	var gone := mini(pips, ceili(amount / 2.0))
	return {"used": mini(amount, gone * 2), "pips": gone, "partial": 0}


static func _collision(attack: Array) -> bool:
	return attack.any(func(t: String) -> bool: return COLLISION.has(t))
