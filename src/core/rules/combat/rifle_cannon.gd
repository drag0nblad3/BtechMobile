class_name RifleCannon
extends RefCounted
## Early rifle cannons lose three damage against military-grade 'Mech and
## combat-vehicle armor. Battle armor is exempt, as are low-BAR support
## vehicles; asset cards do not expose BAR and are left unchanged.
## TODO(rules): support vehicle BAR / commercial 'Mech armor variants.

const ARMOR_PENALTY := 3


static func damage(packet: int, target: Unit) -> int:
	if target.ba != null or target.asset != null:
		return packet
	return maxi(0, packet - ARMOR_PENALTY)
