class_name Thunderbolt
extends RefCounted
## Thunderbolt missiles: one large missile that hits one location for its
## full damage (5, 10, 15 or 20), no cluster roll; it may fire indirectly.
## An engaged AMS rolls 1D6 against it like a Narc pod: 4-6 destroys it.
## Book pp. 187, 206. TODO(rules): special munitions not modelled.


## Rolls the AMS shot; true if the missile is destroyed.
static func shot_down(dice: Dice, data: Dictionary) -> bool:
	data["ams"] = true
	data["ams_target"] = "Thunderbolt missile"
	data["ams_roll"] = AntiMissile.single_missile_roll(dice)
	data["pod_shot_down"] = AntiMissile.single_missile_down(data["ams_roll"])
	return data["pod_shot_down"]
