class_name CombatLogView
extends PanelContainer
## Scrolling battle log. Tap "Log" to cycle small -> large -> hidden.

const HEIGHTS := [150, 400, 0]
const MAX_LINES := 300

var text: RichTextLabel
var _size_index := 0
var _lines: Array[String] = []


func _ready() -> void:
	add_theme_stylebox_override("panel",
		UiSkin.panel_style(Color("#0a1723e8"), UiSkin.BORDER, 8))
	custom_minimum_size = Vector2(540, HEIGHTS[0])
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 4)
	add_child(contents)
	var header := Label.new()
	header.text = "COMBAT TELEMETRY    /    LIVE"
	header.add_theme_font_size_override("font_size", 16)
	UiSkin.label(header, "section")
	contents.add_child(header)
	text = RichTextLabel.new()
	text.scroll_following = true
	text.bbcode_enabled = true
	text.add_theme_font_size_override("normal_font_size", 18)
	text.add_theme_font_size_override("bold_font_size", 18)
	text.add_theme_color_override("default_color", UiSkin.TEXT)
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	contents.add_child(text)


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
