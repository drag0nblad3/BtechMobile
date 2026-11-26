class_name NameplateOverlay
extends Control
## Retained nameplate cards: camera movement changes transforms, not text meshes.
## The screen-space layout and eased separation are unchanged.

const ANCHOR_GAP := 9.0
const LAYOUT_INTERVAL := 0.075
var _offsets := {}
var _targets := {}
var _signature: Array = []
var _layout_wait := 0.0
var _cards: Dictionary = {}
var _safe := {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_safe = SafeArea.insets(get_viewport())
	get_viewport().size_changed.connect(_resize)


func _resize() -> void:
	_safe = SafeArea.insets(get_viewport())
	_signature.clear()


func update_plates(camera: Camera3D, layer: UnitsLayer, content: Dictionary, selected: int,
		delta: float) -> void:
	for id: int in _cards.keys():
		var card: NameplateCard = _cards[id]
		if not content.has(id):
			_cards.erase(id)
			card.queue_free()
		elif not is_instance_valid(camera):
			card.hide_card()
	if not is_instance_valid(camera) or not is_instance_valid(layer):
		_offsets.clear()
		_targets.clear()
		_signature.clear()
		return
	var viewport := get_viewport_rect()
	var left := 10.0 + float(_safe.get("left", 0))
	var top := 10.0 + float(_safe.get("top", 0))
	var bounds := Rect2(viewport.position + Vector2(left, top),
		viewport.size - Vector2(left + 10.0 + float(_safe.get("right", 0)), top + 10.0 + float(_safe.get("bottom", 0))))
	var rows: Array[Dictionary] = []
	var ids: Array = content.keys()
	ids.sort()
	if ids.has(selected):
		ids.erase(selected)
		ids.push_front(selected)
	var signature: Array = [bounds]
	for id: int in ids:
		var view := layer.views.get(id) as Node3D
		var card: NameplateCard = _cards.get(id)
		var anchor := screen_anchor(camera, view, viewport)
		if not anchor.is_finite() or bounds.size.x <= 0 or bounds.size.y <= 0:
			if card != null:
				card.hide_card()
			continue
		if card == null:
			card = NameplateCard.new()
			add_child(card)
			_cards[id] = card
		card.set_content(content[id])
		var extent := card.extent
		var rect := Rect2(anchor - Vector2(extent.x * 0.5, extent.y + ANCHOR_GAP), extent)
		rows.append({"id": id, "rect": rect, "anchor": anchor})
		signature.append([id, extent])
	_layout_wait -= delta
	if signature != _signature or _layout_wait <= 0.0:
		_targets = NameplateLayout.solve(rows, bounds, _targets)
		_signature = signature
		_layout_wait = LAYOUT_INTERVAL
	var live := {}
	for row: Dictionary in rows:
		var id: int = row["id"]
		var desired: Rect2 = row["rect"]
		var target: Vector2 = _targets.get(id, Vector2.ZERO)
		var offset := NameplateLayout.ease(_offsets.get(id, target), target, delta)
		var actual := NameplateLayout.fit(Rect2(desired.position + offset, desired.size), bounds)
		var card: NameplateCard = _cards[id]
		card.place(actual, desired, row["anchor"], id == selected)
		live[id] = actual.position - desired.position
	_offsets = live


## Reject behind-camera, nonfinite and offscreen projections before any
## position reaches the canvas renderer (including transient camera resets).
static func screen_anchor(camera: Camera3D, view: Node3D, viewport: Rect2) -> Vector2:
	if not is_instance_valid(camera) or not is_instance_valid(view) or not view.is_visible_in_tree():
		return Vector2.INF
	var world := view.global_position + Vector3(0, Nameplates.LIFT, 0)
	if not world.is_finite() or camera.is_position_behind(world):
		return Vector2.INF
	var anchor := camera.unproject_position(world)
	return anchor if anchor.is_finite() and viewport.has_point(anchor) else Vector2.INF
