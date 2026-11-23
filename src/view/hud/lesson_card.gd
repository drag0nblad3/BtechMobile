class_name LessonCard
extends CanvasLayer
## Queues training lessons. A cadet can put the cards away mid-battle
## without discarding them; the small Lessons button resumes the queue.

const WIDTH := 500.0

var _queue: Array[Dictionary] = []
var _current: Dictionary = {}
var _snoozed := false
var _box: VBoxContainer
var _title: Label
var _text: Label
var _more: Label
var _resume_button: Button


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
	UiKit.button(row, "Later", _later, Vector2(140, 60))
	UiKit.button(row, "Got it", _next, Vector2(160, 60), "primary")
	_box.get_parent().visible = false
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	_resume_button = UiKit.button(overlay, "Lessons", _resume, Vector2(170, 52), "secondary")
	_resume_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_resume_button.offset_left = -188
	_resume_button.offset_right = -18
	_resume_button.offset_top = 156
	_resume_button.offset_bottom = 208
	_resume_button.visible = false


func is_open() -> bool:
	return _box.get_parent().visible


func add(lessons: Array[Dictionary]) -> void:
	_queue.append_array(lessons)
	if not _snoozed and not is_open() and not _queue.is_empty():
		_next()
	_refresh_badge()


func _later() -> void:
	_snoozed = true
	_box.get_parent().visible = false
	_refresh_badge()


func _resume() -> void:
	_snoozed = false
	if _current.is_empty():
		_next()
	else:
		_box.get_parent().visible = true
	_refresh_badge()


func _next() -> void:
	var panel := _box.get_parent() as Control
	if _queue.is_empty():
		_current.clear()
		panel.visible = false
		_refresh_badge()
		return
	_current = _queue.pop_front()
	_title.text = String(_current.get("title", ""))
	_text.text = String(_current.get("text", ""))
	panel.visible = true
	_refresh_badge()


func _refresh_badge() -> void:
	var count := _queue.size() + (0 if _current.is_empty() else 1)
	_more.text = "%d more" % _queue.size() if _queue.size() > 0 else ""
	_resume_button.text = "Lessons (%d)" % count
	_resume_button.visible = _snoozed and count > 0
