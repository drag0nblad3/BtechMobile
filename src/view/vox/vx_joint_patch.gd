class_name VxJointPatch
extends RefCounted
## Small structural collars between actual parent/child occupied masses.
## A patch is 2x2 with one full backing layer on BOTH sides; not a touch.
## No generic carapace boxes, reparenting, or pivot edits.

const MAX_SPAN := 9
const MAX_ADDED := 40


static func choose(parent: Dictionary, child: Dictionary, owners: Dictionary,
		blocked: Dictionary, pivot: Vector3) -> Array[Vector3i]:
	var bound := _bounds(child)
	var best: Array[Vector3i] = []
	var best_score := 2147483647
	for face: Vector3i in parent:
		if _distance(face, bound) > MAX_SPAN + 2:
			continue
		for outward: Vector3i in VxConnectivity.DIRS:
			var axes: Array[Vector3i] = VxConnectivity._cross_axes(outward)
			for a_sign in [-1, 1]:
				for b_sign in [-1, 1]:
					var a: Vector3i = axes[0] * a_sign
					var b: Vector3i = axes[1] * b_sign
					var quad: Array[Vector3i] = [face, face + a, face + b, face + a + b]
					var solid := true
					for p: Vector3i in quad:
						if not parent.has(p) or not parent.has(p - outward):
							solid = false
							break
					if not solid:
						continue
					for distance in range(1, MAX_SPAN + 1):
						var existing := 0
						for p: Vector3i in quad:
							if child.has(p + outward * distance) or child.has(p + outward * (distance + 1)):
								existing += 1
						if existing < 2:
							continue
						var added: Array[Vector3i] = []
						var legal := true
						for layer in range(1, distance + 2):
							for p: Vector3i in quad:
								var at: Vector3i = p + outward * layer
								if child.has(at):
									continue
								if owners.has(at) or blocked.has(at):
									legal = false
									break
								added.append(at)
							if not legal:
								break
						if not legal or added.is_empty() or added.size() > MAX_ADDED:
							continue
						var near_pivot := int(face.distance_to(Vector3i(pivot))) if pivot.length_squared() > 0.1 else 0
						var score := added.size() * 20 + distance * 4 + mini(25, near_pivot)
						if score < best_score:
							best_score = score
							best = added
	return best


static func _bounds(cells: Dictionary) -> Dictionary:
	var low := Vector3i(100000, 100000, 100000)
	var high := Vector3i(-100000, -100000, -100000)
	for c: Vector3i in cells:
		low.x = mini(low.x, c.x)
		low.y = mini(low.y, c.y)
		low.z = mini(low.z, c.z)
		high.x = maxi(high.x, c.x)
		high.y = maxi(high.y, c.y)
		high.z = maxi(high.z, c.z)
	return {"lo": low, "hi": high}


static func _distance(c: Vector3i, bound: Dictionary) -> int:
	var lo: Vector3i = bound["lo"]
	var hi: Vector3i = bound["hi"]
	return maxi(0, maxi(lo.x - c.x, c.x - hi.x)) \
		+ maxi(0, maxi(lo.y - c.y, c.y - hi.y)) \
		+ maxi(0, maxi(lo.z - c.z, c.z - hi.z))
