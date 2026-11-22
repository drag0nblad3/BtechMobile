extends TestCase
## Tests topology, scale, motion boundaries and negative space, not coordinates
## from particular miniatures. Synthetic coordinates are fixture-relative.


func test_islands_reconnect_at_multiple_resolutions_and_origins() -> void:
	for scale in [1, 2, 3]:
		for translation: Vector3i in [Vector3i.ZERO, Vector3i(41, -25, 53)]:
			var m := _with_island(translation, scale)
			var initial: int = m.part("ct")["cells"].size()
			var report := VxIntegrity.repair(m)
			check_eq(int(report["before"]), 1, "synthetic model starts disconnected")
			check_eq(int(report["after"]), 0, "islands merge at each origin and grid pitch")
			check_eq(int(report["rejoined"]), 1)
			check_eq(m.part("ct")["cells"].size() - initial, int(report["added"]))
			check(int(report["added"]) <= VxIntegrity.GAP * scale,
					"join is a thin structural path, not an added slab")


func test_authored_void_cannot_be_filled_by_repair() -> void:
	var m := _with_island(Vector3i.ZERO, 1)
	var raw := {"parts": [{"name": "ct", "shapes": [
			{"erase": [[3, 0, 0], [4, 0, 0]]}]}]}
	var before: Dictionary = m.part("ct")["cells"].duplicate()
	var report := VxIntegrity.repair(m, raw)
	check_eq(report["rejoined"], 0)
	check_eq(report["after"], 1)
	check_eq(m.part("ct")["cells"], before, "keep an authored bore clear")


func test_repair_never_claims_cells_occupied_by_another_part() -> void:
	var m := _with_island(Vector3i.ZERO, 1)
	var occupied := {Vector3i(3, 0, 0): 0}
	m.parts.append({"name": "other", "loc": Location.LT, "parent": "",
			"joint": "", "pivot": Vector3.ZERO, "cells": occupied})
	var report := VxIntegrity.repair(m)
	check_eq(report["rejoined"], 0, "a separating moving part blocks the join")
	for p: Dictionary in m.parts:
		if p["name"] == "other":
			continue
		for cell: Vector3i in p["cells"]:
			check(not occupied.has(cell), "a voxel must have only one owner")


func test_muzzle_and_distant_modules_stay_open() -> void:
	var m := _with_island(Vector3i.ZERO, 1)
	m.muzzles[Location.CT] = [Vector3(3.5, 0.5, 0.5)]
	var report := VxIntegrity.repair(m)
	check_eq(report["rejoined"], 0, "avoid repairing across the shot corridor")
	m = _with_island(Vector3i.ZERO, 1)
	m.part("ct")["cells"].erase(Vector3i(5, 0, 0))
	m.part("ct")["cells"][Vector3i(30, 0, 0)] = 0
	report = VxIntegrity.repair(m)
	check_eq(report["rejoined"], 0, "distant islands require a new sculpt")
	check(report["after"] > 0, "unresolved islands must be reported")


func test_genuine_joint_contact_gets_a_short_structure_bridge() -> void:
	var m := _with_island(Vector3i.ZERO, 1)
	m.part("ct")["cells"].erase(Vector3i(5, 0, 0))
	m.parts.append({"name": "arm", "loc": Location.LA, "parent": "ct",
			"joint": "shoulder", "pivot": Vector3(4, 0, 0),
			"cells": {Vector3i(4, 0, 0): 0}})
	var report := VxIntegrity.repair(m)
	check_eq(report["joint_contacts"], 1)
	check(int(report["added"]) >= 1, "joint is bridged and its support collar is reinforced")
	check(not m.part("ct")["cells"].has(Vector3i(3, 0, 0)),
			"bridge belongs to articulated child, not torso")
	check(m.part("arm")["cells"].has(Vector3i(3, 0, 0)))


func test_nonjoint_cosmetic_detail_does_not_get_welded() -> void:
	var m := _with_island(Vector3i.ZERO, 1)
	m.part("ct")["cells"].erase(Vector3i(5, 0, 0))
	m.parts.append({"name": "detail", "loc": Location.CT, "parent": "ct",
			"joint": "", "pivot": Vector3(4, 0, 0),
			"cells": {Vector3i(4, 0, 0): 0}})
	var report := VxIntegrity.repair(m)
	check_eq(report["joint_contacts"], 0, "not every gap is a broken hinge")


func test_source_catalog_mirrors_and_lofts_are_well_formed() -> void:
	var visited := 0
	for f: String in DirAccess.get_files_at("res://data/voxels"):
		if not f.ends_with("_shape.json"):
			continue
		visited += 1
		var raw: Dictionary = JsonFile.read("res://data/voxels/" + f)
		var prior := {}
		for p: Dictionary in raw.get("parts", []):
			if p.has("mirror"):
				check(prior.has(p["mirror"]), "%s: mirror must follow its source" % f)
			var parent: String = p.get("parent", "")
			if not parent.is_empty():
				check(prior.has(parent), "%s: parent must precede child" % f)
			for shape: Dictionary in p.get("shapes", []):
				if not shape.has("loft"):
					continue
				var stations: Array = shape["loft"].get("sections", [])
				check(stations.size() >= 2, "%s: loft has >=2 stations" % f)
				for i in range(1, stations.size()):
					check(stations[i]["at"] > stations[i - 1]["at"],
							"%s: strictly ordered stations" % f)
					check(stations[i]["polygon"].size() == stations[i - 1]["polygon"].size(),
							"%s: matching contour vertices" % f)
			prior[p["name"]] = true
	check(visited > 100, "whole shape-source catalog scanned")


func _with_island(offset: Vector3i, n: int) -> VxModel:
	var m := VxModel.new()
	m.detail = n
	m._mat["frame"] = 0
	m.colors.append(Color.WHITE)
	m.roles.append("structure")
	var cells := {}
	for x in range(3 * n):
		for y in range(3 * n):
			for z in range(3 * n):
				cells[Vector3i(x, y, z) + offset] = 0
	for x in range(5 * n, 6 * n):
		for y in range(n):
			for z in range(n):
				cells[Vector3i(x, y, z) + offset] = 0
	m.parts.append({"name": "ct", "loc": Location.CT, "parent": "",
			"joint": "", "pivot": Vector3(offset), "cells": cells})
	return m

func test_short_gap_between_major_sections_gets_one_minimal_stitch() -> void:
	var m := _with_island(Vector3i.ZERO, 1)
	m.part("ct")["cells"].erase(Vector3i(5, 0, 0))
	# A broad neighboring component is not a tiny noise fragment.
	for y in range(3):
		for z in range(3):
			m.part("ct")["cells"][Vector3i(4, y, z)] = 0
	var report := VxIntegrity.repair(m)
	check_eq(report["rejoined"], 1)
	check_eq(report["added"], 1, "only the missing cell between plates is restored")
	check_eq(report["after"], 0)


func test_optical_details_are_not_welded_across_an_intentional_gap() -> void:
	var m := _with_island(Vector3i.ZERO, 1)
	m._mat["window"] = 1
	for c: Vector3i in m.part("ct")["cells"]:
		m.part("ct")["cells"][c] = 1
	var report := VxIntegrity.repair(m)
	check_eq(report["rejoined"], 0, "paired glass parts must remain separate")
	check_eq(report["after"], 1)


func test_boundary_search_handles_large_components_without_coordinate_pins() -> void:
	# A large solid component and a separate plate are one missing-cell
	# gap apart. The internal 7k+ voxels must not consume the search limit.
	for offset: Vector3i in [Vector3i.ZERO, Vector3i(-37, 22, 58)]:
		var block := {}
		var dims := Vector3i(10, 45, 16)
		for x in dims.x:
			for y in dims.y:
				for z in dims.z:
					block[offset + Vector3i(x, y, z)] = true
		var center := offset + Vector3i(dims.x + 1, dims.y / 2, dims.z / 2)
		var path := VxIntegrity._path(block.keys(), {center: true}, {}, [],
				{}, VxIntegrity.GAP)
		check_eq(path.size(), 1, "single-cell crack at any translation")
		if not path.is_empty():
			check(path[0] == center + Vector3i.LEFT,
					"bridge should be the immediate missing contact")


func test_rigid_assembly_repair_does_not_bridge_two_hinged_parts() -> void:
	var m := _with_island(Vector3i.ZERO, 1)
	m.part("ct")["cells"].erase(Vector3i(5, 0, 0))
	m.parts.append({"name": "separate_hip", "loc": Location.LL, "parent": "ct",
			"joint": "hip", "pivot": Vector3(4, 0, 0),
			"cells": {Vector3i(5, 0, 0): 0}})
	var count: int = m.part("ct")["cells"].size()
	var report := VxIntegrity.repair(m)
	check_eq(report["rig_rejoined"], 0, "each articulated hinge is a separate frame")
	check_eq(m.part("ct")["cells"].size(), count, "do not attach stray hip to torso")

func test_assembled_support_is_not_confused_with_per_rig_part_islands() -> void:
	var m := _with_island(Vector3i.ZERO, 1)
	# Detach this tiny synthetic cap, then give it a face-adjacent support
	# on an independently articulated limb. It is not unsupported globally.
	m.part("ct")["cells"].erase(Vector3i(5, 0, 0))
	m.parts.append({"name": "arm", "loc": Location.LA, "parent": "ct",
			"joint": "shoulder", "pivot": Vector3(4, 0, 0),
			"cells": {Vector3i(3, 0, 0): 0, Vector3i(4, 0, 0): 0}})
	check_eq(VxIntegrity.physical_components(m)["islands"], 0,
			"an assembled articulated neighbor can physically support a panel")


func test_unsupported_island_metric_catches_free_floating_piece() -> void:
	var m := _with_island(Vector3i.ZERO, 1)
	check_eq(VxIntegrity.physical_components(m)["islands"], 1,
			"disconnected volume is a real floating island")

func test_high_density_boundary_search_ignores_faraway_source_surface() -> void:
	# Large connected slab; the closest edge is deliberately inserted last.
	# Old breadth-first routing would exhaust its budget on the first 30k
	# source cells instead of reaching the near side of this assembly.
	var surface := {}
	for x in range(160):
		for y in range(160):
			for z in range(2):
				surface[Vector3i(x,y,z)] = true
	var target := {Vector3i(161,0,0): true}
	var route := VxIntegrity._path(surface.keys(), target, {}, [], {}, 3)
	check_eq(route.size(), 1, "one missing bridge cell even when source has 51k voxels")
	if not route.is_empty():
		check_eq(route[0], Vector3i(160,0,0))


func test_load_bearing_joint_requires_a_contiguous_patch_not_a_touch() -> void:
	for n in [1, 2, 3]:
		for offset: Vector3i in [Vector3i.ZERO, Vector3i(-31, 17, 52)]:
			var parent := {}
			for x in range(3 * n):
				for y in range(3 * n):
					for z in range(3 * n):
						parent[Vector3i(x,y,z) + offset] = 0
			var child := {Vector3i(3 * n, 0, 0) + offset: 0}
			var info := VxIntegrity._solid_contact(child, parent, n)
			check(not info["strong"], "single voxel contact cannot carry a structural joint")
			check_eq(info["patch"], 1, "measure connected face area, not voxel occupancy")
			for y in range(3 * n):
				for z in range(3 * n):
					child[Vector3i(3 * n,y,z) + offset] = 0
			info = VxIntegrity._solid_contact(child, parent, n)
			check(not info["strong"], "a broad one-layer veneer still lacks load-bearing depth")
			for x in range(3 * n + 1, 4 * n + 1):
				for y in range(3 * n):
					for z in range(3 * n):
						child[Vector3i(x,y,z) + offset] = 0
			info = VxIntegrity._solid_contact(child, parent, n)
			check(info["strong"], "broad multi-layer socket survives resolution shifts")
			check(info["patch"] >= info["needed"] and info["backed_patch"] >= info["depth_needed"], "mass interface has area and actual depth")


func test_scattered_contacts_are_not_equivalent_to_one_connected_mass() -> void:
	var parent := {}
	var child := {}
	for k in range(6):
		var offset := Vector3i(0, k * 5, 0)
		parent[offset] = 0
		child[offset + Vector3i.RIGHT] = 0
	var info := VxIntegrity._solid_contact(child, parent)
	check_eq(info["patch"], 1, "individual distant face touches cannot add up into a joint")
	check(not info["strong"], "minimum patch is contiguous not total touching faces")


func test_reinforcement_preserves_authored_negative_spaces() -> void:
	var parent := {}
	for y in range(4):
		for z in range(4):
			for x in range(3):
				parent[Vector3i(x,y,z)] = 0
	var arm := {Vector3i(3,1,1): 0}
	var m := VxModel.new()
	m._mat["frame"] = 0
	m.colors.append(Color.WHITE)
	m.roles.append("structure")
	m.parts.append({"name": "ct", "loc": Location.CT, "parent": "",
			"joint": "", "pivot": Vector3.ZERO, "cells": parent})
	m.parts.append({"name": "arm", "loc": Location.LA, "parent": "ct",
			"joint": "shoulder", "pivot": Vector3(3,1,1), "cells": arm})
	var raw := {"parts": [{"name": "arm", "shapes": [
			{"erase": [[3,0,1], [3,0,1]]}]}]}
	var report := VxIntegrity.repair(m, raw)
	check(not m.part("arm")["cells"].has(Vector3i(3,0,1)),
			"no collision with explicitly carved geometry")
	check(int(report["mass_reinforced"]) > 0, "joint grows a multi-face socket")
	check(VxIntegrity._solid_contact(arm, parent)["strong"],
			"reinforcement builds continuous contact mass")
