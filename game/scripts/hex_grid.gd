extends RefCounted
## Flat-top hex grid helpers. Axial coordinates (q, r) are stored in a Vector2i.
## World north is -Z, so hex facing 0 points at -Z and facings advance
## clockwise in 60-degree steps when seen from above.

const SQRT3 := 1.7320508075688772


static func axial_to_world(hex: Vector2i, radius: float) -> Vector3:
	var x := radius * 1.5 * hex.x
	var z := radius * SQRT3 * (hex.y + hex.x * 0.5)
	return Vector3(x, 0.0, z)


static func hexes_in_range(grid_radius: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for q in range(-grid_radius, grid_radius + 1):
		var r_min := maxi(-grid_radius, -q - grid_radius)
		var r_max := mini(grid_radius, -q + grid_radius)
		for r in range(r_min, r_max + 1):
			result.append(Vector2i(q, r))
	return result


## Builds one mesh for the whole board. Each tile is inset slightly so the
## dark ground underneath shows through as grid lines.
static func build_mesh(grid_radius: int, hex_radius: float, inset: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tile_radius := hex_radius - inset
	for hex in hexes_in_range(grid_radius):
		var center := axial_to_world(hex, hex_radius)
		var shade := 0.30 + 0.04 * float(posmod(hex.x * 7 + hex.y * 3, 3))
		var color := Color(shade * 0.85, shade, shade * 0.72)
		for i in 6:
			var a0 := deg_to_rad(60.0 * i)
			var a1 := deg_to_rad(60.0 * (i + 1))
			var corners: Array[Vector3] = [
				center,
				center + Vector3(cos(a0), 0.0, sin(a0)) * tile_radius,
				center + Vector3(cos(a1), 0.0, sin(a1)) * tile_radius,
			]
			for corner in corners:
				st.set_color(color)
				st.set_normal(Vector3.UP)
				st.add_vertex(corner)
	return st.commit()
