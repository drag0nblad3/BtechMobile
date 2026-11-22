extends TestCase
## Shared-grid connectivity: a touching voxel, diagonal contact or a
## paper-thin 2x2 face is not a structurally supported articulated joint.


func _box(a: Vector3i, b: Vector3i) -> Dictionary:
	var out := {}
	for x in range(a.x, b.x + 1):
		for y in range(a.y, b.y + 1):
			for z in range(a.z, b.z + 1):
				out[Vector3i(x, y, z)] = 0
	return out


func _model(first: Dictionary, second: Dictionary = {},
		pivot: Vector3 = Vector3(5, 2, 2)) -> VxModel:
	var model := VxModel.new()
	model.parts.append({"name": "ct", "parent": "", "loc": Location.CT,
		"joint": "", "pivot": Vector3.ZERO, "cells": first})
	if not second.is_empty():
		model.parts.append({"name": "la", "parent": "ct", "loc": Location.LA,
			"joint": "shoulder", "pivot": pivot, "cells": second})
	return model


func test_solid_contact_requires_face_patch_and_backing() -> void:
	var torso := _box(Vector3i(0, 0, 0), Vector3i(3, 3, 3))
	var solid_arm := _box(Vector3i(4, 0, 0), Vector3i(6, 3, 3))
	var thin_arm := _box(Vector3i(4, 0, 0), Vector3i(4, 3, 3))
	var diagonal := _box(Vector3i(4, 4, 0), Vector3i(6, 6, 3))
	check(VxConnectivity.solid_contact(solid_arm, torso), "backed 2x2 patch should pass")
	check(not VxConnectivity.solid_contact(thin_arm, torso),
		"face contact without depth must fail")
	check(not VxConnectivity.solid_contact(diagonal, torso),
		"diagonal corner contact must fail")


func test_local_joint_gap_gets_supported_socket() -> void:
	var torso := _box(Vector3i(0, 0, 0), Vector3i(3, 3, 3))
	var arm := _box(Vector3i(6, 0, 0), Vector3i(9, 3, 3))
	var m := _model(torso, arm)
	check(not VxConnectivity.solid_contact(m.part("la")["cells"], m.part("ct")["cells"]))
	var report := VxConnectivity.repair(m)
	check_eq(report["joints_fixed"], 1)
	check(VxConnectivity.solid_contact(m.part("la")["cells"], m.part("ct")["cells"]),
		"socket must have 2x2 face and backing on both sides")
	check(VxConnectivity.audit(m)["pass"], "joint should pass topology audit")


func test_floating_local_island_is_bridged_without_erasing_it() -> void:
	var mass := _box(Vector3i(0, 0, 0), Vector3i(3, 3, 3))
	var island := _box(Vector3i(6, 0, 0), Vector3i(8, 3, 3))
	for c: Vector3i in island:
		mass[c] = island[c]
	var m := _model(mass)
	check_eq(VxConnectivity.components(m.part("ct")["cells"]).size(), 2)
	var original: int = m.cell_count()
	var report := VxConnectivity.repair(m)
	check_eq(report["islands_fixed"], 1)
	check_eq(VxConnectivity.components(m.part("ct")["cells"]).size(), 1)
	check(m.cell_count() > original, "weld should add occupied material, not remove the island")


func test_distant_island_stays_auditable_instead_of_sprouting_long_strut() -> void:
	var mass := _box(Vector3i(0, 0, 0), Vector3i(3, 3, 3))
	var island := _box(Vector3i(40, 0, 0), Vector3i(43, 3, 3))
	for c: Vector3i in island:
		mass[c] = island[c]
	var m := _model(mass)
	var old: int = m.cell_count()
	var report := VxConnectivity.repair(m)
	check_eq(report["islands_fixed"], 0)
	check_eq(m.cell_count(), old)
	check(not VxConnectivity.audit(m)["pass"], "unresolved geometry must be reported")


func test_parent_attachment_is_independent_of_pivot_coordinates() -> void:
	var torso := _box(Vector3i(0, 0, 0), Vector3i(3, 3, 3))
	var arm := _box(Vector3i(4, 0, 0), Vector3i(6, 3, 3))
	var m := _model(torso, arm, Vector3(999, 999, 999))
	check(VxConnectivity.audit(m)["pass"],
		"actual mass connectivity should pass even if a joint pivot is misplaced")
