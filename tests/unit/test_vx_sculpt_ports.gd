extends TestCase
## Require physically open missile muzzles and supported detail components at both sculpt tiers.

const DIRECTIONS: Array[Vector3i] = [
	Vector3i.LEFT, Vector3i.RIGHT, Vector3i.UP, Vector3i.DOWN,
	Vector3i.FORWARD, Vector3i.BACK
]

const RACKS := [
	{"chassis": "timber_wolf", "part": "lt_rack", "loc": Location.LT, "count": 20},
	{"chassis": "timber_wolf", "part": "rt_rack", "loc": Location.RT, "count": 20},
	{"chassis": "archer", "part": "lt_rack", "loc": Location.LT, "count": 20},
	{"chassis": "archer", "part": "rt_rack", "loc": Location.RT, "count": 20},
	{"chassis": "warhammer", "part": "rt_srm", "loc": Location.RT, "count": 6}
]

const DETAILS := [
	{"chassis": "warhammer", "part": "rt_srm"},
	{"chassis": "shadow_hawk", "part": "lt_jet_vane"},
	{"chassis": "shadow_hawk", "part": "rt_jet_vane"}
]


func _model(chassis: String, tier: String) -> VxModel:
	var data: Dictionary = VxRecipeStore.read("res://data/voxels/%s%s.json" % [chassis, tier])
	data["subdivide"] = 1
	return VxModel.from_dict(data)


func test_launcher_ports_are_open_and_separated_at_both_resolutions() -> void:
	for tier: String in ["", "_shape"]:
		for spec: Dictionary in RACKS:
			var model := _model(spec["chassis"], tier)
			check(model.errors.is_empty(), "bad recipe: %s%s %s" % [
				spec["chassis"], tier, model.errors])
			var part: Dictionary = model.part(spec["part"])
			check(not part.is_empty(), "missing launcher %s%s:%s" % [
				spec["chassis"], tier, spec["part"]])
			if part.is_empty():
				continue
			var cells: Dictionary = part["cells"]
			var ports: Array = model.muzzles.get(spec["loc"], [])
			check_eq(ports.size(), spec["count"], "missile count %s%s:%s" % [
				spec["chassis"], tier, spec["part"]])
			var unique := {}
			for pos: Vector3 in ports:
				var aperture := Vector3i(floori(pos.x), floori(pos.y), ceili(pos.z))
				unique[aperture] = true
				check(not cells.has(aperture), "blocked launcher mouth: %s %s" % [
					spec["chassis"], aperture])
				check(not cells.has(aperture + Vector3i(0, 0, 1)),
						"launcher needs bore depth: %s %s" % [spec["chassis"], aperture])
				var rim := false
				for step: Vector3i in [Vector3i.UP, Vector3i.RIGHT, Vector3i.LEFT]:
					if cells.has(aperture + step):
						rim = true
				check(rim, "port has no surrounding launcher wall: %s %s" % [
					spec["chassis"], aperture])
			check_eq(unique.size(), ports.size(), "muzzle points must be unique")


func test_new_accessories_have_broad_face_contacts_to_parent() -> void:
	for tier: String in ["", "_shape"]:
		for spec: Dictionary in DETAILS:
			var model := _model(spec["chassis"], tier)
			check(model.errors.is_empty(), "bad recipe: %s%s %s" % [
				spec["chassis"], tier, model.errors])
			var detail: Dictionary = model.part(spec["part"])
			check(not detail.is_empty(), "missing %s" % spec["part"])
			if detail.is_empty():
				continue
			var parent: Dictionary = model.part(detail.get("parent", ""))
			check(not parent.is_empty(), "detail without rig parent: %s" % spec["part"])
			if parent.is_empty():
				continue
			var patch := {}
			var backed := {}
			for cell: Vector3i in detail["cells"]:
				for step: Vector3i in DIRECTIONS:
					if parent["cells"].has(cell + step):
						patch[cell] = true
						if detail["cells"].has(cell - step):
							backed[cell] = true
						break
			check(patch.size() >= 4 and backed.size() >= 2,
					"weak unsupported accessory: %s%s:%s patch=%d backed=%d" % [
					spec["chassis"], tier, spec["part"], patch.size(), backed.size()])


func test_accessory_geometry_does_not_overlap_parent_in_authored_recipe() -> void:
	for tier: String in ["", "_shape"]:
		for spec: Dictionary in DETAILS:
			var data: Dictionary = VxRecipeStore.read("res://data/voxels/%s%s.json" % [
				spec["chassis"], tier])
			var raw := VxModel.new()
			for material: Dictionary in data.get("materials", []):
				raw._mat[material["name"]] = raw.colors.size()
				raw.colors.append(Color(material["color"]))
				raw.roles.append(material.get("role", "armor"))
			for part: Dictionary in data["parts"]:
				raw._add_part(part)
			check(raw.errors.is_empty(), "source geometry paint failed: %s%s" % [
				spec["chassis"], tier])
			var detail: Dictionary = raw.part(spec["part"])
			check(not detail.is_empty(), "missing raw accessory %s" % spec["part"])
			if detail.is_empty():
				continue
			var parent: Dictionary = raw.part(detail["parent"])
			check(not parent.is_empty(), "missing raw parent: %s" % spec["part"])
			if parent.is_empty():
				continue
			var common := 0
			for cell: Vector3i in detail["cells"]:
				if parent["cells"].has(cell):
					common += 1
			check_eq(common, 0, "source accessory intersects armor: %s%s/%s" % [
				spec["chassis"], tier, spec["part"]])
