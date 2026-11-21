extends SceneTree
## Renders map props (voxel buildings, trees, fire, ground) up close to a PNG:
##   xvfb-run godot --rendering-method gl_compatibility -s tools/props_capture.gd -- out.png [map.json] [yaw] [dist] [hex XXYY to aim at]

var _frames := 0
var _out := "props.png"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else _out
	var path: String = args[1] if args.size() > 1 else "res://data/maps/city_outskirts.json"
	var map := MapLoader.load_file(path, TerrainDb.load_file())
	var world := Node3D.new()
	root.add_child(world)
	world.add_child(BattleEnvironment.build())
	var view := MapView.new()
	world.add_child(view)
	view.build(map)
	var cam := Camera3D.new()
	world.add_child(cam)
	var box := HexLayout.map_bounds(map)
	var yaw := deg_to_rad(float(args[2]) if args.size() > 2 else 20.0)
	var dist := float(args[3]) if args.size() > 3 else box.size.length() * 0.55
	var c := box.get_center()
	if args.size() > 4:
		c = HexLayout.tile_top(map.get_tile(Hex.from_label(args[4])))
	cam.look_at_from_position(c + Vector3(sin(yaw) * dist * 0.7, dist * 0.6, cos(yaw) * dist * 0.7), c)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 30:
		root.get_viewport().get_texture().get_image().save_png(_out)
		print("saved ", _out)
		return true
	return false
