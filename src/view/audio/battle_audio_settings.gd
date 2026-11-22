class_name BattleAudioSettings
extends VBoxContainer
## Compact touch settings for the paused battle; all preferences use user://.

func _ready() -> void:
	add_theme_constant_override("separation", 4)
	var label := Label.new()
	label.text = "AUDIO"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	_slider("Master", GameSettings.sound_master, GameSettings.set_sound_master)
	_slider("Effects", GameSettings.sound_effects, GameSettings.set_sound_effects)
	_slider("UI", GameSettings.sound_ui, GameSettings.set_sound_ui)
	var muted := CheckButton.new()
	muted.text = "Mute all sound"
	muted.button_pressed = GameSettings.sound_muted
	muted.toggled.connect(GameSettings.set_sound_muted)
	add_child(muted)


func _slider(caption: String, level: float, setter: Callable) -> void:
	var line := HBoxContainer.new()
	add_child(line)
	var label := Label.new()
	label.text = caption
	label.custom_minimum_size.x = 95
	line.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = level
	slider.custom_minimum_size = Vector2(290, 30)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(setter)
	line.add_child(slider)
