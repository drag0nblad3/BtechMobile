class_name NameplateOverlay
extends Control
## Non-interactive screen-space labels. Anchors track the camera immediately;
## only the collision displacement is eased, so moving units never drag labels behind.

const NAME_SIZE := 19
const DETAIL_SIZE := 15
const PAD := 7.0
const ANCHOR_GAP := 9.0
const LAYOUT_INTERVAL := 0.075
var _offsets := {}
var _targets := {}
var _rows: Array[Dictionary] = []
var _signature: Array = []
var _layout_wait := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _extent(data: Dictionary) -> Vector2:
	var font := get_theme_default_font()
	var width := font.get_string_size(data["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE).x
	for key: String in ["health", "attack"]:
		width = maxf(width, font.get_string_size(data[key], HORIZONTAL_ALIGNMENT_LEFT, -1, DETAIL_SIZE).x)
	return Vector2(ceilf(width) + PAD * 2.0, 48.0 if String(data["attack"]).is_empty() else 66.0)


func update_plates(camera: Camera3D, layer: UnitsLayer, content: Dictionary, selected: int,
		delta: float) -> void:
	_rows.clear()
	if camera == null:
		_offsets.clear()
		_targets.clear()
		_signature.clear()
		queue_redraw()
		return
	var viewport := get_viewport_rect()
	var safe := SafeArea.insets(get_viewport())
	var left := 10.0 + float(safe["left"])
	var top := 10.0 + float(safe["top"])
	var bounds := Rect2(viewport.position + Vector2(left, top),
		viewport.size - Vector2(left + 10.0 + float(safe["right"]), top + 10.0 + float(safe["bottom"])))
	var ids: Array = content.keys()
	ids.sort()
	if ids.has(selected):
		ids.erase(selected)
		ids.push_front(selected)
	var signature: Array = [bounds]
	for id: int in ids:
		var view := layer.views.get(id) as Node3D
		if not is_instance_valid(view) or not view.is_visible_in_tree():
			continue
		var world := view.global_position + Vector3(0, Nameplates.LIFT, 0)
		if camera.is_position_behind(world):
			continue
		var anchor := camera.unproject_position(world)
		if not viewport.has_point(anchor):
			continue
		var data: Dictionary = content[id]
		var extent := _extent(data)
		var rect := Rect2(anchor - Vector2(extent.x * 0.5, extent.y + ANCHOR_GAP), extent)
		_rows.append({"id": id, "rect": rect, "anchor": anchor, "data": data})
		signature.append([id, extent])
	_layout_wait -= delta
	if signature != _signature or _layout_wait <= 0.0:
		_targets = NameplateLayout.solve(_rows, bounds, _targets)
		_signature = signature
		_layout_wait = LAYOUT_INTERVAL
	var live := {}
	for row: Dictionary in _rows:
		var id: int = row["id"]
		var desired: Rect2 = row["rect"]
		var target: Vector2 = _targets.get(id, Vector2.ZERO)
		var offset := NameplateLayout.ease(_offsets.get(id, target), target, delta)
		var actual := NameplateLayout.fit(Rect2(desired.position + offset, desired.size), bounds)
		row["display"] = actual
		live[id] = actual.position - desired.position
	_offsets = live
	queue_redraw()


func _draw() -> void:
	# Leaders are underneath every label; show them only for displaced plates.
	for row: Dictionary in _rows:
		var rect: Rect2 = row["display"]
		var preferred: Rect2 = row["rect"]
		if rect.position.distance_to(preferred.position) < 12.0:
			continue
		var anchor: Vector2 = row["anchor"]
		var end := Vector2(clampf(anchor.x, rect.position.x, rect.end.x),
			clampf(anchor.y, rect.position.y, rect.end.y))
		if anchor.distance_to(end) < 2.0:
			continue
		var data: Dictionary = row["data"]
		var tint: Color = data["tint"]
		draw_line(anchor, end, Color(0.02, 0.04, 0.07, 0.8), 3.5, true)
		draw_line(anchor, end, Color(tint, 0.8), 1.5, true)
		draw_circle(anchor, 2.5, tint)
	# Draw low-priority plates first if a cluster is too dense to fully resolve.
	for i in range(_rows.size() - 1, -1, -1):
		var row: Dictionary = _rows[i]
		var rect: Rect2 = row["display"]
		var data: Dictionary = row["data"]
		var tint: Color = data["tint"]
		draw_rect(rect, Color("#091722eb"))
		draw_rect(rect, Color(tint, 0.8), false, 1.0)
		draw_rect(Rect2(rect.position, Vector2(3, rect.size.y)), tint)
		_line(rect, 19.0, data["name"], NAME_SIZE, tint)
		_line(rect, 39.0, data["health"], DETAIL_SIZE, data["health_color"])
		if not String(data["attack"]).is_empty():
			_line(rect, 57.0, data["attack"], DETAIL_SIZE, UiSkin.AMBER)


func _line(rect: Rect2, baseline: float, value: String, font_size: int, hue: Color) -> void:
	draw_string(get_theme_default_font(), rect.position + Vector2(PAD, baseline), value,
		HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - PAD * 2.0, font_size, hue)
