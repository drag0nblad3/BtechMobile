class_name ReadoutModel
extends VBoxContainer
## Independent viewport for the shipped in-game model, with explicit orbit controls.
var _world: Node3D
var _viewport_panel: SubViewportContainer
var _model_extent := Vector3.ZERO
var _rig: CameraRig
var _model: VxMech
var _caption: Label
var _preview: Button
var _selected: UnitDef
var _request := 0


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var container := SubViewportContainer.new()
	container.custom_minimum_size = Vector2(0, 220)
	_viewport_panel = container
	container.stretch = true
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(container)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	container.add_child(vp)
	_world = Node3D.new()
	vp.add_child(_world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("#14232e")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.65
	_world.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -40, 0)
	_world.add_child(light)
	_rig = CameraRig.new()
	_world.add_child(_rig)
	_rig.camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_rig.camera.keep_aspect = Camera3D.KEEP_HEIGHT
	container.resized.connect(_resize_fit)
	var controls := HBoxContainer.new()
	add_child(controls)
	for spec in [["◀", -0.5], ["▶", 0.5]]:
		var angle: float = spec[1]
		UiKit.button(controls, spec[0], func(): _rig.orbit(angle), Vector2(56, 48))
	UiKit.button(controls, "+", func(): _zoom(1.2), Vector2(56, 48))
	UiKit.button(controls, "-", func(): _zoom(0.83), Vector2(56, 48))
	UiKit.button(controls, "Fit", _fit, Vector2(72, 48))
	for button: Button in controls.get_children():
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_caption = UiKit.label(self, "", 17)
	_preview = UiKit.button(self, "LOAD 3D MODEL", _load_selected, Vector2(0, 52), "selected")


func select_design(def: UnitDef) -> void:
	_request += 1
	_selected = def
	_model_extent = Vector3.ZERO
	if is_instance_valid(_model):
		_model.free()
		_model = null
	_preview.disabled = def == null
	_caption.text = "Tap Load 3D Model to inspect the selected design." if def != null else "No design selected."


func _load_selected() -> void:
	if _selected == null:
		return
	var request := _request
	var def := _selected
	_preview.disabled = true
	_caption.text = "Preparing 3D model…"
	if BattleLoading.staged():
		await get_tree().process_frame
		await get_tree().process_frame
	if request != _request:
		return
	show_design(def)
	_preview.disabled = false


func show_design(def: UnitDef) -> void:
	if is_instance_valid(_model):
		_model.free()
		_model = null
	var path := UnitVoxels.model_path(def)
	if not FileAccess.file_exists(path):
		_caption.text = "No game model available for this variant."
		return
	_model = VxMech.from_file(path)
	if not _model.model.errors.is_empty():
		_model.free()
		_model = null
		_caption.text = "Model could not be loaded."
		return
	_world.add_child(_model)
	_caption.text = "In-game model • " + ("exact variant" if path.ends_with("/" + def.id + ".json") else "shared chassis")
	_measure_and_fit()


func _measure_and_fit() -> void:
	if not is_instance_valid(_model):
		return
	var lo := Vector3(INF, INF, INF)
	var hi := -lo
	for part: Dictionary in _model.model.parts:
		for cell: Vector3i in part["cells"]:
			var p := Vector3(cell) * _model.model.voxel_size
			lo = lo.min(p)
			hi = hi.max(p + Vector3.ONE * _model.model.voxel_size)
	if not lo.is_finite() or not hi.is_finite():
		return
	var middle := (lo + hi) * 0.5
	_model_extent = hi - lo
	_rig.cinematic_frame(middle, maxf(4.0, _model_extent.length() * 2.0), 0.6, deg_to_rad(18.0))
	_fit()


## Orbit-safe projected extent, with padding and the actual viewport aspect.
static func fit_size(extent: Vector3, aspect: float) -> float:
	var horizontal := Vector2(extent.x, extent.z).length()
	var pitch := deg_to_rad(18.0)
	var vertical := extent.y * cos(pitch) + horizontal * sin(pitch)
	return maxf(0.01, maxf(vertical, horizontal / maxf(aspect, 0.01)) * 1.18)


func _fit() -> void:
	if not is_instance_valid(_model) or _model_extent == Vector3.ZERO:
		return
	var aspect := _viewport_panel.size.x / maxf(_viewport_panel.size.y, 1.0)
	_rig.camera.size = fit_size(_model_extent, aspect)


func _resize_fit() -> void:
	if _rig != null and _viewport_panel.size.x > 0 and _viewport_panel.size.y > 0:
		_fit()


func _zoom(factor: float) -> void:
	if not is_instance_valid(_model):
		return
	var aspect := _viewport_panel.size.x / maxf(_viewport_panel.size.y, 1.0)
	var fitted := fit_size(_model_extent, aspect)
	_rig.camera.size = clampf(_rig.camera.size / factor, fitted * 0.2, fitted * 4.0)
