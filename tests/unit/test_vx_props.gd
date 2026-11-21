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


func test_trees_stay_small_and_inside_their_hex() -> void:
	for kind: String in ["conifer", "broadleaf"]:
		for v in 3:
			var m := VxTrees.mesh(kind, v)
			var tag := "%s %d" % [kind, v]
			check(m != null, tag + ": no mesh")
			if m == null:
				continue
			var box := m.get_aabb()
			check(VxGrid.triangles(m) < 700, tag + " triangles: %d" % VxGrid.triangles(m))
			check(box.end.y > 0.55 and box.end.y < 1.1, tag + " height %.2f" % box.end.y)
			check(box.size.x < 0.65, tag + " width %.2f" % box.size.x)


func test_woods_use_one_multimesh_per_tree_variant() -> void:
	var map := MapLoader.load_file("res://data/maps/dense_forest.json", terrain())
	var woods := WoodsProps.build(map)
	var trees := 0
	for c in woods.get_children():
		trees += (c as MultiMeshInstance3D).multimesh.instance_count
	check(woods.get_child_count() <= VxTrees.CONIFERS + VxTrees.BROADLEAF, "layers: %d" % woods.get_child_count())
	check(trees > 50, "trees: %d" % trees)
	woods.free()


func test_fire_and_blasts_build_cube_multimeshes() -> void:
	var map := make_map(["c0 c0", "c0 c0"])
	map.get_tile(Vector2i(0, 0)).on_fire = true
	var fires := FireProps.build(map)
	var cubes := 0
	for c in fires.get_children():
		if c is MultiMeshInstance3D:
			cubes += (c as MultiMeshInstance3D).multimesh.instance_count
	check_eq(cubes, FireProps.FLAMES + FireProps.SOOT)
	fires.free()
	var holder := Node3D.new()
	for kind: String in VxBlast.KINDS:
		var p: Dictionary = VxBlast.KINDS[kind]
		var b := VxBlast.spawn(holder, Vector3.ZERO, kind, 7)
		check_eq(b.multimesh.instance_count, int(p["fire"]) + int(p["smoke"]) + int(p["debris"]), kind)
	holder.free()
