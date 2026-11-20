class_name SpriteMech
extends Node3D
## A 'Mech drawn with 2D sprites, per docs/graphics/mech-sprite-standard.md:
## six directional views (one per hex facing) plus a top-down view, loaded
## from res://assets/mechs/<sprite>/manifest.json (see sprite-integration.md).
## Picks the view that matches where the camera is relative to the 'Mech's
## facing; above TOP_SWITCH_DEG of camera pitch it lays the top view flat.

const ROOT := "res://assets/mechs/%s/manifest.json"
const TOP_SWITCH_DEG := 70.0

var views: Array[Texture2D] = []  ## Index i = camera at i*60 degrees clockwise from the front.
var top: Texture2D
var billboard: Sprite3D
var flat: Sprite3D


## Returns null if the design has no sprite set yet (caller uses a placeholder).
static func try_build(def: UnitDef) -> SpriteMech:
	if def.sprite == "" or not ResourceLoader.exists(ROOT % def.sprite):
		return null
	var m: Dictionary = JsonFile.read(ROOT % def.sprite)
	var dir := (ROOT % def.sprite).get_base_dir()
	var s := SpriteMech.new()
	s.name = "Sprite_" + def.sprite
	for i in 6:
		var key := str(i * 60)
		s.views.append(load(dir.path_join(m["views"][key])) if m["views"].has(key) else null)
	if m.has("top"):
		s.top = load(dir.path_join(m["top"]))
	s._make_sprites(float(m.get("pixel_size", 0.01)), m.get("pivot", []))
	return s


func _make_sprites(pixel_size: float, pivot: Array) -> void:
	billboard = Sprite3D.new()
	billboard.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	billboard.pixel_size = pixel_size
	billboard.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	billboard.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	billboard.texture = views[0]
	if views[0] and pivot.size() == 2:
		# Put the ground-contact pixel on the hex. TODO(art): verify in engine.
		var size := views[0].get_size()
		billboard.offset = Vector2(size.x / 2.0 - pivot[0], pivot[1] - size.y / 2.0)
	add_child(billboard)
	flat = Sprite3D.new()
	flat.pixel_size = pixel_size
	flat.texture = top
	flat.rotation.x = -PI / 2.0  # Lie flat; image "up" points along the 'Mech's forward (-Z).
	flat.position.y = 0.05
	flat.visible = false
	add_child(flat)


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var to_cam := cam.global_position - global_position
	var pitch := rad_to_deg(atan2(to_cam.y, Vector2(to_cam.x, to_cam.z).length()))
	var use_top := top != null and pitch > TOP_SWITCH_DEG
	flat.visible = use_top
	billboard.visible = not use_top
	if not use_top:
		var tex := views[view_index(global_transform.basis, to_cam)]
		if tex:
			billboard.texture = tex


## Which of the six views to show: 0 = camera in front of the 'Mech, then
## clockwise seen from above (1 = front-right, 3 = behind, 5 = front-left).
static func view_index(basis: Basis, to_cam: Vector3) -> int:
	var fwd := -basis.z
	var a := Vector2(fwd.x, fwd.z).angle_to(Vector2(to_cam.x, to_cam.z))
	return posmod(roundi(rad_to_deg(a) / 60.0), 6)
