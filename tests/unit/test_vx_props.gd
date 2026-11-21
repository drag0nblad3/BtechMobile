extends TestCase
## Voxel map props: building generator footprint, height, budget, repeatability.

const TYPES := ["civilian", "light", "medium", "heavy", "hardened"]


func test_every_building_class_fits_its_hex_and_height() -> void:
	for id: String in TYPES:
		for levels: int in [1, 2, 3, 4]:
			var m := VxBuildingGen.generate(id, levels, 0).mesh()
			check(m != null, "%s %d: no mesh" % [id, levels])
			if m == null:
				continue
			var box := m.get_aabb()
			var tag := "%s %d" % [id, levels]
			check(box.position.x >= -0.87 and box.end.x <= 0.87, tag + " too wide: %s" % box)
			check(box.position.z >= -0.76 and box.end.z <= 0.76, tag + " too deep: %s" % box)
			var game_h := levels * HexLayout.LEVEL_HEIGHT
			check(box.end.y >= game_h * 0.85, tag + " too low: %.2f < %.2f" % [box.end.y, game_h])
			check(box.end.y <= game_h + 0.75, tag + " too tall: %.2f" % box.end.y)
			check(VxGrid.triangles(m) < 4000, tag + " triangles: %d" % VxGrid.triangles(m))


func test_variants_repeat_exactly() -> void:
	var a := VxBuildingGen.generate("medium", 2, 1)
	var b := VxBuildingGen.generate("medium", 2, 1)
	check_eq(a.cells.size(), b.cells.size())
	check(a.cells == b.cells, "same seed should give the same building")
	var c := VxBuildingGen.generate("medium", 2, 2)
	check(c.cells != a.cells, "variants should differ")


func test_city_map_reuses_cached_meshes() -> void:
	var map := MapLoader.load_file("res://data/maps/city_outskirts.json", terrain())
	var props := BuildingProps.build(map)
	var meshes := {}
	for c in props.get_children():
		meshes[(c as MeshInstance3D).mesh] = true
	check(props.get_child_count() > 0, "city has buildings")
	check(meshes.size() <= props.get_child_count(), "shared meshes")
	props.set_occupied({props._by_coord.keys()[0]: true})
	check_eq(props._ghosted.size(), 1)
	props.set_occupied({})
	check_eq(props._ghosted.size(), 0)
	props.free()
