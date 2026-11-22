class_name VoxelAsset
extends RefCounted
## Voxel visuals for Battlefield Support Assets. This code never mutates
## AssetCard, the combat Unit, or the official damage state.
## All asset recipes, including whole infantry squads, have a 50k voxel cap.

const MAX_VOXELS := 50000
const DIR := "res://data/voxels/assets/"

static func recipe_for(def: UnitDef) -> String:
	if def.asset == null:
		return ""
	if def.id == "savior_repair_vehicle":
		return "savior_repair_vehicle"
	var c: AssetCard = def.asset
	if c.kind == AssetCard.BATTLE_ARMOR:
		return "battle_armor_elementals"
	if c.kind == AssetCard.INFANTRY:
		if c.mechanized or c.motive == "w":
			return "infantry_motorized"
		return "infantry_jump" if c.motive == "j" else "infantry_rifles"
	if c.kind == AssetCard.EMPLACEMENT:
		return "missile_emplacement" if c.has("IF") else "field_emplacement"
	if c.kind == AssetCard.VTOL:
		return "transport_vtol" if c.has("APC") else "attack_vtol"
	match c.motive:
		"h":
			return "hover_scout" if c.has("NOTUR") else "hover_tank"
		"w":
			return "wheeled_apc" if c.has("APC") else "wheeled_supply_truck"
		"t":
			return "lrm_carrier" if c.has("IF") else "tracked_tank"
	return ""


## Asset models intentionally do NOT use the eight-location Mech validator.
## The model painter / mesher is shared, while gameplay hit locations aren't.
static func model_from_dict(data: Dictionary) -> VxModel:
	var recipe: Dictionary = VxArtQuality.apply_asset(data)
	var m := VxModel.new()
	if int(recipe.get("voxel_cap", MAX_VOXELS)) > MAX_VOXELS:
		m.errors.append("declared asset cap exceeds 50000")
		return m
	m.voxel_size = float(recipe.get("voxel_size", 0.028))
	for material: Dictionary in recipe.get("materials", []):
		m._mat[material["name"]] = m.colors.size()
		m.colors.append(Color(material["color"]))
		m.roles.append(material.get("role", "armor"))
	for p: Dictionary in recipe.get("parts", []):
		m._add_part(p)
	VxRefine.apply(m, int(recipe.get("subdivide", 1)))
	for p: Dictionary in recipe.get("parts", []):
		m._paint(m.part(p["name"]).get("cells", {}), p.get("detail", []))
	if bool(recipe.get("exclusive_parts", false)):
		m._claim_exclusive_cells()
	if m.cell_count() > MAX_VOXELS:
		m.errors.append("asset exceeds 50000 voxels (%d)" % m.cell_count())
	return m


static func build(def: UnitDef, side: int) -> Node3D:
	var id := recipe_for(def)
	if id == "":
		return null
	return _build_file(DIR + id + ".json", side)


## Official combat-vehicle record sheet. The renderer does not touch combat data.
static func build_record_vehicle(def: UnitDef, side: int) -> Node3D:
	if def.vehicle == null:
		return null
	return _build_file("res://data/voxels/vehicles/" + def.id + ".json", side)


## Official Elemental and Inner Sphere battle armor squads.
static func build_record_squad(def: UnitDef, side: int) -> Node3D:
	if def.battle_armor == null:
		return null
	return _build_file("res://data/voxels/battle_armor/" + def.id + ".json", side)


static func _build_file(path: String, side: int) -> Node3D:
	if not FileAccess.file_exists(path):
		return null
	var id := path.get_file().get_basename()
	var data: Variant = JsonFile.read(path)
	if not data is Dictionary:
		return null
	var model := model_from_dict(data)
	if not model.errors.is_empty() or model.cell_count() > MAX_VOXELS:
		push_warning("VoxelAsset %s: %s" % [id, model.errors])
		return null  # Keep existing placeholder rather than display an invalid mesh.
	var color: Color = PlaceholderMech.SIDE_COLORS[side % PlaceholderMech.SIDE_COLORS.size()]
	for i in model.colors.size():
		if model.roles[i] == "armor":
			model.colors[i] = model.colors[i].lerp(color, 0.18)
	var root := Node3D.new()
	root.name = "VoxelAsset_" + id
	var meshes := {}
	var owner := {}
	for spec: Dictionary in model.parts:
		var part := VxPart.new()
		part.setup(spec, model)
		root.add_child(part)
		meshes[part.part_name] = part
		for c: Vector3i in spec["cells"]:
			owner[c] = spec["name"]
	for part: VxPart in meshes.values():
		for c: Vector3i in part.original:
			for delta: Vector3i in VxPart.DIRS:
				var other: String = owner.get(c + delta, part.part_name)
				if other != part.part_name:
					part.touching[c + delta] = true
		part.rebuild()
	return root
