extends TestCase
## Visual style tokens remain usable by every screen without a scene tree.


func test_primary_action_has_amber_frame() -> void:
	var button := Button.new()
	UiSkin.button(button, "primary")
	var normal := button.get_theme_stylebox("normal") as StyleBoxFlat
	check(normal != null, "primary button has a StyleBoxFlat")
	check_eq(normal.border_color, UiSkin.AMBER, "primary action border")
	button.free()


func test_panel_retains_readable_padding() -> void:
	var p := PanelContainer.new()
	UiSkin.panel(p)
	var style := p.get_theme_stylebox("panel") as StyleBoxFlat
	check(style != null, "panel has a style")
	check(style.content_margin_left >= 12, "touchable content margin")
	p.free()


func test_disabled_button_is_not_accented() -> void:
	var b := Button.new()
	UiSkin.button(b, "primary")
	var disabled := b.get_theme_stylebox("disabled") as StyleBoxFlat
	check(disabled.border_color != UiSkin.AMBER, "disabled buttons must not look active")
	b.free()
