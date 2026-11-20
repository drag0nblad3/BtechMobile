class_name VoxelChassis
extends RefCounted
## Visual prototypes keyed to IDs already present in data/units.
## Does not modify the rules engine's UnitDef or any combat state.

const PATH := "res://data/graphics/voxel_chassis.json"


static func all() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var data: Dictionary = JsonFile.read(PATH)
	for entry: Dictionary in data.get("chassis", []):
		entries.append(entry)
	return entries


static func find(profile_id: String) -> Dictionary:
	for profile in all():
		if profile.get("id", "") == profile_id:
			return profile
	return all()[0]


static func is_digitigrade(profile: Dictionary) -> bool:
	return profile.get("gait", "humanoid") == "digitigrade"
