class_name Nameplates
extends Node3D
## Floating plates over visible units, with screen-space separation.
## Only invalidated forecasts are recalculated; positioning is cosmetic.

const LIFT := 2.4
const REFRESH := 0.25

var state: GameState
var units_layer: UnitsLayer
var viewer_of: Callable
var _overlay: NameplateOverlay
var _content := {}
var _wait := 0.0
var _dirty := true
var _last_selection: Array = []


func setup(s: GameState, layer: UnitsLayer, viewer: Callable) -> void:
	state = s
	units_layer = layer
	viewer_of = viewer
	var canvas := CanvasLayer.new()
	# Below the battle HUD (layer 1), above the 3D battlefield.
	canvas.layer = 0
	add_child(canvas)
	_overlay = NameplateOverlay.new()
	canvas.add_child(_overlay)


func _process(delta: float) -> void:
	if _overlay == null:
		return
	_wait -= delta
	if _wait <= 0.0:
		_wait = REFRESH
		var viewer: Unit = viewer_of.call() if viewer_of.is_valid() else null
		var selection := selection_key(viewer)
		if _dirty or selection != _last_selection:
			refresh()
	var selected := int(_last_selection[0]) if not _last_selection.is_empty() else -1
	_overlay.update_plates(get_viewport().get_camera_3d(), units_layer, _content, selected, delta)


## Both controller events and completed animations can change visibility.
func invalidate(_reason: Variant = null) -> void:
	_dirty = true


## These pre-declaration edits don't emit controller events.
static func selection_key(viewer: Unit) -> Array:
	if viewer == null:
		return []
	var key := [viewer.id, viewer.torso_twist, viewer.arms_flipped]
	for w: MountedWeapon in viewer.weapons:
		key.append(w.mode)
	return key


## Re-read visible units and their text without changing any game state.
func refresh() -> void:
	var viewer: Unit = viewer_of.call() if viewer_of.is_valid() else null
	_last_selection = selection_key(viewer)
	_dirty = false
	_content.clear()
	for u in PlateInfo.visible_from(state, viewer):
		var v: UnitView = units_layer.view_of(u)
		if v != null and v.visible:
			_content[u.id] = plate_content(state, u, viewer)


static func plate_content(s: GameState, u: Unit, viewer: Unit) -> Dictionary:
	var hp := PlateInfo.health(u)
	var status := PlateInfo.status(u)
	var tint: Color = PlaceholderMech.SIDE_COLORS[u.side % PlaceholderMech.SIDE_COLORS.size()].lightened(0.22)
	return {"name": "%s · %s" % [Names.side(u.side).to_upper(), u.def.name],
		"tint": tint,
		"health": PlateInfo.bar(hp) + ("  " + status if status != "" else ""),
		"health_color": Color(0.45, 0.95, 0.45) if hp > 0.66 else (Color(1.0, 0.85, 0.3) if hp > 0.33 else Color(1.0, 0.4, 0.35)),
		"attack": PlateInfo.attack(s, viewer, u)["text"]}
