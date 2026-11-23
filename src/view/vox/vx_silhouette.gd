class_name VxSilhouette
extends RefCounted
## Name-blind, orthographic silhouette fingerprints of occupied voxel masses.
## Only the projected boundary is used: materials, labels and colors cannot
## leak the answer. Front has highest weight, followed by side, 3/4 and top.

const VIEWS := ["front", "side", "quarter", "top"]
const WEIGHTS := {"front": 0.55, "side": 0.28,
	"quarter": 0.12, "top": 0.05}
const RESOLUTION := 40


static func model_cells(model: VxModel) -> Dictionary:
	var cells := {}
	for part: Dictionary in model.parts:
		for c: Vector3i in part["cells"]:
			cells[c] = true
	return cells


static func project(cells: Dictionary, view: String, size: int = RESOLUTION) -> Dictionary:
	var points := {}
	var min_u := INF
	var max_u := -INF
	var min_v := INF
	var max_v := -INF
	for c: Vector3i in cells:
		var uv := _orthographic(c, view)
		points[uv] = true
		min_u = minf(min_u, float(uv.x))
		max_u = maxf(max_u, float(uv.x))
		min_v = minf(min_v, float(uv.y))
		max_v = maxf(max_v, float(uv.y))
	if points.is_empty():
		return {}
	# Preserve width/height ratio, but remove absolute size and placement.
	# A small scout is not classified solely from its world scale.
	var span := maxf(1.0, maxf(max_u - min_u, max_v - min_v))
	var center_u: float = (min_u + max_u) * 0.5
	var center_v: float = (min_v + max_v) * 0.5
	var mask := {}
	for uv: Vector2i in points:
		var x := clampi(roundi((float(uv.x) - center_u) / span * (size - 3)
				+ (size - 1) * 0.5), 0, size - 1)
		var y := clampi(roundi((float(uv.y) - center_v) / span * (size - 3)
				+ (size - 1) * 0.5), 0, size - 1)
		mask[Vector2i(x, y)] = true
	return mask


static func signature(model: VxModel, size: int = RESOLUTION) -> Dictionary:
	var cells := model_cells(model)
	var result := {}
	for view: String in VIEWS:
		result[view] = project(cells, view, size)
	return result


static func similarity(left: Dictionary, right: Dictionary) -> float:
	var sum := 0.0
	for view: String in VIEWS:
		var a: Dictionary = left.get(view, {})
		var b: Dictionary = right.get(view, {})
		if a.is_empty() or b.is_empty():
			continue
		var overlap := 0
		for p: Vector2i in a:
			if b.has(p):
				overlap += 1
		var union_count: int = a.size() + b.size() - overlap
		if union_count > 0:
			sum += float(overlap) / float(union_count) * float(WEIGHTS[view])
	return sum


## The blind guess is the closest *other* chassis, not a classifier trained
## to echo model names. Higher scores mean greater ambiguity.
static func closest(id: String, fingerprints: Dictionary, limit: int = 3) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	if not fingerprints.has(id):
		return candidates
	for other: String in fingerprints:
		if other == id:
			continue
		candidates.append({"id": other,
			"similarity": similarity(fingerprints[id], fingerprints[other])})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["similarity"]) > float(b["similarity"]))
	candidates.resize(mini(limit, candidates.size()))
	return candidates


static func _orthographic(c: Vector3i, view: String) -> Vector2i:
	match view:
		"front":
			return Vector2i(c.x, c.y)
		"side":
			return Vector2i(c.z, c.y)
		"quarter":
			return Vector2i(c.x - c.z, c.y)
		"top":
			return Vector2i(c.x, c.z)
		_:
			return Vector2i(c.x, c.y)
