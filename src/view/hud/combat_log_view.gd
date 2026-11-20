class_name CombatLogView
extends PanelContainer
## Scrolling battle log. Tap "Log" to cycle small -> large -> hidden.

const HEIGHTS := [150, 400, 0]
const MAX_LINES := 300

var text: RichTextLabel
var _size_index := 0
var _lines: Array[String] = []


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.55)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(8)
	add_theme_stylebox_override("panel", style)
	custom_minimum_size = Vector2(540, HEIGHTS[0])
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	text = RichTextLabel.new()
	text.scroll_following = true
	text.bbcode_enabled = true
	text.add_theme_font_size_override("normal_font_size", 18)
	text.add_theme_font_size_override("bold_font_size", 18)
	add_child(text)


func add_line(t: String, bold: bool = false) -> void:
	if t == "":
		return
	var line := t.replace("[", "[lb]")
	_lines.append("[b]%s[/b]" % line if bold else line)
	if _lines.size() > MAX_LINES:
		_lines = _lines.slice(-MAX_LINES)
	text.text = "\n".join(_lines)


func cycle_size() -> void:
	_size_index = (_size_index + 1) % HEIGHTS.size()
	visible = HEIGHTS[_size_index] > 0
	custom_minimum_size.y = HEIGHTS[_size_index]
