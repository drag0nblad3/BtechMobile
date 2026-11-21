extends SceneTree
## Renders the game to a PNG (for visual checks without a device):
##   xvfb-run godot --rendering-method gl_compatibility -s tools/capture.gd -- out.png [mode]
## Modes: (none) battle start · select (move highlights) · attack (weapon phase,
## first enemy targeted) · sheet (record sheet open) · menu (force builder) · clanmenu (its Clan list) ·
## map=<id> (battle start on that map) · tutorial (training battle, first lesson) ·
## training (the training campaign screen).

var _frames := 0
var _scene: Node
var _out := "capture.png"
var _mode := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	_mode = args[1] if args.size() > 1 else ""
	if _mode.begins_with("map="):  # e.g. map=rolling_hills: two lances on that map
		var fb := ForceBuilder.new(UnitDb.load_dir(), 6000)
		for id in ["griffin_grf1n", "warhammer_whm6r"]:
			fb.add(0, id)
		for id in ["marauder_mad3r", "wasp_wsp1a"]:
			fb.add(1, id)
		BattleLaunch.pending = fb.build(MapLoader.load_file(
				"res://data/maps/%s.json" % _mode.substr(4), TerrainDb.load_file()))
	if _mode == "tutorial":
		var tut := "res://data/scenarios/tutorial.json"
		BattleLaunch.pending = ScenarioLoader.load_file(tut, TerrainDb.load_file(), UnitDb.load_dir())
		BattleLaunch.bot_sides = [1]
		BattleLaunch.tutorial_path = tut
	BattleLaunch.open_training = _mode == "training"
	var path := "res://scenes/menu.tscn" if _mode.ends_with("menu") or _mode == "training" else "res://scenes/main.tscn"
	_scene = load(path).instantiate()
	root.add_child(_scene)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 5:
		match _mode:
			"select":
				_select_far_move()
			"attack", "sheet":
				_to_weapon_phase()
			"clanmenu":
				_scene.catalog.mode = DesignFilter.Mode.CLAN
				_scene.catalog.rebuild()
	if _frames == 7 and (_mode == "attack" or _mode == "sheet"):
		_target_nearest()
	if _frames == 8 and _mode == "sheet":
		_scene._toggle_sheet()
	if _frames == 40:
		root.get_viewport().get_texture().get_image().save_png(_out)
		print("saved ", _out)
		return true
	return false


func _select_far_move() -> void:
	var u: Unit = _scene.controller.pending_units()[0]
	_scene.movement.on_hex_tapped(u.coord)
	var reach: Dictionary = _scene.movement.options.reachable_hexes()
	var far: Vector2i = u.coord
	for c: Vector2i in reach:
		if Hex.distance(c, u.coord) > Hex.distance(far, u.coord):
			far = c
	_scene.movement.on_hex_tapped(far)


## Everyone walks straight ahead as far as possible, then the first
## attacker targets the nearest enemy.
func _to_weapon_phase() -> void:
	var gc: GameController = _scene.controller
	while gc.state.phase == Phase.Kind.MOVEMENT:
		var u: Unit = gc.pending_units()[0]
		var opts := MovePlanner.plan(gc.state, u, MoveMode.Kind.RUN)
		var best := opts.start_key()
		for k: Vector3i in opts.cost:
			if opts.can_reach(k) and k.z == u.facing and opts.cost[k] > opts.cost.get(best, 0):
				best = k
		gc.submit_move(u, best, MoveMode.Kind.RUN)


func _target_nearest() -> void:
	var gc: GameController = _scene.controller
	var a: Unit = _scene.attacks.attacker
	var best_e: Unit = null
	for e in gc.state.units:
		if e.side != a.side and (best_e == null or Hex.distance(a.coord, e.coord) < Hex.distance(a.coord, best_e.coord)):
			best_e = e
	# Capture only: bring the target into range so the weapon list has rows.
	var spot := Hex.neighbor(Hex.neighbor(Hex.neighbor(Hex.neighbor(a.coord, a.facing), a.facing), a.facing), a.facing)
	if gc.state.map.has(spot) and gc.state.unit_at(spot) == null:
		best_e.coord = spot
		_scene.units_layer.refresh_unit(best_e.id)
	_scene.attacks.on_hex_tapped(best_e.coord)
