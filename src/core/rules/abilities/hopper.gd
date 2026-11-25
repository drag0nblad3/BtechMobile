class_name Hopper
extends RefCounted
## Hopper (Campaign Operations p. 76): losing a leg isn't an automatic fall.
## The MechWarrior makes the Piloting roll instead (the destroyed leg's
## modifier included); if it fails, the 'Mech falls and the roll to avoid
## pilot damage gets -2. On one leg it walks 1 and runs 2 MP as usual.
## TODO(rules): the book's +5 for the missing leg is the older value; we use
## the Core Rulebook's leg modifier from Psr.standing_mods.

const SEATBELT_MOD := -2


## The owed roll is a lost leg that this MechWarrior may try to stay up on.
static func applies(u: Unit, p: Dictionary) -> bool:
	return Spa.has(u, Spa.HOPPER) and String(p.get("reason", "")) == "leg destroyed" \
			and not u.def.quad and u.legs_destroyed() < 2
