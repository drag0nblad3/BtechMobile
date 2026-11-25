extends TestCase
## Lightweight synthetic cache lifecycle checks; no catalog meshing needed.


func test_lru_eviction_preserves_live_models() -> void:
	VxRenderCache.clear()
	var first := VxModel.new()
	VxRenderCache._remember_model("first", first)
	for i in VxRenderCache.MAX_MODELS - 1:
		VxRenderCache._remember_model("entry_%d" % i, VxModel.new())
	check_eq(VxRenderCache.model_at("first"), first)
	VxRenderCache._remember_model("extra", VxModel.new())
	check_eq(VxRenderCache.stats()["models"], VxRenderCache.MAX_MODELS)
	check(VxRenderCache._models.has("first"), "recently accessed recipe stays")
	check(not VxRenderCache._models.has("entry_0"), "least recently used recipe is evicted")
	VxRenderCache.clear()
	check_eq(VxRenderCache.stats()["models"], 0)
	check_eq(first.cell_count(), 0, "a live reference survives eviction")


func test_cell_budget_evicts_recipe_and_geometry_together() -> void:
	VxRenderCache.clear()
	# Synthetic repeated part entries exercise the weight logic without
	# constructing or meshing hundreds of thousands of actual cells.
	var m := VxModel.new()
	var cells := {}
	for i in 1000:
		cells[Vector3i(i, 0, 0)] = 0
	for i in 250:
		m.parts.append({"cells": cells})
	VxRenderCache._remember_model("a", m)
	VxRenderCache.remember("a", {})
	VxRenderCache._remember_model("b", m)
	check(not VxRenderCache._models.has("a"))
	check(not VxRenderCache._geometry.has("a"))
	check(VxRenderCache.stats()["cells"] <= VxRenderCache.MAX_CELLS)
	VxRenderCache.clear()
