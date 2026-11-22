class_name BattleFocusFx
extends Node3D
## Selection and enemy aim rings are lightweight visual-only indicators.
## They track the same UnitViews as the camera, including movement animation.

const SELECT_COLOR := Color("#f7c66f")
const TARGET_COLOR := Color("#ff706b")

var _selected: MeshInstance3D
var _target: MeshInstance3D
var _elapsed := 0.0


func _ready() -> void:
	name = "BattleFocus"
	var ribbon := HexMesh.ring(HexLayout.HEX_SIZE * 0.93, 0.075)
	_selected = _make(ribbon, SELECT_COLOR)
	_target = _make(ribbon, TARGET_COLOR)


func _make(ribbon: Mesh, tint: Color) -> MeshInstance3D:
	var inst := MeshInstance3D.new()
	inst.mesh = ribbon
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(tint.r, tint.g, tint.b, 0.85)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	inst.material_override = mat
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	inst.visible = false
	add_child(inst)
	return inst


func follow(layer: UnitsLayer, selected: Unit, target: Unit) -> void:
	_place(_selected, layer, selected)
	_place(_target, layer, target if target != selected else null)


func _place(marker: MeshInstance3D, layer: UnitsLayer, unit: Unit) -> void:
	var view: UnitView = layer.view_of(unit) if unit != null else null
	marker.visible = view != null and view.visible and view.is_inside_tree()
	if marker.visible:
		marker.global_position = view.global_position + Vector3(0.0, 0.055, 0.0)


func _process(delta: float) -> void:
	_elapsed += delta
	if _selected != null:
		_selected.transparency = 0.13 + 0.13 * (0.5 + 0.5 * sin(_elapsed * 3.2))
	if _target != null:
		_target.transparency = 0.11 + 0.21 * (0.5 + 0.5 * sin(_elapsed * 5.5))
