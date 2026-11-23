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


func test_hatchets_have_broad_blades_and_narrow_hafts() -> void:
	for id: String in IDS:
		var d: Dictionary = _recipe(id)
		var meta: Dictionary = d.get("melee_weapon", {})
		check_eq(meta.get("kind", ""), "hatchet", "%s: intended silhouette" % id)
		var p := VxModel.from_dict(d).part("ra_hatchet")
		if p.is_empty():
			continue
		var cells: Dictionary = p["cells"]
		var bottom := 100000
		var top := -100000
		for cell: Vector3i in cells:
			bottom = mini(bottom, cell.y)
			top = maxi(top, cell.y)
		var haft: Dictionary = {}
		var head: Dictionary = {}
		for cell: Vector3i in cells:
			if cell.y <= bottom + (top - bottom) / 3.0:
				haft[cell.x] = true
			if cell.y >= top - (top - bottom) / 3.0:
				head[cell.x] = true
		check(head.size() > haft.size() * 2,
				"%s: hatchet blade must be much wider than haft" % id)
		check(head.size() >= 7, "%s: head must survive small game-camera scale" % id)


func test_mounted_hatchet_arm_has_readable_ready_pose() -> void:
	for id: String in IDS:
		var m := _model(id)
		check(float(m.ready_arm.get("RA", 0.0)) > 0.2,
				"%s: weapon arm should have a readable guard pose" % id)
		check(not m.ready_arm.has("LA"), "%s: off-hand must stay free" % id)
		var mech := VxMech.new()
		mech.model = m
		mech.build()
		mech.anim._process(0.016)
		check(mech.shoulders[1].rotation.x > 0.2,
				"%s: actual rig must raise weapon arm" % id)
		mech.free()


static func _recipe(id: String) -> Dictionary:
	return JsonFile.read("res://data/voxels/%s_shape.json" % id)


static func _model(id: String) -> VxModel:
	return VxModel.from_dict(_recipe(id))
