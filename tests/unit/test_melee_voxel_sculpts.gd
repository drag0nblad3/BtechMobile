extends TestCase
## Generalized silhouette, attached-grip, and pose checks for held hatchets.

const IDS := ["hatchetman", "axman", "nightsky", "scarabus"]


func test_melee_weapon_is_an_independent_supported_rig_component() -> void:
	for id: String in IDS:
		var m := _model(id)
		check(m.errors.is_empty(), "%s: %s" % [id, str(m.errors)])
		var part: Dictionary = m.part("ra_hatchet")
		check(not part.is_empty(), "%s: separate melee part missing" % id)
		if part.is_empty():
			continue
		check_eq(part["loc"], Location.RA, "%s: damage must follow right arm" % id)
		check_eq(part["parent"], "ra", "%s: melee part must follow weapon arm" % id)
		var groups := VxConnectivity.components(part["cells"])
		check_eq(groups.size(), 1, "%s: weapon shaft/blade contains floating pieces" % id)
		check(VxConnectivity.solid_contact(part["cells"], m.part("ra")["cells"]),
				"%s: shaft must have a backed 2x2 grip contact" % id)


func test_hatchets_have_broad_cutting_bits_and_narrow_hafts() -> void:
	for id: String in IDS:
		var d: Dictionary = _recipe(id)
		var meta: Dictionary = d.get("melee_weapon", {})
		check_eq(meta.get("kind", ""), "hatchet", "%s: intended silhouette" % id)
		var p := VxModel.from_dict(d).part("ra_hatchet")
		if p.is_empty():
			continue
		var rows: Dictionary = {}
		for cell: Vector3i in p["cells"]:
			if not rows.has(cell.y):
				rows[cell.y] = {}
			rows[cell.y][cell.x] = true
		var keys: Array = rows.keys()
		keys.sort()
		var low: int = keys[0]
		var high: int = keys.back()
		var shaft_width := 10000
		var blade_width := 0
		for y: int in keys:
			var width: int = rows[y].size()
			if float(y) <= float(low) + (high - low) * 0.30:
				shaft_width = mini(shaft_width, width)
			if float(y) >= float(low) + (high - low) * 0.50:
				blade_width = maxi(blade_width, width)
		check(blade_width >= shaft_width + 4,
				"%s: upper cutting bit must exceed narrow haft" % id)
		var blade_profiles := 0
		for part: Dictionary in d.get("parts", []):
			if part.get("name", "") != "ra_hatchet":
				continue
			for form: Dictionary in part.get("shapes", []):
				if form.has("loft") and form.get("mat", "") == "plate":
					var points: Array = form["loft"]["sections"][0]["polygon"]
					var bottom := INF
					var top := -INF
					for uv: Array in points:
						bottom = minf(bottom, float(uv[1]))
						top = maxf(top, float(uv[1]))
					if top - bottom >= 9.0:
						blade_profiles += 1
		check(blade_profiles > 0,
				"%s: blade should flare vertically, not become a hammer" % id)

func test_mounted_hatchet_arm_has_readable_ready_pose() -> void:
	for id: String in IDS:
		var m := _model(id)
		check(float(m.ready_arm.get("RA", 0.0)) > 0.2,
				"%s: weapon arm should have a readable guard pose" % id)
		check(not m.ready_arm.has("LA"), "%s: off-hand must stay free" % id)
		check(float(m.ready_roll.get("RA", 0.0)) > 0.1,
				"%s: axe should clear the torso in the front silhouette" % id)
		var mech := VxMech.new()
		mech.model = m
		mech.build()
		mech.anim._process(0.016)
		check(mech.shoulders[1].rotation.x > 0.2,
				"%s: actual rig must raise weapon arm" % id)
		check(mech.shoulders[1].rotation.z > 0.1,
				"%s: actual rig must present the head clear of the torso" % id)
		mech.free()


static func _recipe(id: String) -> Dictionary:
	return JsonFile.read("res://data/voxels/%s_shape.json" % id)


static func _model(id: String) -> VxModel:
	return VxModel.from_dict(_recipe(id))
