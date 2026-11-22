class_name GameSettings
extends RefCounted
## Player preferences saved in user://settings.cfg (survives app restarts).
## The explanation level (ExplainLevel: full / light / off), how well the
## computer plays (BotSkill.Level) and training campaign progress
## ({mission id: {won, kills}}, see TrainingCampaign).

const PATH := "user://settings.cfg"

static var explain_level: int = ExplainLevel.FULL
static var training: Dictionary = {}
static var ai_level: int = BotSkill.Level.REGULAR
static var cinematic_camera := false
static var sound_master := 0.85
static var sound_effects := 0.9
static var sound_ui := 0.65
static var sound_muted := false
static var _loaded := false


static func load_settings() -> void:
	if _loaded:
		return
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		explain_level = clampi(int(cfg.get_value("explain", "level", ExplainLevel.FULL)), 0, 2)
		training = cfg.get_value("training", "progress", {})
		ai_level = clampi(int(cfg.get_value("ai", "level", BotSkill.Level.REGULAR)), 0, BotSkill.NAMES.size() - 1)
		cinematic_camera = bool(cfg.get_value("camera", "cinematic", false))
		sound_master = clampf(float(cfg.get_value("audio", "master", 0.85)), 0.0, 1.0)
		sound_effects = clampf(float(cfg.get_value("audio", "effects", 0.9)), 0.0, 1.0)
		sound_ui = clampf(float(cfg.get_value("audio", "ui", 0.65)), 0.0, 1.0)
		sound_muted = bool(cfg.get_value("audio", "muted", false))


static func set_explain_level(level: int) -> void:
	explain_level = clampi(level, 0, 2)
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("explain", "level", explain_level)
	cfg.save(PATH)


## Records a played training mission; a win is never overwritten by a loss.
static func record_training(id: String, result: Dictionary) -> void:
	var old: Dictionary = training.get(id, {})
	if old.get("won", false) and not result.get("won", false):
		return
	training[id] = result
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("training", "progress", training)
	cfg.save(PATH)


static func set_ai_level(level: int) -> void:
	ai_level = clampi(level, 0, BotSkill.NAMES.size() - 1)
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("ai", "level", ai_level)
	cfg.save(PATH)


static func set_sound_master(value: float) -> void:
	sound_master = clampf(value, 0.0, 1.0)
	_save_audio("master", sound_master)


static func set_sound_effects(value: float) -> void:
	sound_effects = clampf(value, 0.0, 1.0)
	_save_audio("effects", sound_effects)


static func set_sound_ui(value: float) -> void:
	sound_ui = clampf(value, 0.0, 1.0)
	_save_audio("ui", sound_ui)


static func set_sound_muted(on: bool) -> void:
	sound_muted = on
	_save_audio("muted", on)


static func _save_audio(key: String, value: Variant) -> void:
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("audio", key, value)
	cfg.save(PATH)


## Cosmetic camera preference, independent of combat state and battle saves.
static func set_cinematic_camera(enabled: bool) -> void:
	cinematic_camera = enabled
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("camera", "cinematic", enabled)
	cfg.save(PATH)
