extends TestCase
## Guard the per-part audit itself, including face-touch vs diagonal-touch.
func test_per_part_auditor_catches_islands_and_missing_parent_contacts() -> void:
	var model := VxModel.new()
	model.id = "synthetic_connectivity"
	model.parts = [
		{"name": "hull", "parent": "", "pivot": Vector3.ZERO,
		 "cells": {Vector3i(0, 0, 0): 0, Vector3i(0, 1, 0): 0}},
		{"name": "connected", "parent": "hull", "pivot": Vector3.ZERO,
		 "cells": {Vector3i(1, 0, 0): 0, Vector3i(2, 0, 0): 0}},
		{"name": "isolated", "parent": "hull", "pivot": Vector3.ZERO,
		 "cells": {Vector3i(9, 0, 0): 0, Vector3i(9, 1, 0): 0,
		  Vector3i(15, 1, 0): 0}}
	]
	var record := VxPartConnectivity.audit(model)
	check_eq(record["part_count"], 3)
	check_eq(record["loose_islands"], 1)
	check_eq(record["parent_gaps"], 1)
	check_eq(record["parts"][1]["parent_contacts"], 1)
	check_eq(record["parts"][2]["island_sizes"], [2, 1])


func test_audit_actual_mech_parts_not_just_global_occupancy() -> void:
	for chassis in ["raven", "shadow_cat", "king_crab", "marauder", "timber_wolf"]:
		var path := "res://data/voxels/%s_shape.json" % chassis
		var data: Dictionary = JsonFile.read(path)
		var model := VxModel.from_dict(data)
		var result := VxPartConnectivity.audit(model)
		check_eq(result["part_count"], model.parts.size(),
			"Part-by-part coverage: " + chassis)
		for item: Dictionary in result["parts"]:
			check(item.has("island_sizes") and item.has("parent_contacts"),
				"Audit data missing: " + chassis + " " + item["name"])
