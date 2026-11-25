class_name BattleLoading
extends CanvasLayer
## Main-thread loading feedback. Stage values measure completed work, not time.
## Yield two frames so the new label is drawn before expensive work begins.

static var force_staged := false  ## Dedicated headless smoke uses the real staged path.
var stage := 0.0
var status: Label
var bar: ProgressBar
var heading := "DEPLOYMENT  /  PREPARING BATTLE"


static func staged() -> bool:
	return force_staged or DisplayServer.get_name() != "headless"


func _ready() -> void:
	layer = 100
	var bg := ColorRect.new()
	bg.color = UiSkin.BACKGROUND
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 560
	UiSkin.panel(panel, "info")
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	panel.add_child(column)
	var title := Label.new()
	title.text = heading
	title.add_theme_font_size_override("font_size", 28)
	UiSkin.label(title, "heading")
	column.add_child(title)
	status = Label.new()
	status.text = "Preparing deployment…"
	status.add_theme_font_size_override("font_size", 22)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiSkin.label(status, "body")
	column.add_child(status)
	bar = ProgressBar.new()
	bar.custom_minimum_size.y = 22
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", UiSkin.panel_style(UiSkin.SURFACE_HIGH, UiSkin.BORDER, 0, 4))
	bar.add_theme_stylebox_override("fill", UiSkin.panel_style(UiSkin.CYAN, UiSkin.CYAN, 0, 4))
	column.add_child(bar)
	var note := Label.new()
	note.text = "Combat begins once deployment is ready."
	UiSkin.label(note, "muted")
	column.add_child(note)


func step(message: String, completed: float) -> void:
	stage = maxf(stage, clampf(completed, 0.0, 100.0))
	status.text = message
	bar.value = stage
	if staged():
		await get_tree().process_frame
		await get_tree().process_frame
