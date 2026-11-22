extends TestCase
## Name-blind multi-view guesses. Shape comparisons are orientation-aware
## and front-weighted; no model-specific silhouette coordinates are fixed.


func _cuboid(high: Vector3i) -> VxModel:
	var model := VxModel.new()
	var cells := {}
	for x in range(high.x + 1):
		for y in range(high.y + 1):
			for z in range(high.z + 1):
				cells[Vector3i(x, y, z)] = 0
	model.parts.append({"name": "ct", "loc": Location.CT,
		"parent": "", "pivot": Vector3.ZERO, "joint": "", "cells": cells})
	return model


func test_front_is_weighted_more_than_side() -> void:
	var reference := VxSilhouette.signature(_cuboid(Vector3i(3, 7, 3)))
	var front_same := VxSilhouette.signature(_cuboid(Vector3i(3, 7, 9)))
	var side_same := VxSilhouette.signature(_cuboid(Vector3i(9, 7, 3)))
	check_eq(reference["front"], front_same["front"],
		"depth changes must not change an orthographic front view")
	check_eq(reference["side"], side_same["side"],
		"width changes must not change an orthographic side view")
	check(VxSilhouette.similarity(reference, front_same) >
			VxSilhouette.similarity(reference, side_same),
		"front match must outweigh an equally informative side match")


func test_side_view_separates_front_silhouette_lookalikes() -> void:
	var a := VxSilhouette.signature(_cuboid(Vector3i(3, 7, 2)))
	var b := VxSilhouette.signature(_cuboid(Vector3i(3, 7, 11)))
	check_eq(a["front"], b["front"], "same front outline")
	check(a["side"] != b["side"], "side depth exposes the difference")
	check(VxSilhouette.similarity(a, b) < 1.0,
		"no perfect guess for two different 3D silhouettes")


func test_front_side_quarter_top_are_present() -> void:
	var m := _cuboid(Vector3i(4, 7, 2))
	var shape := VxSilhouette.signature(m)
	for view: String in VxSilhouette.VIEWS:
		check(shape.has(view) and not shape[view].is_empty(), "missing %s" % view)
	check(shape["front"] != shape["top"], "top and front must use different axes")


func test_name_blind_guess_excludes_source_model() -> void:
	var fingerprints := {
		"unknown_1": VxSilhouette.signature(_cuboid(Vector3i(3, 7, 3))),
		"unknown_2": VxSilhouette.signature(_cuboid(Vector3i(4, 7, 3))),
		"unknown_3": VxSilhouette.signature(_cuboid(Vector3i(9, 7, 3)))
	}
	var matches := VxSilhouette.closest("unknown_1", fingerprints, 2)
	check_eq(matches.size(), 2)
	check(matches[0]["id"] != "unknown_1", "must guess a different model")
	check(float(matches[0]["similarity"]) >= float(matches[1]["similarity"]),
		"top confusion candidates should be sorted by similarity")


func test_real_shape_profiles_have_all_required_angles() -> void:
	# The classes are tested against real sculpt data without baking in any
	# chassis-specific outline measurements, silhouettes, or coordinates.
	for id in ["atlas", "jenner", "wolverine"]:
		var m := VxModel.load_file("res://data/voxels/%s_shape.json" % id)
		var signature := VxSilhouette.signature(m)
		for view: String in VxSilhouette.VIEWS:
			check(signature[view].size() > 10, "%s %s outline too sparse" % [id, view])
