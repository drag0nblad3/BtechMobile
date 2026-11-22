class_name LessonCard
extends CanvasLayer
## Tutorial lessons, one card at a time at the top right, clear of the
## screen centre where the camera puts the player's 'Mech.
## Queued lessons wait for "Got it". `open` is true while a card shows.

const WIDTH := 500.0

var _queue: Array[Dictionary] = []
var _box: VBoxContainer
var _title: Label
var _text: Label
var _more: Label


func _ready() -> void:
	layer = 5
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	center.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	center.offset_top = 156
	center.offset_right = -18
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_box = UiKit.panel(center)
	_box.get_parent().custom_minimum_size = Vector2(WIDTH, 0)
	_title = UiKit.label(_box, "", 28)
	UiSkin.label(_title, "heading")
	UiSkin.rule(_box)
	_text = UiKit.label(_box, "", UiKit.SMALL)
	_text.custom_minimum_size = Vector2(WIDTH - 24, 0)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	_box.add_child(row)
	_more = UiKit.label(row, "", UiKit.SMALL)
	_more.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiKit.button(row, "Got it", _next, Vector2(160, 60), "primary")
	_box.get_parent().visible = false


func is_open() -> bool:
	return _box.get_parent().visible


func add(lessons: Array[Dictionary]) -> void:
	_queue.append_array(lessons)
	if not is_open():
		_next()
	_more.text = "%d more" % _queue.size() if _queue.size() > 0 else ""


func _next() -> void:
	var panel := _box.get_parent() as Control
	if _queue.is_empty():
		panel.visible = false
		return
	var l: Dictionary = _queue.pop_front()
	_title.text = l.get("title", "")
	_text.text = l.get("text", "")
	_more.text = "%d more" % _queue.size() if _queue.size() > 0 else ""
	panel.visible = true
