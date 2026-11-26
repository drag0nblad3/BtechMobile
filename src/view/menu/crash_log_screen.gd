class_name CrashLogScreen
extends Control
## Reports can be inspected and copied without permissions or automatic uploads.

var _report: TextEdit
var _status: Label
var _mode := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	UiSkin.backdrop(self)
	var box := UiKit.screen_body(self, "CRASH LOGS", UiKit.close_overlay.bind(self))
	UiKit.label(box, "Logs stay on this device. An interrupted session may be a crash, force stop or normal Android background process removal. Native crash stacks are not guaranteed.", 20)
	var tabs := HBoxContainer.new()
	box.add_child(tabs)
	for i in 3:
		var b := UiKit.button(tabs, ["LAST INTERRUPTED", "PREVIOUS SESSION", "CURRENT SESSION"][i], _select.bind(i), Vector2(0, 48))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 18)
	_report = TextEdit.new()
	_report.editable = false
	_report.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_report.custom_minimum_size.y = 300
	_report.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_report.add_theme_font_size_override("font_size", 16)
	box.add_child(_report)
	var footer := UiKit.screen_footer(box)
	_status = UiKit.label(footer, "", 18)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiKit.button(footer, "REFRESH", _select.bind(-1), Vector2(132, 56), "subtle")
	UiKit.button(footer, "COPY LOG", _copy, Vector2(180, 56), "primary").name = "CopyCrashLog"
	_select(0)


func _select(mode: int) -> void:
	if mode >= 0:
		_mode = mode
	var value := CrashMonitor.report(_mode)
	_report.text = value if not value.is_empty() else "No report recorded yet."
	_status.text = "Ready to copy" if not value.is_empty() else "No saved report"


func _copy() -> void:
	var value := CrashMonitor.report(_mode)
	if value.is_empty():
		return
	DisplayServer.clipboard_set(value)
	_status.text = "Copied. Paste into a message or bug report."
