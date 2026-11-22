class_name StructureTypes
extends RefCounted
## Internal structure types (book pp. 204-205). Endo-composite has no rules
## of its own. Composite: each point of damage takes two pips (after any
## explosion cap). Reinforced: a pip needs two full points; odd points are
## carried. TODO(rules): composite's last-pip rule across a transfer (marks a
## pip in both locations) is simplified to the last pip only; weights and
## slots are MegaMek construction data.

## Weight relative to standard structure; bulky slots (Inner Sphere, Clan).
const KINDS := {
	"endo_steel": {"name": "Endo Steel", "mult": 0.5},
	"endo_composite": {"name": "Endo-Composite", "mult": 0.75},
	"composite": {"name": "Composite", "mult": 0.5},
	"reinforced": {"name": "Reinforced", "mult": 2.0},
}


static func weight_mult(def: UnitDef) -> float:
	return float(KINDS.get(def.structure_type, {"mult": 1.0})["mult"])


## {used, pips, partial} for `amount` against `pips` structure left.
static func absorb(def: UnitDef, pips: int, partial: int, amount: int) -> Dictionary:
	match def.structure_type:
		"composite":
			var lost := mini(pips, amount * 2)
			return {"used": ceili(lost / 2.0), "pips": lost, "partial": 0}
		"reinforced":
			var total := amount + partial
			var gone := mini(pips, total / 2)
			if gone < pips:
				return {"used": amount, "pips": gone, "partial": total - gone * 2}
			return {"used": pips * 2 - partial, "pips": pips, "partial": 0}
	var s := mini(pips, amount)
	return {"used": s, "pips": s, "partial": partial}
