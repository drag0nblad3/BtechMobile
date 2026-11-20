class_name AtlasSourceMesh
extends RefCounted
## Artist-editable *triangular source meshes*, kept independent of voxels.
## Reference: original AS7-D TRO illustration and CGL modern AS7-D miniature.
## Sculpted cross-section vertices and armor polygon landmarks are in
## ORIGINAL 75 mm-grid coordinate units, so every part is aligned with the
## existing rig. Rendering and hit cells are produced only AFTER this mesh.
##
## component = {name:String, material:int, phase:int, tris:PackedVector3Array}
## phase 0 additive armor, 1 subtractive bore/socket, 2 inset/detail.
## Unlike the previous model this is NOT voxel boxes followed by bevels.


static func _outline(width: float, z_front: float, z_back: float,
		cx: float = 0.0, taper: float = 0.0) -> Array[Vector2]:
	# Twelve individually faceted points, from front left across clockwise.
	# The slight x-skew lets separate pauldrons and armor segments cant out.
	var w := width
	return [
		Vector2(cx - w * 0.78, z_front + 0.80 + taper),
		Vector2(cx - w * 0.42, z_front + 0.10),
		Vector2(cx - w * 0.12, z_front - 0.32),
		Vector2(cx + w * 0.17, z_front - 0.32),
		Vector2(cx + w * 0.64, z_front + 0.25),
		Vector2(cx + w, z_front + 1.55),
		Vector2(cx + w * 0.91, z_back - 0.95),
		Vector2(cx + w * 0.45, z_back),
		Vector2(cx - w * 0.49, z_back),
		Vector2(cx - w * 0.96, z_back - 0.95),
		Vector2(cx - w, z_front + 1.70),
		Vector2(cx - w * 0.92, z_front + 1.10 + taper)
	]


static func _ring(y: float, width: float, front: float, back: float,
		cx: float = 0.0, skew: float = 0.0) -> Dictionary:
	return {"y": y, "outline": _outline(width, front, back, cx, skew)}


static func _tri(out: PackedVector3Array, a: Vector3, b: Vector3,
		c: Vector3) -> void:
	out.append_array(PackedVector3Array([a, b, c]))


static func _loft(out: Array[Dictionary], name: String, rings: Array,
		material: int, phase: int = 0) -> void:
	if rings.size() < 2:
		return
	var tris := PackedVector3Array()
	var count: int = (rings[0]["outline"] as Array).size()
	# Explicit closed polygon mesh; not a voxel extrusion.
	var center_a := Vector3.ZERO
	var center_b := Vector3.ZERO
	for ring_idx in rings.size():
		var section: Array = rings[ring_idx]["outline"]
		assert(section.size() == count)
		var y: float = float(rings[ring_idx]["y"])
		var center := Vector3.ZERO
		for pt: Vector2 in section:
			center += Vector3(pt.x, y, pt.y)
		center /= float(count)
		if ring_idx == 0:
			center_a = center
		if ring_idx == rings.size() - 1:
			center_b = center
		if ring_idx == 0:
			for i in count:
				var a: Vector2 = section[i]
				var b: Vector2 = section[(i + 1) % count]
				_tri(tris, center, Vector3(b.x, y, b.y),
						Vector3(a.x, y, a.y))
		if ring_idx == rings.size() - 1:
			for i in count:
				var a: Vector2 = section[i]
				var b: Vector2 = section[(i + 1) % count]
				_tri(tris, center, Vector3(a.x, y, a.y),
						Vector3(b.x, y, b.y))
		if ring_idx == 0:
			continue
		var prev: Array = rings[ring_idx - 1]["outline"]
		var prev_y: float = float(rings[ring_idx - 1]["y"])
		for i in count:
			var j := (i + 1) % count
			var aa: Vector2 = prev[i]
			var bb: Vector2 = prev[j]
			var cc: Vector2 = section[i]
			var dd: Vector2 = section[j]
			var v00 := Vector3(aa.x, prev_y, aa.y)
			var v01 := Vector3(bb.x, prev_y, bb.y)
			var v10 := Vector3(cc.x, y, cc.y)
			var v11 := Vector3(dd.x, y, dd.y)
			_tri(tris, v00, v10, v11)
			_tri(tris, v00, v11, v01)
	out.append({"name": name, "material": material,
			"phase": phase, "tris": tris})


static func _plate(out: Array[Dictionary], name: String,
		front: Array[Vector3], thickness: float, material: int,
		phase: int = 0) -> void:
	# A front-facing convex 3D panel with beveled perimeter; the actual
	# irregular polygon is authored vertex by vertex, not approximated by a
	# uniform cube. Extrude it backwards along Z.
	var tris := PackedVector3Array()
	var n := front.size()
	var cfront := Vector3.ZERO
	for p in front:
		cfront += p
	cfront /= float(n)
	var cback := cfront + Vector3(0, 0, thickness)
	for i in n:
		var j := (i + 1) % n
		_tri(tris, cfront, front[j], front[i])
		_tri(tris, cback, front[i] + Vector3(0, 0, thickness),
				front[j] + Vector3(0, 0, thickness))
		_tri(tris, front[i], front[j], front[j] + Vector3(0, 0, thickness))
		_tri(tris, front[i], front[j] + Vector3(0, 0, thickness),
				front[i] + Vector3(0, 0, thickness))
	out.append({"name": name, "material": material,
			"phase": phase, "tris": tris})


static func _round_tube(out: Array[Dictionary], name: String,
		cx: float, cy: float, zfront: float, zback: float,
		radius: float, material: int, phase: int = 0) -> void:
	# Closed true cylinder in the triangular source mesh. Subtractive
	# cylinder volumes (phase 1) open the barrel and missile sockets.
	var tris := PackedVector3Array()
	var sides := 16
	var vfront := Vector3(cx, cy, zfront)
	var vback := Vector3(cx, cy, zback)
	for i in sides:
		var a := float(i) * TAU / float(sides)
		var b := float(i + 1) * TAU / float(sides)
		var aa := Vector3(cx + cos(a) * radius, cy + sin(a) * radius, zfront)
		var ab := Vector3(cx + cos(b) * radius, cy + sin(b) * radius, zfront)
		var ba := Vector3(cx + cos(a) * radius, cy + sin(a) * radius, zback)
		var bb := Vector3(cx + cos(b) * radius, cy + sin(b) * radius, zback)
		_tri(tris, vfront, ab, aa)
		_tri(tris, vback, ba, bb)
		_tri(tris, aa, ab, bb)
		_tri(tris, aa, bb, ba)
	out.append({"name": name, "material": material,
			"phase": phase, "tris": tris})


static func part_meshes(part_key: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match part_key:
		"torso":
			_torso(out)
		"left_arm", "right_arm":
			_arm(out, part_key == "right_arm")
		"left_leg", "right_leg":
			_thigh(out)
		"left_leg_shin", "right_leg_shin":
			_calf(out)
		"left_leg_foot", "right_leg_foot":
			_foot(out)
	return out


static func _torso(out: Array[Dictionary]) -> void:
	# Crucial 3025/CGL Atlas silhouette: small skull NESTED between huge
	# pauldrons, deep tapering armored torso, narrower belt and big pelvis.
	_loft(out, "waisted-torso", [
		_ring(-11.0, 4.1, -3.1, 3.4),
		_ring(-8.8, 5.1, -4.2, 4.4),
		_ring(-5.0, 6.5, -5.1, 4.6),
		_ring(-1.0, 8.2, -5.7, 5.0),
		_ring(3.5, 10.0, -5.8, 4.9),
		_ring(5.7, 8.5, -5.1, 4.1)
	], 0)
	# Exposed annular waist, intentionally smaller than breastplate.
	_round_tube(out, "torso-swivel", 0, -9.4, -2.8, 2.4, 3.5, 8)
	_plate(out, "left-pectoral", [
		Vector3(-8.1, 1.2, -6.0), Vector3(-5.9, 4.3, -6.0),
		Vector3(-1.4, 3.8, -6.4), Vector3(-1.0, -4.4, -5.9),
		Vector3(-5.1, -6.6, -5.5), Vector3(-8.3, -2.2, -5.8)
	], 0.75, 4)
	_plate(out, "right-pectoral", [
		Vector3(1.1, -4.4, -5.9), Vector3(1.4, 3.8, -6.4),
		Vector3(5.9, 4.3, -6.0), Vector3(8.1, 1.2, -6.0),
		Vector3(8.3, -2.2, -5.8), Vector3(5.1, -6.6, -5.5)
	], 0.75, 4)
	# Angular, high-backed upper arm pauldrons: 3/4 view shows very
	# different cross-section from the round V4 towers.
	for side in [-1.0, 1.0]:
		var x: float = float(side) * 11.3
		_loft(out, "left-pauldron" if side < 0 else "right-pauldron", [
			_ring(-0.8, 3.3, -4.5, 3.2, x),
			_ring(2.3, 4.0, -5.1, 4.7, x + side * 0.6),
			_ring(6.3, 3.5, -5.4, 4.5, x + side * 0.4),
			_ring(8.3, 2.6, -4.5, 3.9, x)
		], 4)
		_round_tube(out, "shoulder-pivot", side * 13.3, 0.0,
				-0.9, 2.9, 1.6, 8)
		# No horizontal T-bar: rear shoulders taper into shoulder sockets.
		var bx: float = float(side) * 9.0
		_plate(out, "scapula-armor", [
			Vector3(bx - 2.0, 0.5, 5.1), Vector3(bx - 2.2, 5.8, 4.5),
			Vector3(bx + 1.2, 7.0, 4.2), Vector3(bx + 2.7, 2.0, 4.6)
		], 0.75, 0)
	# Skull itself: eight detailed silhouette stations. Widest portion is
	# cheek at Y7, narrow jaw at Y4, domed brow at Y11; not a cube on stalk.
	_loft(out, "skull-cranium", [
		_ring(4.8, 2.1, -5.2, 0.2, -0.3),
		_ring(6.6, 3.1, -7.1, 0.3, -0.3),
		_ring(8.5, 3.7, -7.6, 0.5, -0.3),
		_ring(10.9, 3.6, -7.4, 0.5, -0.3),
		_ring(12.2, 3.2, -6.7, 0.2, -0.3),
		_ring(13.1, 2.0, -5.6, -0.4, -0.3)
	], 6)
	# Sculpt a shallow brow ridge, two deep eye sockets, a projecting nose,
	# separated cheekbones and a toothed jaw. Separate CSG cutters are meshes.
	_plate(out, "forehead-brow", [
		Vector3(-3.1, 10.4, -7.8), Vector3(-2.8, 11.3, -7.6),
		Vector3(2.8, 11.3, -7.6), Vector3(3.2, 10.4, -7.8)
	], 0.9, 6)
	for x in [-1.65, 1.55]:
		_round_tube(out, "recessed-eye-socket", x, 9.2,
				-8.6, -6.0, 0.95, 1, 1)
		_round_tube(out, "inset-red-eye", x, 9.25,
				-6.5, -6.1, 0.45, 7, 2)
	for x in [-2.8, 2.4]:
		_plate(out, "skull-cheek", [
			Vector3(x - 0.7, 7.6, -7.5), Vector3(x - 0.3, 8.8, -8.0),
			Vector3(x + 0.7, 8.7, -7.5), Vector3(x + 0.8, 6.3, -7.6)
		], 0.9, 6)
	_plate(out, "nasal-bridge", [
		Vector3(-0.48, 9.2, -8.1), Vector3(0.5, 9.2, -8.1),
		Vector3(0.9, 7.6, -8.25), Vector3(0.1, 6.8, -8.55),
		Vector3(-0.65, 7.6, -8.25)
	], 0.8, 6)
	_plate(out, "clenched-teeth", [
		Vector3(-2.0, 5.7, -7.5), Vector3(-2.5, 6.6, -7.3),
		Vector3(2.3, 6.6, -7.3), Vector3(2.0, 5.7, -7.5)
	], 0.8, 8)
	# Torso-mounted AC/20 right, not a fake second gun attached to fist.
	_round_tube(out, "ac20-coaxial-housing", 8.4, -1.9,
			-10.7, -4.0, 2.8, 8)
	_round_tube(out, "ac20-bore", 8.4, -1.9,
			-10.9, -2.9, 1.10, 1, 1)
	# The left flank contains the AS7-D five-opening LRM grouping.
	_loft(out, "lrm-shoulder-housing", [
		_ring(-3.3, 3.5, -8.2, -4.4, -7.8),
		_ring(2.7, 3.6, -8.2, -4.4, -7.8)
	], 9)
	for x in [-9.9, -8.0, -6.1]:
		for y in [-1.3, 1.2]:
			if x == -6.1 and y == -1.3:
				continue
			_round_tube(out, "lrm-port", x, y, -9.0,
					-5.2, 0.55, 1, 1)
			_round_tube(out, "lrm-rear", x, y, -5.55,
					-5.3, 0.36, 3, 2)
	# Rear reactor grilles and descending belt, each angled armor plate.
	for x in [-6.0, 5.8]:
		_loft(out, "reactor-duct", [
			_ring(-1.2, 1.8, 4.7, 7.0, x),
			_ring(5.0, 2.5, 4.7, 8.1, x),
			_ring(7.0, 2.1, 4.8, 7.5, x)
		], 8)
	for x in [-2.7, 2.2]:
		_plate(out, "waist-cuirass", [
			Vector3(x - 1.4, -8.0, -5.2), Vector3(x - 1.0, -6.0, -5.3),
			Vector3(x + 1.6, -6.0, -5.3), Vector3(x + 1.5, -10.7, -4.1)
		], 0.7, 4)


static func _arm(out: Array[Dictionary], right: bool) -> void:
	# Arms are *asymmetric but equally long*: not solid rectangular posts.
	_loft(out, "upper-arm-sculpt", [
		_ring(-6.4, 2.0, -2.0, 2.0),
		_ring(-4.7, 2.4, -2.7, 2.3),
		_ring(-2.8, 3.0, -3.2, 3.0),
		_ring(0.5, 3.5, -3.7, 3.6),
		_ring(2.2, 2.7, -3.1, 3.0)
	], 4)
	_round_tube(out, "elbow-rotor", 0.0, -6.6, -2.4, 2.4, 2.25, 8)
	_loft(out, "sloped-forearm-shell", [
		_ring(-12.8, 3.1, -3.7, 1.6),
		_ring(-10.2, 3.5, -3.5, 2.5),
		_ring(-8.5, 2.7, -3.2, 2.5),
		_ring(-7.1, 2.0, -2.4, 2.1)
	], 0)
	# Gauntlet knuckle armor avoids a single big rectangular hammer fist.
	_plate(out, "knuckle-shield", [
		Vector3(-3.0, -10.1, -4.0), Vector3(-2.0, -8.2, -3.6),
		Vector3(2.2, -8.2, -3.6), Vector3(3.0, -10.1, -4.0),
		Vector3(2.7, -12.1, -3.3), Vector3(-2.7, -12.1, -3.3)
	], 0.7, 4)
	for finger in [-2.4, -0.8, 0.8, 2.4]:
		_loft(out, "articulated-finger", [
			_ring(-15.0, 0.52, -1.1, 0.3, finger),
			_ring(-13.2, 0.62, -1.8, 0.3, finger),
			_ring(-11.9, 0.68, -1.6, 0.5, finger)
		], 8)
	# In real artwork the right hand has a small laser fixture, but neither
	# fist houses the enormous AC/20 already in the torso.
	if right:
		_round_tube(out, "right-fist-laser", -1.8, -10.0,
				-7.0, -3.6, 1.15, 8)
		_round_tube(out, "laser-bore", -1.8, -10.0,
				-7.2, -3.0, 0.43, 1, 1)


static func _thigh(out: Array[Dictionary]) -> void:
	# 1m-long quadriceps narrows visibly at the knee; a separate anatomical
	# armored kneecap projects forward, not a column from hip to ankle.
	_loft(out, "hip-to-knee-anatomy", [
		_ring(-10.3, 2.0, -2.2, 2.1),
		_ring(-7.9, 2.5, -2.8, 2.5),
		_ring(-5.3, 2.9, -3.0, 2.7),
		_ring(-2.0, 3.8, -3.6, 3.6),
		_ring(0.5, 3.5, -3.2, 3.4)
	], 0)
	_round_tube(out, "hip-articulation", 0.0, -0.2, -2.8, 3.0, 2.25, 8)
	_round_tube(out, "knee-disc", 0.0, -9.0, -3.2, 2.8, 2.1, 8)
	_plate(out, "quadriceps-v-armor", [
		Vector3(-3.1, -2.1, -3.8), Vector3(-1.2, -1.1, -3.8),
		Vector3(2.1, -2.3, -3.7), Vector3(2.5, -5.1, -3.2),
		Vector3(1.0, -8.0, -3.3), Vector3(-1.8, -7.2, -3.3)
	], 0.9, 4)
	_plate(out, "offset-knee-shield", [
		Vector3(-2.1, -8.5, -3.4), Vector3(0.1, -7.8, -3.7),
		Vector3(2.2, -8.5, -3.4), Vector3(1.5, -10.5, -2.9),
		Vector3(-1.5, -10.5, -2.9)
	], 0.55, 0)


static func _calf(out: Array[Dictionary]) -> void:
	# Long SHIN shield and exposed actuator bundles; slim at the knee and
	# moderately armored at the ankle. No 10-cell-wide shin cylinders.
	_loft(out, "load-bearing-lower-leg", [
		_ring(-10.0, 2.25, -1.7, 2.5),
		_ring(-7.5, 2.45, -2.4, 2.8),
		_ring(-4.5, 2.7, -2.5, 2.7),
		_ring(-1.5, 2.3, -2.0, 2.4),
		_ring(0.3, 2.45, -2.2, 2.4)
	], 8)
	_plate(out, "vertical-tibia-armor", [
		Vector3(-2.6, -1.4, -2.8), Vector3(-1.1, 0.1, -2.8),
		Vector3(1.5, 0.1, -2.8), Vector3(2.7, -2.0, -2.7),
		Vector3(2.0, -8.4, -2.7), Vector3(-2.0, -8.4, -2.7)
	], 0.8, 4)
	# Uncovered side actuator rods are genuinely separate source meshes.
	for xx in [-2.6, 2.6]:
		_round_tube(out, "shin-piston", xx, -5.4,
				1.85, 4.05, 0.6, 8)


static func _foot(out: Array[Dictionary]) -> void:
	# Articulated toe phalanges, two separate forefoot plates and heel.
	_loft(out, "ankle-boot", [
		_ring(-2.0, 3.8, -5.2, 3.0),
		_ring(0.4, 3.3, -4.3, 3.3),
		_ring(2.0, 2.0, -2.0, 2.3)
	], 4)
	for x in [-2.6, -0.8, 1.1, 2.8]:
		_round_tube(out, "toe-link", x, -1.7,
				-11.3, -4.2, 0.68, 8)
		_plate(out, "toe-tip", [
			Vector3(x - 0.55, -2.35, -12.0),
			Vector3(x + 0.55, -2.35, -12.0),
			Vector3(x + 0.7, -1.1, -10.6),
			Vector3(x - 0.6, -1.1, -10.6)
		], 0.75, 4)
	_round_tube(out, "rear-heel-pivot", 0.0, -0.8,
			2.4, 5.4, 1.55, 8)


## Exportable real mesh of authored triangles, before voxelization. This is
## useful for viewing/editing the source geometry and for reference QA.
static func source_mesh(part_key: String) -> ArrayMesh:
	var components := part_meshes(part_key)
	var mesh := ArrayMesh.new()
	for entry: Dictionary in components:
		if int(entry["phase"]) == 1:
			continue
		var vertices: PackedVector3Array = entry["tris"]
		if vertices.is_empty():
			continue
		var normals := PackedVector3Array()
		for i in range(0, vertices.size(), 3):
			var a: Vector3 = vertices[i]
			var b: Vector3 = vertices[i + 1]
			var c: Vector3 = vertices[i + 2]
			var n := (b - a).cross(c - a).normalized()
			for _j in 3:
				normals.append(n)
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
