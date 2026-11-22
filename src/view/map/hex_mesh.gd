class_name HexMesh
extends RefCounted
## Procedural hex meshes. Flat-topped: corners at 0, 60, ... degrees.


static func corners(radius: float) -> PackedVector3Array:
	var pts := PackedVector3Array()
	for i in 6:
		var a := deg_to_rad(60.0 * i)
		pts.append(Vector3(cos(a) * radius, 0.0, sin(a) * radius))
	return pts


## Prism with its top at y=0 and bottom at y=-1. Scale Y per instance.
static func prism(radius: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var c := corners(radius)
	var down := Vector3(0, -1, 0)
	for i in 6:
		var a := c[i]
		var b := c[(i + 1) % 6]
		_tri(st, Vector3.UP, Vector3.ZERO, b, a)
		var n := ((a + b) * 0.5).normalized()
		_tri(st, n, a, b, b + down)
		_tri(st, n, a, b + down, a + down)
	return st.commit()


## Flat hexagon at y=0 facing up (water surface, highlights).
static func cap(radius: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var c := corners(radius)
	for i in 6:
		_tri(st, Vector3.UP, Vector3.ZERO, c[(i + 1) % 6], c[i])
	return st.commit()


## A crisp hollow hex for friendly selection and hostile target markers.
## One six-sided ribbon, not a fill: doesn't hide terrain or movement ranges.
static func ring(radius: float, width: float) -> ArrayMesh:
	var outer := corners(radius)
	var inner := corners(maxf(0.01, radius - width))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 6:
		var j := (i + 1) % 6
		_tri(st, Vector3.UP, outer[i], outer[j], inner[j])
		_tri(st, Vector3.UP, outer[i], inner[j], inner[i])
	return st.commit()


## Vertices are emitted a, d, b so faces point along n (verified visually).
static func _tri(st: SurfaceTool, n: Vector3, a: Vector3, b: Vector3, d: Vector3) -> void:
	for v in [a, d, b]:
		st.set_normal(n)
		st.add_vertex(v)
