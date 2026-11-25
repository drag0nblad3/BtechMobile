class_name ReadoutModel
extends VBoxContainer
## Independent viewport for the shipped in-game model, with explicit orbit controls.
var _world: Node3D
var _rig: CameraRig
var _model: VxMech
var _caption: Label
var _preview: Button
var _selected: UnitDef
var _request := 0


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var container := SubViewportContainer.new()
	container.custom_minimum_size = Vector2(0, 290)
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
	var controls := HBoxContainer.new()
	add_child(controls)
	for spec in [["◀", -0.5], ["▶", 0.5]]:
		var angle: float = spec[1]
		UiKit.button(controls, spec[0], func(): _rig.orbit(angle), Vector2(68, 48))
	UiKit.button(controls, "+", func(): _rig.zoom(1.2), Vector2(68, 48))
	UiKit.button(controls, "-", func(): _rig.zoom(0.83), Vector2(68, 48))
	UiKit.button(controls, "Fit", _fit, Vector2(85, 48))
	_caption = UiKit.label(self, "", 17)
	_preview = UiKit.button(self, "LOAD 3D MODEL", _load_selected, Vector2(0, 52), "selected")


func select_design(def: UnitDef) -> void:
	_request += 1
	_selected = def
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
	_fit()


func _fit() -> void:
	if not is_instance_valid(_model):
		return
	var lo := Vector3(INF, INF, INF)
	var hi := -lo
	for part: Dictionary in _model.model.parts:
		for cell: Vector3i in part["cells"]:
			var p := Vector3(cell) * _model.model.voxel_size
			lo = lo.min(p)
			hi = hi.max(p)
	if not lo.is_finite() or not hi.is_finite():
		return
	var middle := (lo + hi) * 0.5
	_rig.cinematic_frame(middle, maxf(4.0, (hi - lo).length() * 1.8), 0.6, deg_to_rad(18.0))
