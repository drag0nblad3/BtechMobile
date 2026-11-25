class_name Nameplates
extends Node3D
## Floating plates over the selected 'Mech and every 'Mech it can see: name,
## a health bar and, for enemies, its best to-hit number (PlateInfo). They
## follow the unit views every frame and re-read the state a few times a second.

const LIFT := 2.4        ## Height above the unit's hex.
const REFRESH := 0.25    ## Seconds between state re-reads.

var state: GameState
var units_layer: UnitsLayer
var viewer_of: Callable  ## () -> Unit: the selected 'Mech, or null.
var _plates: Dictionary = {}  ## unit id -> Label3D
var _wait := 0.0


func setup(s: GameState, layer: UnitsLayer, viewer: Callable) -> void:
	state = s
	units_layer = layer
	viewer_of = viewer
	for u in s.all_units():
		var plate := Node3D.new()
		plate.visible = false
		add_child(plate)
		var tint: Color = PlaceholderMech.SIDE_COLORS[u.side % PlaceholderMech.SIDE_COLORS.size()].lightened(0.55)
		_label(plate, 32, 40, tint)       # name
		_label(plate, 22, 0, Color.WHITE) # health bar
		_label(plate, 28, -36, Color(1.0, 0.9, 0.55))  # attack
		_plates[u.id] = plate


func _label(plate: Node3D, size: int, y: float, color: Color) -> Label3D:
	var l := Label3D.new()
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.fixed_size = true
	l.pixel_size = 0.0008
	l.font_size = size
	l.offset = Vector2(0, y)
	l.outline_size = 8
	l.outline_modulate = Color(0, 0, 0, 0.9)
	l.render_priority = 10
	l.outline_render_priority = 9
	l.modulate = color
	plate.add_child(l)
	return l


func _process(delta: float) -> void:
	for id: int in _plates:
		var plate: Node3D = _plates[id]
		if not plate.visible:
			continue
		var v := units_layer.views.get(id) as Node3D
		if v and v.visible:
			plate.position = v.position + Vector3(0, LIFT, 0)
		else:
			plate.visible = false
	_wait -= delta
	if _wait <= 0.0:
		_wait = REFRESH
		refresh()


## Re-reads who is visible from the selected 'Mech and what each plate says.
func refresh() -> void:
	var viewer: Unit = viewer_of.call() if viewer_of.is_valid() else null
	var shown := {}
	for u in PlateInfo.visible_from(state, viewer):
		var v: UnitView = units_layer.view_of(u)
		if v != null and v.visible:
			shown[u.id] = u
	for id: int in _plates:
		var plate: Node3D = _plates[id]
		plate.visible = shown.has(id)
		if plate.visible:
			var v: UnitView = units_layer.views[id]
			plate.position = v.position + Vector3(0, LIFT, 0)
			fill(plate, shown[id], viewer)


func fill(plate: Node3D, u: Unit, viewer: Unit) -> void:
	var name_l := plate.get_child(0) as Label3D
	var bar_l := plate.get_child(1) as Label3D
	var atk_l := plate.get_child(2) as Label3D
	name_l.text = u.def.name
	var hp := PlateInfo.health(u)
	var st := PlateInfo.status(u)
	bar_l.text = PlateInfo.bar(hp) + ("  " + st if st != "" else "")
	bar_l.modulate = Color(0.45, 0.95, 0.45) if hp > 0.66 else (Color(1.0, 0.85, 0.3) if hp > 0.33 else Color(1.0, 0.4, 0.35))
	atk_l.text = PlateInfo.attack(state, viewer, u)["text"]
