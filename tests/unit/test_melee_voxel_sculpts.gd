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


func test_forward_blade_is_thin_not_a_side_facing_slab() -> void:
	for id: String in IDS:
		var d: Dictionary = _recipe(id)
		var meta: Dictionary = d.get("melee_weapon", {})
		check_eq(meta.get("blade_axis", ""), "-z", "%s: cutting bit must face -z" % id)
		var p: Dictionary = VxModel.from_dict(d).part("ra_hatchet")
		if p.is_empty():
			continue
		var low := Vector3i(999, 999, 999)
		var high := Vector3i(-999, -999, -999)
		for c: Vector3i in p["cells"]:
			low.x = mini(low.x, c.x)
			low.y = mini(low.y, c.y)
			low.z = mini(low.z, c.z)
			high.x = maxi(high.x, c.x)
			high.y = maxi(high.y, c.y)
			high.z = maxi(high.z, c.z)
		var sideways: int = high.x - low.x + 1
		var forward: int = high.z - low.z + 1
		check(forward >= 9 and forward >= sideways * 2,
				"%s: head must project forward of grip" % id)
		check(sideways <= 5, "%s: blade too thick laterally" % id)
		var cutting_loft := false
		for item: Dictionary in d.get("parts", []):
			if item.get("name", "") != "ra_hatchet":
				continue
			for shape: Dictionary in item.get("shapes", []):
				if shape.get("mat", "") != "steel_edge" or not shape.has("loft"):
					continue
				cutting_loft = shape["loft"].get("axis", "") == "z"
		check(cutting_loft, "%s: needs a real forward cutting edge" % id)


func test_cutting_wedge_tapers_to_a_high_contrast_steel_edge() -> void:
	for id: String in IDS:
		var d: Dictionary = _recipe(id)
		var steel := Color.BLACK
		var bright := Color.BLACK
		for material: Dictionary in d.get("materials", []):
			if material.get("name", "") == "steel":
				steel = Color(material["color"])
			elif material.get("name", "") == "steel_edge":
				bright = Color(material["color"])
		check(bright.get_luminance() > steel.get_luminance() * 1.35,
				"%s: cutting edge must stand out from the blade" % id)
		var cutting: Dictionary = {}
		for part: Dictionary in d.get("parts", []):
			if part.get("name", "") != "ra_hatchet":
				continue
			for shape: Dictionary in part.get("shapes", []):
				if shape.get("mat", "") == "steel_edge":
					cutting = shape
		check(cutting.has("loft"), "%s: edge needs tapered geometry" % id)
		if not cutting.has("loft"):
			continue
		var sections: Array = cutting["loft"]["sections"]
		check(sections.size() >= 3, "%s: edge should taper through three profiles" % id)
		var edge_height: float = _vertical_span(sections[0]["polygon"])
		var body_height: float = _vertical_span(sections.back()["polygon"])
		var edge_thickness: float = _horizontal_span(sections[0]["polygon"])
		var body_thickness: float = _horizontal_span(sections.back()["polygon"])
		check(edge_height >= body_height * 0.6,
				"%s: axe needs a long cutting edge, not a mace point" % id)
		check(edge_thickness < body_thickness * 0.6,
				"%s: edge must be tapered thin across X" % id)
		check(VxPart._is_unpainted("steel_edge"),
				"%s: team paint must not recolor the metal edge" % id)


static func _vertical_span(polygon: Array) -> float:
	var low := INF
	var high := -INF
	for uv: Array in polygon:
		low = minf(low, float(uv[1]))
		high = maxf(high, float(uv[1]))
	return high - low

static func _horizontal_span(polygon: Array) -> float:
	var low := INF
	var high := -INF
	for uv: Array in polygon:
		low = minf(low, float(uv[0]))
		high = maxf(high, float(uv[0]))
	return high - low



func test_mounted_hatchet_arm_has_readable_ready_pose() -> void:
	for id: String in IDS:
		var m := _model(id)
		check(absf(float(m.ready_arm.get("RA", 0.0))) < 0.01,
				"%s: blade should point forward without pitching the whole arm" % id)
		check(not m.ready_arm.has("LA"), "%s: off-hand must stay free" % id)
		check(absf(float(m.ready_roll.get("RA", 0.0))) < 0.01,
				"%s: axe should clear the torso in the front silhouette" % id)
		var mech := VxMech.new()
		mech.model = m
		mech.build()
		mech.anim._process(0.016)
		check(absf(mech.shoulders[1].rotation.x) < 0.01,
				"%s: actual rig must raise weapon arm" % id)
		check(absf(mech.shoulders[1].rotation.z) < 0.01,
				"%s: actual rig must present the head clear of the torso" % id)
		mech.free()


static func _recipe(id: String) -> Dictionary:
	return JsonFile.read("res://data/voxels/%s_shape.json" % id)


static func _model(id: String) -> VxModel:
	return VxModel.from_dict(_recipe(id))
