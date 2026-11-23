class_name CombatLogView
extends PanelContainer
## Scrolling battle log. Tap "Log" to cycle small -> large -> hidden.

const HEIGHTS := [112, 400, 0]  ## Small keeps ~3 lines over the map.
const MAX_LINES := 300

var text: RichTextLabel
var _size_index := 0
var _lines: Array[String] = []


func _ready() -> void:
	add_theme_stylebox_override("panel",
		UiSkin.panel_style(Color("#0a1723e8"), UiSkin.BORDER, 8))
	custom_minimum_size = Vector2(500, HEIGHTS[0])
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


## Severity accents make the most important combat events scannable.
static func tone_for(e: GameEvent) -> String:
	match e.type:
		GameEvent.UNIT_DESTROYED, GameEvent.AMMO_EXPLOSION, GameEvent.CRITICAL:
			return "danger"
		GameEvent.WEAPON_FIRED:
			return "hit" if e.data.get("hit", false) else "miss"
		GameEvent.TURN_STARTED, GameEvent.PHASE_CHANGED:
			return "phase"
	return ""


func add_line(t: String, bold: bool = false, tone: String = "") -> void:
	if t == "":
		return
	var line := t.replace("[", "[lb]")
	match tone:
		"danger":
			line = "[color=#f28a7b]" + line + "[/color]"
		"hit":
			line = "[color=#9cddba]" + line + "[/color]"
		"miss":
			line = "[color=#a9bfcb]" + line + "[/color]"
		"phase":
			line = "[color=#72d2d6]" + line + "[/color]"
	_lines.append("[b]%s[/b]" % line if bold else line)
	if _lines.size() > MAX_LINES:
		_lines = _lines.slice(-MAX_LINES)
	text.text = "\n".join(_lines)


func cycle_size() -> void:
	_size_index = (_size_index + 1) % HEIGHTS.size()
	visible = HEIGHTS[_size_index] > 0
	custom_minimum_size.y = HEIGHTS[_size_index]
