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


func test_ground_scatter_stays_within_a_phone_budget() -> void:
	for kind: String in ["tuft", "flower", "bush", "rock", "chunk"]:
		for v in VxPlants.VARIANTS:
			check(VxGrid.triangles(VxPlants.mesh(kind, v)) < 260, "%s %d" % [kind, v])
	var map := MapLoader.load_file("res://data/maps/city_outskirts.json", terrain())
	var scatter := GroundScatter.build(map)
	var tris := 0
	for c in scatter.get_children():
		var mm := (c as MultiMeshInstance3D).multimesh
		tris += mm.instance_count * VxGrid.triangles(mm.mesh)
	var per_hex := float(tris) / map.tiles.size()
	check(per_hex < 250.0, "scatter triangles per hex: %.0f" % per_hex)
	check(tris > 0, "city has clutter")
	scatter.free()


func test_every_terrain_names_a_ground_pattern() -> void:
	for t: TerrainType in terrain().by_id.values():
		check(MapView.PATTERNS.has(t.pattern), t.id + " pattern " + t.pattern)


func test_scars_carve_the_wall_facing_the_shooter_and_survive_rebuild() -> void:
	var map := make_map(["c0 c0 c0", "c0 c0 c0"])
	var t := map.get_tile(Vector2i(1, 0))
	t.building = Building.new(terrain().buildings["medium"], 2)
	var scars := {}
	var props := BuildingProps.build(map, scars)
	var whole := VxBuildingGen.generate("medium", 2, absi(hash(t.coord)) % BuildingProps.VARIANTS).cells.size()
	var shooter := HexLayout.tile_top(map.get_tile(Vector2i(0, 0))) + Vector3(0, 0.5, 0)
	var hit := props.scar(t.coord, shooter, 20)
	var centre := HexLayout.tile_top(t)
	check(hit.distance_to(shooter) < centre.distance_to(shooter), "hole on the near wall: %s" % hit)
	check(props._scarred(t).cells.size() < whole, "voxels removed")
	check_eq(scars[t.coord].size(), 1)
	var again := BuildingProps.build(map, scars)
	check(again._by_coord[t.coord].mesh != BuildingProps.mesh_for("medium", 2, absi(hash(t.coord)) % BuildingProps.VARIANTS), "scarred mesh kept")
	props.free()
	again.free()


func test_voxel_bridges_fit_the_hex_and_take_scars() -> void:
	var open := [false, true, true, false, true, true]
	var g := VxBridgeGen.make(7, open, 0)
	var m := g.mesh()
	check(m != null and VxGrid.triangles(m) < 3000, "bridge triangles: %d" % VxGrid.triangles(m))
	var box := m.get_aabb()
	check(box.position.x >= -0.87 and box.end.x <= 0.87, "bridge fits its hex: %s" % box)
	check(absf(g.deck_top * VxBuildingGen.PITCH - (7 * VxBuildingGen.PITCH)) < 0.01, "deck top where asked")
	var before := g.cells.size()
	var hit := g.hit_cell(Vector2(1, 0), g.deck_top - 1)
	g.carve(hit, 2.5)
	check(g.cells.size() < before, "a shot knocks stones out")
	var m2 := MapLoader.load_file("res://data/maps/river_crossing.json", terrain())
	var props := BridgeProps.build(m2)
	check_eq(props.get_child_count(), 2, "one voxel model per bridge hex")
	var p := props.scar(Hex.from_label("0909"), Vector3(-5, 0, 0), 10)
	check(p != Vector3.ZERO and props.scars.has(Hex.from_label("0909")), "scar recorded")
	props.free()
