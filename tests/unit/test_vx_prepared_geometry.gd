extends TestCase
## Worker and normal paths produce the same geometry and paint metadata.


func test_prepared_arrays_match_synchronous_part() -> void:
	var m := VxModel.new()
	m.colors.append(Color.WHITE)
	m.roles.append("armor")
	var cells := {Vector3i.ZERO: 0, Vector3i.RIGHT: 0}
	var spec := {"name": "test", "loc": Location.CT, "pivot": Vector3.ZERO, "cells": cells}
	m.parts.append(spec)
	var p := VxPart.new()
	p.setup(spec, m)
	p.touching[Vector3i.LEFT] = true
	var data := VxPreparedGeometry.surface(cells, cells, p.touching, m.colors,
			VxPart.paint_mask(m), Vector3.ZERO, m.voxel_size)
	p.rebuild()
	check_eq(p.faces_before_merge, 10)
	check_eq(p.faces_before_merge, data["faces"])
	check_eq(p.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX], data["arrays"][Mesh.ARRAY_VERTEX])
	check_eq(p.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV2], data["arrays"][Mesh.ARRAY_TEX_UV2])
	p.free()
