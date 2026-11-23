extends TestCase
## Reference-led source checks. Structural contact is validated by full catalog QA.

const CHASSIS := ["jenner_iic", "locust_iic", "mad_cat_mk_ii", "marauder_ii",
		"uziel", "shadow_hawk_iic", "sunder", "templar"]


func test_resculpted_eight_keep_equivalent_source_tiers_and_rigs() -> void:
	for id: String in CHASSIS:
		var low: Dictionary = JsonFile.read("res://data/voxels/%s_shape.json" % id)
		var high: Dictionary = JsonFile.read("res://data/voxels/%s.json" % id)
		check_eq(low.get("reference_sculpt_batch", ""),
				"distinctive-eight-20261123", id + " review lineage")
		check(not bool(low.get("reference_sculpt_approved", true)),
				id + " requires visual review")
		check_eq(low["unit"], high["unit"], id + " record sheet")
		check_eq(low["legs"], high["legs"], id + " gait")
		check_eq(low["muzzles"], high["muzzles"], id + " muzzle origins")
		check_eq(low["weapons"], high["weapons"], id + " equipped weapons")
		check_eq(low["parts"].size(), high["parts"].size(), id + " part count")
		for i in low["parts"].size():
			var a: Dictionary = low["parts"][i]
			var b: Dictionary = high["parts"][i]
			check_eq(a["name"], b["name"], id + " part identity")
			check_eq(a.get("parent", ""), b.get("parent", ""), id + " ancestry")
			check_eq(a.get("pivot", []), b.get("pivot", []), id + " pivot")
			check_eq(a.get("joint", ""), b.get("joint", ""), id + " joint")
			check_eq(a.get("shapes", []), b.get("shapes", []), id + " shape parity")


func test_reference_lofts_have_positive_area_and_increasing_sections() -> void:
	for id: String in CHASSIS:
		var recipe: Dictionary = JsonFile.read("res://data/voxels/%s_shape.json" % id)
		for part: Dictionary in recipe["parts"]:
			for s: Dictionary in part.get("shapes", []):
				if not s.has("loft"):
					continue
				var sections: Array = s["loft"]["sections"]
				for i in range(1, sections.size()):
					check(float(sections[i]["at"]) > float(sections[i - 1]["at"]),
							id + " ordered stations " + part["name"])
				for section: Dictionary in sections:
					var poly: Array = section["polygon"]
					var area := 0.0
					for i in poly.size():
						var a: Array = poly[i]
						var b: Array = poly[(i + 1) % poly.size()]
						area += float(a[0]) * float(b[1]) - float(b[0]) * float(a[1])
					check(absf(area) > 0.04, id + " real contour " + part["name"])


func test_signature_openings_and_gait_remain_distinctive() -> void:
	for id: String in ["jenner_iic", "locust_iic", "mad_cat_mk_ii"]:
		var d: Dictionary = JsonFile.read("res://data/voxels/%s_shape.json" % id)
		check_eq(d["legs"], "digitigrade", id + " reverse knee")
	var mad: Dictionary = JsonFile.read("res://data/voxels/mad_cat_mk_ii_shape.json")
	var ports := 0
	for p: Dictionary in mad["parts"]:
		if p["name"] in ["lt_weapon", "rt_weapon"]:
			for shape: Dictionary in p["shapes"]:
				if shape.has("erase"):
					ports += 1
	check(ports >= 12, "Mad Cat Mk II keeps twin physical missile racks")
