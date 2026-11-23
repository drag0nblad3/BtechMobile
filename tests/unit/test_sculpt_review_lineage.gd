extends TestCase
## Guard 100-pass review lineage and strictly ordered loft stations.
## Checks both editable source shapes and their high-detail counterparts.

const REPAIRED := [
	"akuma", "assassin", "grasshopper", "hatamoto_chi", "hellspawn",
	"kintaro", "quickdraw", "spartan", "victor", "whitworth",
]


func test_repaired_sculpts_keep_review_history_and_ordered_stations() -> void:
	for chassis: String in REPAIRED:
		for suffix: String in ["_shape", ""]:
			var path := "res://data/voxels/%s%s.json" % [chassis, suffix]
			var file := FileAccess.open(path, FileAccess.READ)
			check(file != null, "Missing voxel recipe: " + path)
			if file == null:
				continue
			var data: Variant = JSON.parse_string(file.get_as_text())
			check(data is Dictionary, "Invalid JSON recipe: " + path)
			if not data is Dictionary:
				continue
			var recipe: Dictionary = data
			check(int(recipe.get("art_quality_passes", 0)) >= 100,
					"Lost sculpt review passes: " + path)
			for part: Dictionary in recipe.get("parts", []):
				for shape: Dictionary in part.get("shapes", []):
					if not shape.has("loft"):
						continue
					var sections: Array = shape["loft"].get("sections", [])
					for i in range(1, sections.size()):
						check(float(sections[i]["at"]) > float(sections[i - 1]["at"]),
								"Out-of-order loft station: %s (%s)" % [path, part.get("name", "")])
