extends SceneTree
## Renders the game to a PNG (for visual checks without a device):
##   xvfb-run godot --rendering-method gl_compatibility -s tools/capture.gd -- out.png [mode]
## Modes: (none) battle start · select (move highlights) · attack (weapon phase,
## first enemy targeted) · sheet (record sheet open) · menu (force builder) · setupmenu (its Battlefield page) · clanmenu (its Clan list) ·
## map=<id> (battle start on that map) · gen=<theme>[:seed] (generated two-sheet map) ·
## jump (mid-air jump-jet preview) · tutorial (training battle, first lesson) · rolls (sample roll feed) ·
## launcher (first screen) · training (the training campaign screen) · notebook (its notebook, two missions played) ·
## campaign (company screen after one battle; replaces user://campaign.json).

var _frames := 0
var _scene: Node
var _out := "capture.png"
var _mode := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	_mode = args[1] if args.size() > 1 else ""
	if _mode == "voxel":
		GameSettings.load_settings()
		GameSettings.voxel_mechs = true  # capture-only override, never saved
		var fb := ForceBuilder.new(UnitDb.load_dir(), 20000)
		for side in 2:
			for i in 4:
				fb.add(side, "hunchback_hbk4g")
		BattleLaunch.pending = fb.build(MapLoader.load_file(
				"res://data/maps/city_outskirts.json", TerrainDb.load_file()))
		BattleLaunch.bot_sides = []
	if _mode.begins_with("map=") or _mode.begins_with("gen=") or _mode in ["vfx", "jump"]:  # two lances on that map
		var fb := ForceBuilder.new(UnitDb.load_dir(), 6000)
		for id in ["griffin_grf1n", "warhammer_whm6r"]:
			fb.add(0, id)
		for id in ["marauder_mad3r", "wasp_wsp1a"]:
			fb.add(1, id)
		BattleLaunch.pending = fb.build(_capture_map())
	if _mode.begins_with("weather="):
		var preset := _mode.substr(8)
		var cfg := {}
		match preset:
			"night": cfg = {"night": true}
			"rain": cfg = {"rain": true, "wind": true}
			"snow": cfg = {"snowfall": true, "wind": true}
			"fog": cfg = {"low_visibility": true}
			"heat": cfg = {"heat": 3}
			"cold": cfg = {"cold": 3}
			"wind": cfg = {"wind": true, "rain": true}
		var fb := ForceBuilder.new(UnitDb.load_dir(), 8000)
		for side in 2:
			fb.add(side, "hunchback_hbk4g")
			fb.add(side, "warhammer_whm6r")
		fb.conditions = Conditions.from_dict(cfg)
		BattleLaunch.pending = fb.build(MapLoader.load_file(
				"res://data/maps/city_outskirts.json", TerrainDb.load_file()))
		BattleLaunch.bot_sides = []
	if _mode in ["vfx", "jump"]:
		BattleLaunch.bot_sides = []  # cinematic frame, no bot actions
	if _mode == "tutorial":
		var tut := "res://data/scenarios/tutorial.json"
		BattleLaunch.pending = ScenarioLoader.load_file(tut, TerrainDb.load_file(), UnitDb.load_dir())
		BattleLaunch.bot_sides = [1]
		BattleLaunch.tutorial_path = tut
	BattleLaunch.open_training = _mode in ["training", "notebook"]
	if _mode == "notebook":
		GameSettings.load_settings()
		GameSettings.training = {"first_steps": {"won": true, "kills": 1}, "woods": {"won": false, "kills": 0}}
	if _mode == "campaign":
		_sample_company()
	var path := "res://scenes/launcher.tscn" if _mode == "launcher" else "res://scenes/menu.tscn" if _mode.ends_with("menu") or BattleLaunch.open_training or BattleLaunch.open_campaign else "res://scenes/main.tscn"
	_scene = load(path).instantiate()
	root.add_child(_scene)


## A company after one battle: one 'Mech hurt, its pilot wounded.
func _sample_company() -> void:
	var c := Campaign.create(CampaignRules.load_file(), ChaosRules.load_file())
	var u := c.mechs[0].to_unit(UnitDb.load_dir(), 1, 0, Pilot.new())
	u.armor[Location.LA] = 0
	u.structure[Location.LA] -= 4
	u.armor[Location.CT] -= 9
	u.slots[Location.LA][2].hit = true
	c.mechs[0].condition = MechCondition.lasting(u)
	c.pilots[0].wounds = 1
	c.pilots[1].kills = 1
	for p in c.pilots:
		p.battles = 1
	c.battles = 1
	c.last_report.assign(["Battle 1: victory.", "Captain Ada Rhee's Wolverine WVR-6R needs repairs.",
		"Lt. Joss Marek fought, 1 kill.", "✓ Advance Attack (300 WP)", "✗ Frugal is the Word (300 WP)",
		"Warchest: +300 WP, now 550 WP."])
	c.wp = 550
	CampaignStore.save(c)
	BattleLaunch.open_campaign = true


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 5:
		match _mode:
			"select", "arcs":
				_select_far_move()
			"attack", "sheet", "rolls", "aim":
				_to_weapon_phase()
			"notebook":
				_scene.get_child(_scene.get_child_count() - 1)._show_notebook()
			"setupmenu":
				_scene._show_page(1)
			"clanmenu":
				_scene.catalog.mode = DesignFilter.Mode.CLAN
				_scene.catalog.rebuild()
	if _frames == 30 and _mode == "rolls":
		_show_sample_rolls()
	if _frames == 7 and _mode in ["attack", "sheet", "aim"]:
		_target_nearest()
	if _frames == 8 and _mode == "sheet":
		_scene._toggle_sheet()
	if _frames == 8 and _mode == "audio":
		_scene.hud.pause_menu.visible = true  # capture UI without pausing SceneTree
	if _frames == 8 and (_mode in ["vfx", "jump"] or _mode.begins_with("weather=")):
		_stage_battle_visuals()
	if _frames == 12 and _mode == "jump":
		# The CI Compatibility renderer can take hundreds of milliseconds
		# per frame; slow this *review capture* so frame 40 is airborne.
		Engine.time_scale = 0.025
		_stage_jump()
	if _frames == 8 and _mode == "voxel":
		_stage_voxel_group()
	if _frames == 39 and _mode == "vfx":
		# Visual review only: place a PPC across the visible battlefield.
		# Does not affect the actual combat resolution or either roster.
		var all_units: Array = _scene.controller.state.units
		if all_units.size() >= 2:
			var shooter: UnitView = _scene.units_layer.view_of(all_units[0])
			var victim: UnitView = _scene.units_layer.view_of(all_units[all_units.size() - 1])
			var muzzle: Vector3 = shooter.weapon_origin("ppc", 0)
			var target: Vector3 = victim.impact_point(muzzle)
			ShotFx.spawn(_scene.fx, muzzle, target, "er_ppc", true)
			VxBlast.spawn(_scene.fx, target, "impact")
		_scene.hud.show_combat_event(GameEvent.new(GameEvent.WEAPON_FIRED, {"hit": true}))
	if _frames == 8 and _mode == "hitfx":
		var target: Unit = _scene.controller.state.units[0]
		var target_view: UnitView = _scene.units_layer.view_of(target)
		_scene.rig.snap(target_view.position, 10.0)
	if _frames == 24 and _mode == "hitfx":
		var hot: Unit = _scene.controller.state.units[0]
		hot.heat = 22  # cosmetic staging for capture, not a combat action
		_scene.fx.play(GameEvent.new(GameEvent.HEAT, {"unit_id": hot.id, "heat": hot.heat}))
	if _frames == 36 and _mode == "hitfx":
		var hit: Unit = _scene.controller.state.units[0]
		_scene.fx.play(GameEvent.new(GameEvent.DAMAGE,
				{"unit_id": hit.id, "loc": Location.RA, "rear": false, "amount": 24}))
	if _frames == 8 and _mode == "scars":
		var wreck: Unit = _scene.controller.state.units[0]
		wreck.destroyed = true  # capture only, no controller action
		var view: UnitView = _scene.units_layer.view_of(wreck)
		view.snap_to_state()
		_scene.scars.on_event(GameEvent.new(GameEvent.BUILDING,
				{"kind": "fire", "coord": wreck.coord}))
		_scene.scars.on_event(GameEvent.new(GameEvent.DAMAGE,
				{"unit_id": wreck.id, "amount": 24, "loc": Location.CT}))
		_scene.scars.on_event(GameEvent.new(GameEvent.UNIT_DESTROYED, {"unit_id": wreck.id}))
		_scene.rig.focus(view.position)
	if _frames == 40:
		if _mode == "jump" and get_nodes_in_group("jump_fx").is_empty():
			printerr("CAPTURE_JUMP_FAILED: exhaust absent on review frame")
		root.get_viewport().get_texture().get_image().save_png(_out)
		Engine.time_scale = 1.0
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


func _capture_map() -> BattleMap:
	var arg := _mode.substr(4)
	if _mode.begins_with("map=") or _mode in ["vfx", "jump"]:
		var id := "city_outskirts" if _mode in ["vfx", "jump"] else arg
		return MapLoader.load_file("res://data/maps/%s.json" % id, TerrainDb.load_file())
	var parts := arg.split(":")
	var seed_value := int(parts[1]) if parts.size() > 1 else 1
	return MapGenerator.build(MapTheme.find(parts[0]), Vector2i(2, 1), seed_value, TerrainDb.load_file())


## Screenshot-only staging: show real loaded model views in the frame.
## This script is not used by gameplay and does not change deployment rules.
func _stage_battle_visuals() -> void:
	var state: GameState = _scene.controller.state
	if state.units.size() < 2:
		return
	var box := HexLayout.map_bounds(state.map)
	var center := box.get_center()
	# Review close-ups expose physical sockets and exhausts; gameplay uses
	# the normal free tactical camera, never these screenshot-only changes.
	_scene.rig.snap(center + Vector3(0, 0.35, 0), 12.5)
	_scene.rig.cinematic_frame(center + Vector3(0, 0.35, 0),
		12.5, deg_to_rad(24.0), deg_to_rad(38.0))
	_scene.hud.set_tip("")
	var targets := [center + Vector3(-3.5, 0, 0), center + Vector3(3.5, 0, 0)]
	var staged := [state.units[0], state.units[state.units.size() - 1]]
	for i in staged.size():
		var unit: Unit = staged[i]
		var chosen := Hex.INVALID
		var nearest := INF
		for coord: Vector2i in state.map.coords():
			var tile: MapTile = state.map.get_tile(coord)
			if tile.building != null or tile.depth > 0:
				continue
			if state.unit_at(coord) != null:
				continue
			var distance := HexLayout.to_world(coord).distance_to(targets[i])
			if distance < nearest:
				nearest = distance
				chosen = coord
		if chosen != Hex.INVALID:
			unit.coord = chosen
			_scene.units_layer.refresh_unit(unit.id)


## Camera-centered group shot: all eight voxel views must be in frame.
func _stage_voxel_group() -> void:
	var state: GameState = _scene.controller.state
	var center := HexLayout.map_bounds(state.map).get_center()
	var taken := {}
	var sum := Vector3.ZERO
	var count := 0
	for i in state.units.size():
		var unit: Unit = state.units[i]
		var desired := center + Vector3((i % 4 - 1.5) * 2.3, 0,
				(floori(float(i) / 4.0) - 0.5) * 3.3)
		var selected := Hex.INVALID
		var closest := INF
		for c: Vector2i in state.map.coords():
			var tile: MapTile = state.map.get_tile(c)
			if tile.building != null or tile.depth > 0 or taken.has(c):
				continue
			var occupant := state.unit_at(c)
			if occupant != null and occupant != unit:
				continue
			var p := HexLayout.to_world(c, tile.level)
			var distance := Vector2(p.x - desired.x, p.z - desired.z).length_squared()
			if distance < closest:
				closest = distance
				selected = c
		if selected == Hex.INVALID:
			continue
		unit.coord = selected  # capture-only; never submitted to controller
		taken[selected] = true
		_scene.units_layer.refresh_unit(unit.id)
		sum += _scene.units_layer.view_of(unit).global_position
		count += 1
	if count > 0:
		_scene.rig.snap(sum / float(count), 16.0)


## Review only: sample lines in the roll feed, nothing is resolved.
func _show_sample_rolls() -> void:
	var s: GameState = _scene.controller.state
	var a: Unit = s.units[0]
	var t: Unit = s.units[s.units.size() - 1]
	for e in [GameEvent.new(GameEvent.WEAPON_FIRED, {"attacker_id": a.id, "weapon": "Medium Laser", "roll": 9, "need": 8, "hit": true}),
			GameEvent.new(GameEvent.DAMAGE, {"unit_id": t.id, "amount": 5, "loc": Location.LT}),
			GameEvent.new(GameEvent.WEAPON_FIRED, {"attacker_id": a.id, "weapon": "AC/20", "roll": 6, "need": 8, "hit": false}),
			GameEvent.new(GameEvent.PSR, {"unit_id": t.id, "roll": 5, "need": 7, "ok": false})]:
		_scene.hud.roll_feed.add_event(e, s)


## Review-only jumping unit, independent of GameController combat state.
func _stage_jump() -> void:
	var state: GameState = _scene.controller.state
	var chosen: Unit = null
	for u: Unit in state.units:
		if u.def.jump_mp >= 3 and not u.destroyed:
			chosen = u
			break
	if chosen == null:
		printerr("CAPTURE_JUMP_FAILED: no jet-capable unit")
		return
	var center := HexLayout.map_bounds(state.map).get_center()
	var destination := Hex.INVALID
	var closest := INF
	for c: Vector2i in state.map.coords():
		var t: MapTile = state.map.get_tile(c)
		if t.building != null or t.depth > 0 or state.unit_at(c) != null:
			continue
		var distance := Hex.distance(chosen.coord, c)
		if distance < 2 or distance > mini(4, chosen.jump_mp()):
			continue
		var score := HexLayout.to_world(c).distance_to(center)
		if score < closest:
			closest = score
			destination = c
	if destination == Hex.INVALID:
		printerr("CAPTURE_JUMP_FAILED: no nearby landing hex")
		return
	var view: UnitView = _scene.units_layer.view_of(chosen)
	view.play_path([Vector3i(destination.x, destination.y, chosen.facing)],
		chosen.coord, chosen.facing, MoveMode.Kind.JUMP)
