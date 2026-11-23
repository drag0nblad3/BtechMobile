extends SceneTree
## Validates the visual scene graph without a GPU. Shader compilation and
## actual appearance are separately checked by Godot's import / screenshot QA.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	BattleLaunch.bot_sides = []  # prevent AI turns while inspecting.
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	if not _check(scene.hud._phase_cells.size() == Phase.Kind.size(),
			"phase tracker must display all battle phases"):
		return
	scene.hud.set_phase(Phase.Kind.WEAPON_ATTACK)
	scene.hud._on_tool_action(4)
	if not _check(scene.hud.perf_readout.visible, "performance overlay can be enabled"):
		return
	scene.hud._on_tool_action(4)
	if not _check(not scene.hud.perf_readout.visible, "performance overlay can be hidden"):
		return
	var active: StyleBoxFlat = scene.hud._phase_cells[Phase.Kind.WEAPON_ATTACK].get_theme_stylebox("panel")
	if not _check(active.border_color == UiSkin.AMBER, "weapon phase indicator"):
		return
	scene.hud.show_combat_event(GameEvent.new(GameEvent.WEAPON_FIRED, {"hit": false}))
	if not _check(scene.hud._event_panel.visible and
			scene.hud._event_label.text == "SHOT MISSED", "miss banner"):
		return
	var highlighter: HexHighlighter = scene.movement.highlighter
	var cell: Vector2i = scene.controller.state.map.coords()[0]
	highlighter.show_hexes({cell: HexHighlighter.REACH_WALK})
	if not _check(highlighter.multimesh.instance_count == 1 and
			highlighter._borders.multimesh.instance_count == 1,
			"selection overlay and outline stay in sync"):
		return
	highlighter.clear()
	if not _check(highlighter._borders.multimesh.instance_count == 0,
			"outline clears along with fill"):
		return
	var water := scene.map_view.get_node_or_null("Water") as MultiMeshInstance3D
	if not _check(water != null and water.material_override is ShaderMaterial,
			"water uses procedural shader"):
		return
	var env := scene.get_node_or_null("Environment/SkyFill") as DirectionalLight3D
	if not _check(env != null and not env.shadow_enabled,
			"mobile fill light must be shadowless"):
		return
	var fx: Node3D = scene.fx
	var trail := ShotFx.spawn(fx, Vector3(0, 1, 0), Vector3(5, 1, 0),
		"er_ppc", true)
	if not _check(trail != null and trail.is_in_group("battle_shot"), "visible shot FX"):
		return
	await create_timer(0.6).timeout
	if not _check(not is_instance_valid(trail), "shot FX frees itself"):
		return
	# A real jump-capable unit must take off, reach an arc, and clean up.
	var jumper: Unit = null
	for unit: Unit in scene.controller.state.units:
		if unit.def.jump_mp >= 3:
			jumper = unit
			break
	if not _check(jumper != null, "scenario has a jumper"):
		return
	var original: Vector2i = jumper.coord
	var landing := Hex.INVALID
	for coord: Vector2i in scene.controller.state.map.coords():
		if Hex.distance(original, coord) == 2 and scene.controller.state.map.get_tile(coord) != null:
			landing = coord
			break
	if not _check(landing != Hex.INVALID, "jump endpoint exists"):
		return
	var jumper_view: UnitView = scene.units_layer.view_of(jumper)
	var initial: Vector3 = jumper_view.position
	jumper_view.play_path([Vector3i(landing.x, landing.y, jumper.facing)],
		original, jumper.facing, MoveMode.Kind.JUMP)
	await create_timer(0.20).timeout
	if not _check(jumper_view.position.y > initial.y + 0.15, "jumper rises off ground"):
		return
	if not _check(get_nodes_in_group("jump_fx").size() > 0, "jump plumes are active"):
		return
	await create_timer(1.35).timeout
	if not _check(get_nodes_in_group("jump_fx").is_empty(), "jump plume cleanup"):
		return
	print("battle visuals smoke ok")
	quit(0)


func _check(ok: bool, description: String) -> bool:
	if not ok:
		printerr("BATTLE_VISUAL_FAILED: ", description)
		quit(1)
	return ok
