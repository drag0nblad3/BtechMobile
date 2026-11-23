class_name BaStealth
extends RefCounted
## Battle armor stealth and mimetic armor (Total Warfare, as MegaMek plays it).
## Stealth: to-hit penalties by range bracket, always on (no ECM needed):
## basic and prototype +0/+1/+2, standard +1/+1/+2, improved +1/+2/+3
## (short/medium/long). Mimetic: +3 if the squad hasn't moved this turn, -1 per
## hex it moved (3+ hexes: none).
## TODO(rules): not in the Core Rulebook; conventional infantry (not in the
## game) would ignore stealth; myomer boosters cancel both (none carried).

const MODS := {
	"stealth_basic": [0, 1, 2], "stealth_prototype": [0, 1, 2],
	"stealth": [1, 1, 2], "stealth_improved": [1, 2, 3],
}
const NAMES := {
	"stealth_basic": "basic stealth armor", "stealth_prototype": "prototype stealth armor",
	"stealth": "stealth armor", "stealth_improved": "improved stealth armor", "mimetic": "mimetic armor",
}


static func kind(target: Unit) -> String:
	return target.def.battle_armor.armor_type if target.def.battle_armor else ""


static func add_mods(th: ToHit, target: Unit, br: int) -> void:
	var k := kind(target)
	if MODS.has(k):
		var mods: Array = MODS[k]
		var i := 0 if br <= WeaponDef.Bracket.SHORT else 1 if br == WeaponDef.Bracket.MEDIUM else 2
		if mods[i] > 0:
			th.add(NAMES[k], mods[i], "The squad's %s hides it: +%d at short, +%d medium, +%d long range. Get closer." % [NAMES[k], mods[0], mods[1], mods[2]])
	elif k == "mimetic":
		var m := maxi(0, 3 - target.hexes_moved)
		if m > 0:
			th.add(NAMES[k], m, "Mimetic armor blends into the background while the squad stays still: +3 if it hasn't moved, 1 less per hex it moved.")
