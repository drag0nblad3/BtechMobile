extends SceneTree
## Write the *source* Atlas geometry as editable OBJ meshes, prior to
## converting any surfaces into damage cells. CUT_ groups are watertight
## CSG subtractor volumes for eye sockets, barrels and launcher openings.


func _initialize() -> void:
	call_deferred("_export")


func _export() -> void:
	var args := OS.get_cmdline_user_args()
	var target := "/tmp/atlas-source"
	if not args.is_empty():
		target = args[0]
	DirAccess.make_dir_recursive_absolute(target)
	var total := 0
	for part in ["torso", "left_arm", "right_arm", "left_leg", "right_leg",
			"left_leg_shin", "right_leg_shin", "left_leg_foot",
			"right_leg_foot"]:
		var path := target.path_join(part + ".obj")
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			printerr("ATLAS_OBJ_FAILED|", path)
			quit(1)
			return
		file.store_line("# Atlas AS7-D manually authored source mesh")
		file.store_line("# Units: meters; CSG CUT groups must be subtracted")
		file.store_line("# Reference: AS7-D classic TRO and CGL miniature")
		var vertex_idx := 1
		var triangles := 0
		for component: Dictionary in AtlasSourceMesh.part_meshes(part):
			var name: String = str(component["name"])
			var phase: int = int(component["phase"])
			var group := ("CUT_" if phase == 1 else
					("INSET_" if phase == 2 else "ADD_")) + name
			file.store_line("g " + group)
			file.store_line("usemtl material_%d" % int(component["material"]))
			var verts: PackedVector3Array = component["tris"]
			for v: Vector3 in verts:
				var m := v * VoxelPart.VOXEL_SIZE
				file.store_line("v %.6f %.6f %.6f" % [m.x, m.y, m.z])
			for i in range(0, verts.size(), 3):
				var a := vertex_idx + i
				file.store_line("f %d %d %d" % [a, a + 1, a + 2])
				triangles += 1
			vertex_idx += verts.size()
		file.close()
		total += triangles
		print("ATLAS_OBJ|", part, "|", triangles, "|", path)
	print("ATLAS_OBJ_TOTAL_TRIANGLES|", total)
	quit(0)
