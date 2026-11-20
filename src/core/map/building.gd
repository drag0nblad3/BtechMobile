class_name Building
extends RefCounted
## A building standing on one hex. `cf` drops as it takes damage; at 0 it
## collapses into rubble. Changed only through GameController.

var type: BuildingType
var height: int = 1  ## Levels above the ground.
var cf: int = 0


func _init(t: BuildingType, levels: int = 1) -> void:
	type = t
	height = maxi(1, levels)
	cf = t.cf


## Damage the walls soak from each hit on a 'Mech inside (CF / 10, rounded up).
func absorbs() -> int:
	return ceili(cf / 10.0)
