extends Node3D
## Draws a mech as 2D sprites in the 3D world, following
## docs/graphics/mech-sprite-standard.md:
## - Six directional views (one per hex facing) on a Y-axis billboard. The view
##   is picked from the camera's bearing relative to the mech's facing.
## - One top-down view lying flat on the ground, rotated to the mech's heading,
##   used when the camera looks down more steeply than the threshold.

const MechSpriteLibrary := preload("res://scripts/mech_sprite_library.gd")

const FACING_COUNT := 6
const FACING_STEP_DEGREES := 60.0
const TOP_VIEW := 6

@export var chassis := "mad_dog"
## Hex facing 0 to 5, clockwise from north (-Z).
@export_range(0, 5) var facing := 0:
	set(value):
		facing = posmod(value, FACING_COUNT)
		_update_heading()
## Camera elevation, in degrees above horizontal, at which the top-down view
## replaces the directional views.
@export var top_down_threshold_degrees := 65.0
@export var pixel_size := 0.01

## 0 to 5 for a directional view, TOP_VIEW for the top-down view, -1 before the
## first frame.
var current_view := -1

var _views: Array[Texture2D] = []
var _side: Sprite3D
var _top_pivot: Node3D
var _top: Sprite3D


func _ready() -> void:
	var sprites := MechSpriteLibrary.load_chassis(chassis)
	_views = sprites["views"]

	_side = Sprite3D.new()
	_side.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_side.shaded = false
	_side.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	_side.pixel_size = pixel_size
	_side.texture = _views[0]
	_side.position.y = _views[0].get_height() * pixel_size * 0.5
	add_child(_side)

	_top_pivot = Node3D.new()
	add_child(_top_pivot)
	_top = Sprite3D.new()
	_top.shaded = false
	_top.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	_top.pixel_size = pixel_size
	_top.texture = sprites["top"]
	_top.rotation_degrees.x = -90.0
	_top.position.y = 0.02
	_top.visible = false
	_top_pivot.add_child(_top)

	_update_heading()


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var to_cam := cam.global_position - global_position
	var horizontal := Vector2(to_cam.x, to_cam.z).length()
	var elevation := rad_to_deg(atan2(to_cam.y, horizontal))
	if elevation >= top_down_threshold_degrees:
		_show_view(TOP_VIEW)
		return
	var bearing := rad_to_deg(atan2(to_cam.x, -to_cam.z))
	var relative := fposmod(bearing - facing * FACING_STEP_DEGREES, 360.0)
	_show_view(roundi(relative / FACING_STEP_DEGREES) % FACING_COUNT)


func current_view_name() -> String:
	if current_view == TOP_VIEW:
		return "top"
	if current_view < 0:
		return "-"
	return "facing_%03d" % (current_view * 60)


func _show_view(view: int) -> void:
	if view == current_view:
		return
	current_view = view
	var is_top := view == TOP_VIEW
	_top.visible = is_top
	_side.visible = not is_top
	if not is_top:
		_side.texture = _views[view]


func _update_heading() -> void:
	if _top_pivot:
		# Positive Y rotation is counterclockwise from above, so negate it.
		_top_pivot.rotation_degrees.y = -facing * FACING_STEP_DEGREES
	# Force the next frame to pick a view again.
	current_view = -1
