extends TestCase
## Source-only geometry and rig parity for the fourteen reference sculpt edits.

const CHASSIS := [
	"jinggau", "kingfisher", "peacekeeper", "raptor", "rattlesnake_ii",
	"rattlesnake", "shiro", "stealth", "tempest", "thunder",
	"thunderbolt_iic", "tian_zong", "tiburon", "toro",
]


func test_reference_fourteen_preserve_source_tiers_and_rig_ancestry() -> void:
	for id: String in CHASSIS:
		var low: Dictionary = JsonFile.read("res://data/voxels/%s_shape.json" % id)
		var high: Dictionary = JsonFile.read("res://data/voxels/%s.json" % id)
		check_eq(low.get("reference_sculpt_batch", ""), "remaining-fourteen-reference-20261123",
				id + " review lineage")
		check(not bool(low.get("reference_sculpt_approved", true)), id + " visual sign-off pending")
		check_eq(low["unit"], high["unit"], id + " unit design")
		check_eq(low["legs"], high["legs"], id + " leg type")
		check_eq(low["muzzles"], high["muzzles"], id + " muzzle origins")
		check_eq(low["weapons"], high["weapons"], id + " loadout")
		check_eq(low["parts"].size(), high["parts"].size(), id + " rig part count")
		for i in low["parts"].size():
			var a: Dictionary = low["parts"][i]
			var b: Dictionary = high["parts"][i]
			check_eq(a["name"], b["name"], id + " component")
			check_eq(a.get("parent", ""), b.get("parent", ""), id + " parent")
			check_eq(a.get("joint", ""), b.get("joint", ""), id + " joint")
			check_eq(a.get("pivot", []), b.get("pivot", []), id + " pivot")
			check_eq(a.get("shapes", []), b.get("shapes", []), id + " source geometry")


func test_reference_fourteen_contours_are_noncollapsed_and_monotone() -> void:
	for id: String in CHASSIS:
		var raw: Dictionary = JsonFile.read("res://data/voxels/%s_shape.json" % id)
		for p: Dictionary in raw["parts"]:
			for s: Dictionary in p.get("shapes", []):
				if not s.has("loft"):
					continue
				var sections: Array = s["loft"]["sections"]
				for i in range(1, sections.size()):
					check(float(sections[i]["at"]) > float(sections[i-1]["at"]),
							id + " ordered loft stations in " + p["name"])
				for sec: Dictionary in sections:
					var polygon: Array = sec["polygon"]
					var area := 0.0
					for i in polygon.size():
						var a: Array = polygon[i]
						var b: Array = polygon[(i + 1) % polygon.size()]
						area += float(a[0]) * float(b[1]) - float(a[1]) * float(b[0])
					check(absf(area) > 0.04, id + " nondegenerate loft " + p["name"])


func test_original_and_successor_rattlesnake_gaits_differ() -> void:
	var original: Dictionary = JsonFile.read("res://data/voxels/rattlesnake_shape.json")
	var successor: Dictionary = JsonFile.read("res://data/voxels/rattlesnake_ii_shape.json")
	check_eq(original["legs"], "digitigrade")
	check_eq(successor["legs"], "plantigrade")


func test_shiro_sword_and_pennant_attachments_exist() -> void:
	var shiro: Dictionary = JsonFile.read("res://data/voxels/shiro_shape.json")
	var found_sword := false
	var fin_count := 0
	for p: Dictionary in shiro["parts"]:
		if p["name"] == "ra_sword":
			found_sword = true
		if p["name"] in ["lt", "rt"]:
			for shape: Dictionary in p["shapes"]:
				if shape.has("loft") and shape["loft"]["sections"].size() == 3:
					fin_count += 1
	check(found_sword, "Shiro retains its distinct articulated sword")
	check(fin_count >= 2, "Shiro's two narrow shoulder banners retain profiles")
