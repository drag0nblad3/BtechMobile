extends SceneTree
## Renders Claude's voxel showcase to PNGs for visual review:
## xvfb-run -a godot --rendering-method gl_compatibility --resolution 1280x720 \
##     -s tools/capture_vx.gd -- /tmp/vx-frames

var out := "/tmp/vx-frames"
var scene: VxShowcase
var frame := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	scene = load("res://scenes/vx_showcase.tscn").instantiate()
	root.add_child(scene)


func _process(_delta: float) -> bool:
	frame += 1
	match frame:
		5: _shot("vx_idle.png")
		6: scene.walk(false)
		30: _shot("vx_walk.png")
		80:
			scene.reset()
			for loc in [Location.CT, Location.RT, Location.LT]:
				Damage.apply(scene.unit, loc, 16)
			Damage.apply(scene.unit, Location.HEAD, 5)
			Damage.apply(scene.unit, Location.LA, 40)
			scene.mech.show_unit(scene.unit)
		120: _shot("vx_damaged.png")
		121: scene.fire(Location.RT)
		140: _shot("vx_fire.png")
		200:
			scene._orbit = 1.75
			scene._aim_camera()
		204: _shot("vx_damaged_side.png")
		205: scene.mech.anim.fall()
		260: _shot("vx_fallen.png")
		261:
			scene.reset()
			scene._orbit = 1.65
			scene._aim_camera()
			scene.walk(false)
		290: _shot("vx_walk_side.png")
		291: return true
	return false


func _shot(file_name: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(out.path_join(file_name))
	print("Saved ", file_name)
