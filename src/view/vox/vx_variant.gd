class_name VxVariant
extends RefCounted
## Source-preserving per-variant voxel geometry overlays. The shared chassis
## stays untouched; moving-part overlays are applied at authoring resolution.


static func resolve(base: Dictionary, variant: Dictionary) -> Dictionary:
	var result: Dictionary = base.duplicate(true)
	for key in variant:
		if key not in ["source", "part_overlays"]:
			result[key] = variant[key]
	for edit: Dictionary in variant.get("part_overlays", []):
		var found := false
		for part: Dictionary in result.get("parts", []):
			if part.get("name", "") != edit.get("part", ""):
				continue
			found = true
			for key in ["shapes", "add"]:
				if not edit.has(key):
					continue
				var existing: Array = part.get(key, []).duplicate(true)
				existing.append_array(edit[key])
				part[key] = existing
			break
		if not found:
			push_error("Voxel overlay targets unknown part: %s" % edit.get("part", ""))
	return result
