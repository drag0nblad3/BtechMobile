extends TestCase
## Geometry-only study. No voxel density or damage quality assertions.

const MODELS := [
	"res://data/voxels/atlas_shape.json",
	"res://data/voxels/wolverine_shape.json",
	"res://data/voxels/jenner_shape.json",
]


func test_independent_component_shapes_use_only_authored_profiles() -> void:
	for path: String in MODELS:
		var d: Dictionary = JsonFile.read(path)
		check_eq(d.get("subdivide", -1), 1, "no subdivision permitted in the shape gate")
		var polygons := 0
		for part: Dictionary in d.get("parts", []):
			for op: Dictionary in part.get("shapes", []):
				if op.has("loft"):
					polygons += 1
					check(op["loft"]["sections"].size() >= 2, "loft must have multiple profiles")
		check(polygons >= 12, "expected authored contours: %s" % path)
		var m := VxModel.from_dict(d)
		check(m.errors.is_empty(), "invalid shape study %s: %s" % [path, m.errors])
		check(m.cell_count() > 1200 and m.cell_count() < 22000,
				"shape-only count unexpected %s %d" % [m.id, m.cell_count()])
		for loc in Location.COUNT:
			check(not m.parts_at(loc).is_empty(), "%s missing %s" % [m.id, Location.code(loc)])


func test_loft_rasterization_changes_cross_section() -> void:
	var d := {
		"materials": [{"name": "form", "color": "b5b9bc", "role": "armor"}],
		"parts": [{"name":"ct", "loc":"CT", "shapes":[
			{"loft":{"axis":"y","sections":[
				{"at":0,"polygon":[[-1,-1],[1,-1],[1,1],[-1,1]]},
				{"at":4,"polygon":[[-4,-2],[4,-2],[4,2],[-4,2]]}
			]},"mat":"form"}]}]
	}
	var model := VxModel.from_dict(d)
	check(model.part("ct")["cells"].has(Vector3i(0,0,0)), "loft base missing")
	check(model.part("ct")["cells"].has(Vector3i(3,4,0)), "loft upper expansion missing")
	check(not model.part("ct")["cells"].has(Vector3i(3,0,0)),
			"loft should be tapered, not a box")
