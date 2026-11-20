class_name Building
extends RefCounted
## A building standing on one hex (book pp. 130-137). It has no damage
## track: hard enough hits earn a Destroy Check, and a destroyed hex
## turns to rubble. Changed only through GameController.

var type: BuildingType
var height: int = 1  ## Levels above the ground.


func _init(t: BuildingType, levels: int = 1) -> void:
	type = t
	height = maxi(1, levels)


## May a 'Mech of this weight force its way in?
func admits(tons: int) -> bool:
	return type.civilian or UnitDef.class_index(tons) >= type.entry_class


## Damage a collapse does to a 'Mech `unit_height` levels tall inside.
func collapse_damage(unit_height: int) -> int:
	if type.civilian:
		return 0
	@warning_ignore("integer_division")
	return type.threshold / 2 * maxi(0, height - unit_height)
