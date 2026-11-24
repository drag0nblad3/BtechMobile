class_name VxFineGrid
extends RefCounted
## Increase the resolution of an existing occupied lattice without inventing
## geometry. Shared integer boundaries keep adjacent cells, holes and mirrors
## intact, even when the desired linear scale is not an integer.

const TARGET := 150000
const MIN_FINE := 140000


static func count_at(model: VxModel, scale: float) -> int:
	var count := 0
	var widths := {}
	for p: Dictionary in model.parts:
		for c: Vector3i in p["cells"]:
			for axis in 3:
				if not widths.has(c[axis]):
					widths[c[axis]] = _edge(c[axis] + 1, scale) - _edge(c[axis], scale)
			count += int(widths[c.x]) * int(widths[c.y]) * int(widths[c.z])
	return count


static func _edge(i: int, scale: float) -> int:
	return roundi(float(i) * scale)


## Keep already-dense authored versions. Otherwise choose the closest
## sampled scale at or below the target, not a fixed subdivision multiplier.
static func target_scale(model: VxModel, target: int = TARGET) -> float:
	var initial := model.cell_count()
	if initial <= 0 or initial >= target:
		return 1.0
	var estimate := pow(float(target) / initial, 1.0 / 3.0)
	var lower := 1.0
	var upper := estimate + 0.4
	var best := 1.0
	var best_count := initial
	# Counts can have small discontinuities from grid-boundary rounding.
	# Retain the best actually measured candidate rather than an estimate.
	for i in 12:
		var trial := (lower + upper) * 0.5
		var n := count_at(model, trial)
		if n <= target:
			if n > best_count:
				best = trial
				best_count = n
			lower = trial
		else:
			upper = trial
	for i in range(-5, 6):
		var trial := maxf(1.0, estimate + float(i) * 0.015)
		var n := count_at(model, trial)
		if n <= target and n > best_count:
			best = trial
			best_count = n
	return best


static func expand(model: VxModel, scale: float) -> void:
	if scale <= 1.0:
		return
	for p: Dictionary in model.parts:
		var fine := {}
		var original: Dictionary = p["cells"]
		for c: Vector3i in original:
			var lo := Vector3i(_edge(c.x, scale), _edge(c.y, scale), _edge(c.z, scale))
			var hi := Vector3i(_edge(c.x + 1, scale), _edge(c.y + 1, scale), _edge(c.z + 1, scale))
			for x in range(lo.x, hi.x):
				for y in range(lo.y, hi.y):
					for z in range(lo.z, hi.z):
						fine[Vector3i(x, y, z)] = original[c]
		p["cells"] = fine
		p["pivot"] = p["pivot"] * scale
	for table: Dictionary in [model.muzzles, model.jets]:
		for loc: int in table:
			var scaled: Array[Vector3] = []
			for point: Vector3 in table[loc]:
				scaled.append(point * scale)
			table[loc] = scaled
	model.voxel_size /= scale
	model.detail = maxi(model.detail, roundi(float(model.detail) * scale))
