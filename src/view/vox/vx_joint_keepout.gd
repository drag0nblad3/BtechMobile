class_name VxJointKeepout
extends RefCounted
## Protect authored muzzle bores/empty channels from structural sockets.
## Source coordinates are in the coarse authoring grid.


static func mask(recipe: Dictionary, m: VxModel) -> Dictionary:
	var blocked := {}
	for part: Dictionary in recipe.get("parts", []):
		for shape: Dictionary in part.get("shapes", []) + part.get("add", []):
			if not shape.has("erase"):
				continue
			var bounds: Array = shape["erase"]
			var a := Vector3i(int(bounds[0][0]), int(bounds[0][1]), int(bounds[0][2]))
			var b := Vector3i(int(bounds[1][0]), int(bounds[1][1]), int(bounds[1][2]))
			for x in range(a.x, b.x + 1):
				for y in range(a.y, b.y + 1):
					for z in range(a.z, b.z + 1):
						blocked[Vector3i(x, y, z)] = true
	for points: Array in m.muzzles.values():
		for muzzle: Vector3 in points:
			var at := Vector3i(roundi(muzzle.x), roundi(muzzle.y), roundi(muzzle.z))
			for x in range(at.x - 1, at.x + 2):
				for y in range(at.y - 1, at.y + 2):
					for z in range(at.z - 2, at.z + 2):
						blocked[Vector3i(x, y, z)] = true
	return blocked
