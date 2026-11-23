extends TestCase
## Faction paint is cosmetic: shared materials, intact geometry and damage.


func test_faction_palettes_are_data_driven() -> void:
	var suns := VxLivery.scheme("federated_suns")
	var wolf := VxLivery.scheme("clan_wolf")
	check(suns.has("primary") and suns.has("badge"), "Suns palette and field badge")
	check(wolf.has("primary") and wolf.has("badge"), "Wolf palette and field badge")
	check(suns["primary"] != wolf["primary"], "factions have distinct armor colors")
	check_eq(VxLivery.scheme("ilclan_wolf"), wolf, "era successor shares Wolf livery")


func test_unlisted_factions_get_stable_colors() -> void:
	var a := VxLivery.scheme("clan_coyote")
	var b := VxLivery.scheme("clan_coyote")
	check_eq(a, b, "a fallback is deterministic")
	check(a.has("primary") and a.has("secondary"), "unlisted Clan still has paint")
	check(VxLivery.scheme("duchy_of_andurien").has("badge"), "unlisted IS receives a badge")


func test_paint_materials_are_shared_per_team() -> void:
	var a := VxLivery.material_for("clan_wolf", 1)
	var b := VxLivery.material_for("clan_wolf", 1)
	var c := VxLivery.material_for("federated_suns", 0)
	check(a == b, "same team reuses one shader material")
	check(a != c, "enemy paint does not reuse our palette")
	check(a.shader != null, "shader is present")


func test_mesher_keeps_structure_unpainted() -> void:
	var m := VxModel.new()
	m.colors = PackedColorArray([Color.WHITE, Color(0.2, 0.2, 0.2)])
	m.roles = ["armor", "structure"]
	var part := VxPart.new()
	part.setup({"name": "ct", "loc": Location.CT, "pivot": Vector3.ZERO,
			"cells": {Vector3i.ZERO: 0, Vector3i.RIGHT: 1}}, m)
	part.rebuild()
	check(part.mesh != null, "two-material part has a mesh")
	var surfaces := part.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = surfaces[Mesh.ARRAY_VERTEX]
	var roles: PackedVector2Array = surfaces[Mesh.ARRAY_TEX_UV2]
	check_eq(roles.size(), verts.size(), "per-face role stream matches vertices")
	var armor_faces := 0
	var frame_faces := 0
	for role: Vector2 in roles:
		if role.x > 0.5:
			armor_faces += 1
		else:
			frame_faces += 1
	check(armor_faces > 0 and frame_faces > 0, "armor and structure both survive meshing")
	part.free()


func test_livery_survives_damage_and_wreck_recovery() -> void:
	var mech := VxMech.from_file("res://data/voxels/hunchback.json")
	mech.set_faction("federated_suns")
	var ct: VxPart = mech.part_at(Location.CT)
	var coat := ct.material_override
	var full := mech.voxel_count()
	var u := Unit.new(1, designs().get_def("hunchback_hbk4g"), 0, Vector2i.ZERO, 0)
	Damage.apply(u, Location.CT, 13)
	mech.show_unit(u)
	check(mech.voxel_count() < full, "damage still removes real mesh cells")
	check(ct.material_override == coat, "damage doesn't strip the paint shader")
	mech.set_wrecked(true)
	check(ct.material_override != coat, "wreck gets darkened")
	mech.set_wrecked(false)
	check(ct.material_override == coat, "undamaged paint can be restored")
	mech.free()


func test_faction_setting_selects_paint_for_side() -> void:
	var old := GameSettings.paint_factions[0]
	GameSettings.paint_factions[0] = "clan_jade_falcon"
	var mech := VxMech.from_file("res://data/voxels/hunchback.json")
	mech.set_side(0)
	check(mech.part_at(Location.CT).material_override ==
			VxLivery.material_for("clan_jade_falcon", 0),
			"team faction becomes the visible material")
	GameSettings.paint_factions[0] = old
	mech.free()
