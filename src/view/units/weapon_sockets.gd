class_name WeaponSockets
extends RefCounted
## Cosmetic, chassis-specific positions for existing placeholder models.
## Native model-defined muzzle nodes win when art assets provide them.

const PATH := "res://data/graphics/weapon_sockets.json"
static var _profiles: Dictionary = {}


static func profile(def: UnitDef) -> Dictionary:
	if _profiles.is_empty():
		_profiles = JsonFile.read(PATH).get("chassis", {})
	var id := def.sprite if def.sprite != "" else def.name.to_lower().replace(" ", "_")
	return _profiles.get(id, {})


static func local_position(def: UnitDef, weapon_index: int) -> Vector3:
	if weapon_index < 0 or weapon_index >= def.weapon_mounts.size():
		return Vector3.INF
	var cfg := profile(def)
	if cfg.is_empty():
		return Vector3.INF
	var mount: Dictionary = def.weapon_mounts[weapon_index]
	var name := Location.code(int(mount["loc"]))
	if bool(mount.get("rear", false)):
		name += "_REAR"
	var sockets: Array = cfg.get(name, [])
	if sockets.is_empty():
		return Vector3.INF
	var occurrence := 0
	for i in weapon_index:
		var other: Dictionary = def.weapon_mounts[i]
		if int(other["loc"]) == int(mount["loc"]) and bool(other.get("rear", false)) == bool(mount.get("rear", false)):
			occurrence += 1
	var coords: Array = sockets[mini(occurrence, sockets.size() - 1)]
	if coords.size() != 3:
		return Vector3.INF
	var extra := maxf(0.0, float(occurrence - (sockets.size() - 1))) * 0.035
	return Vector3(float(coords[0]) + extra, float(coords[1]), float(coords[2]))


static func attach(model: Node3D, def: UnitDef) -> void:
	if model == null or def == null or def.is_support():
		return
	for i in def.weapon_mounts.size():
		var p := local_position(def, i)
		if p == Vector3.INF:
			continue
		var key := "muzzle_%d" % i
		if _has_socket(model, key):
			continue
		var marker := Marker3D.new()
		marker.name = key
		marker.position = p * (1.25 + float(def.tonnage) / 250.0)
		model.add_child(marker)


static func _has_socket(parent: Node, wanted: String) -> bool:
	if parent.name == wanted:
		return true
	for child in parent.get_children():
		if _has_socket(child, wanted):
			return true
	return false
