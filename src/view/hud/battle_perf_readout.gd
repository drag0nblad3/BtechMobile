class_name BattlePerfReadout
extends PanelContainer
## Opt-in live telemetry for Android visual QA. Disabled by default and
## refreshed only twice per second; this does not claim device performance.

const UPDATE_SECONDS := 0.5
var readout: Label
var _elapsed := 0.0


func _ready() -> void:
	name = "PerformanceReadout"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -266.0
	offset_right = -20.0
	offset_top = 152.0
	offset_bottom = 236.0
	add_theme_stylebox_override("panel", UiSkin.panel_style(Color("#0b202de8"), UiSkin.CYAN, 7, 5))
	readout = Label.new()
	readout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	readout.add_theme_font_size_override("font_size", 15)
	UiSkin.label(readout, "section")
	add_child(readout)
	_update_values()


func _process(delta: float) -> void:
	if not visible:
		return
	_elapsed += delta
	if _elapsed < UPDATE_SECONDS:
		return
	_elapsed = 0.0
	_update_values()


func _update_values() -> void:
	if readout == null:
		return
	var fps := Engine.get_frames_per_second()
	var cpu := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var shots := get_tree().get_nodes_in_group("battle_shot").size()
	var jets := get_tree().get_nodes_in_group("jump_fx").size()
	readout.text = "FPS %d   CPU %.1f ms\nShot FX %d   Jet FX %d" % [fps, cpu, shots, jets]
	readout.add_theme_color_override("font_color", UiSkin.RED if fps > 0 and fps < 30 else UiSkin.CYAN)
