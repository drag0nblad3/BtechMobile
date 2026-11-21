class_name MapPicker
extends RefCounted
## Start-screen controls for the map: cycle maps, change size, roll a new
## seed or type one in, and a preview of the result.

var choice := MapChoice.new()
var _preview: MapPreview
var _seed_edit: LineEdit
var _size_button: Button
var _on_change: Callable


func build(parent: Control, on_change: Callable) -> void:
	_on_change = on_change
	_preview = MapPreview.new()
	_preview.custom_minimum_size = Vector2(0, 150)
	parent.add_child(_preview)
	var row := HBoxContainer.new()
	parent.add_child(row)
	UiKit.button(row, "Map", func(): choice.next_map(); _changed(), Vector2(90, 60))
	_size_button = UiKit.button(row, "Size", func(): choice.next_size(); _changed(), Vector2(90, 60))
	UiKit.button(row, "New map", func(): choice.reroll(); _changed(), Vector2(110, 60))
	_seed_edit = LineEdit.new()
	_seed_edit.placeholder_text = "seed"
	_seed_edit.custom_minimum_size = Vector2(110, 60)
	_seed_edit.add_theme_font_size_override("font_size", UiKit.SMALL)
	_seed_edit.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	_seed_edit.text_submitted.connect(_typed)
	_seed_edit.focus_exited.connect(func(): _typed(_seed_edit.text))
	row.add_child(_seed_edit)
	refresh()


## Redraw the preview and controls from the current choice.
func refresh() -> void:
	_preview.show_map(choice.preview())
	var gen := choice.is_generated()
	_size_button.disabled = not gen
	_seed_edit.editable = gen
	_seed_edit.text = str(choice.seed_value) if gen else ""


func _typed(text: String) -> void:
	if text.is_valid_int() and int(text) != choice.seed_value:
		choice.set_seed(int(text))
		_changed()


func _changed() -> void:
	refresh()
	_on_change.call()
