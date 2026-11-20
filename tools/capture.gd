extends SceneTree
## Renders the battle scene to a PNG (for visual checks without a device):
##   xvfb-run godot --rendering-method gl_compatibility -s tools/capture.gd -- out.png [select]
## With "select", the first pending unit is selected so move highlights show.

var _frames := 0
var _battle: Node
var _out := "capture.png"
var _select := false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	_select = args.has("select")
	_battle = load("res://scenes/main.tscn").instantiate()
	root.add_child(_battle)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 5 and _select:
		var u: Unit = _battle.controller.pending_units()[0]
		_battle.movement.on_hex_tapped(u.coord)
		var reach: Dictionary = _battle.movement.options.reachable_hexes()
		var far: Vector2i = u.coord
		for c: Vector2i in reach:
			if Hex.distance(c, u.coord) > Hex.distance(far, u.coord):
				far = c
		_battle.movement.on_hex_tapped(far)
	if _frames == 40:
		root.get_viewport().get_texture().get_image().save_png(_out)
		print("saved ", _out)
		return true
	return false
