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
static var voxel_mechs := true
## Presentation-only team paint preferences; not serialized into GameState.
static var paint_factions: Array[String] = ["federated_suns", "clan_wolf"]
static var sound_master := 0.85
static var sound_effects := 0.9
static var sound_ui := 0.65
static var sound_music := 0.35
static var radio_chatter := true
static var sound_muted := false
static var camera_shake := true
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
		voxel_mechs = bool(cfg.get_value("graphics", "voxel_mechs", true))
		var painted: Array = cfg.get_value("graphics", "paint_factions", [])
		for i in mini(2, painted.size()):
			if painted[i] is String and not String(painted[i]).is_empty():
				paint_factions[i] = String(painted[i])
		sound_master = clampf(float(cfg.get_value("audio", "master", 0.85)), 0.0, 1.0)
		sound_effects = clampf(float(cfg.get_value("audio", "effects", 0.9)), 0.0, 1.0)
		sound_ui = clampf(float(cfg.get_value("audio", "ui", 0.65)), 0.0, 1.0)
		sound_music = clampf(float(cfg.get_value("audio", "music", 0.35)), 0.0, 1.0)
		radio_chatter = bool(cfg.get_value("audio", "radio", true))
		sound_muted = bool(cfg.get_value("audio", "muted", false))
		camera_shake = bool(cfg.get_value("camera", "shake", true))


static func set_explain_level(level: int) -> void:
	explain_level = clampi(level, 0, 2)
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("explain", "level", explain_level)
	cfg.save(PATH)


## Records every training attempt, preserving prior wins and best practice.
static func record_training(id: String, result: Dictionary) -> void:
	var old: Dictionary = training.get(id, {})
	training[id] = TrainingCampaign.merge_result(old, result)
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


## Choose JSON voxel rigs, or use sprites and placeholders on slower phones.
static func set_voxel_mechs(enabled: bool) -> void:
	voxel_mechs = enabled
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("graphics", "voxel_mechs", enabled)
	cfg.save(PATH)


## Each side may select a historical faction and use its stylized livery.
static func paint_faction(side: int) -> String:
	return paint_factions[clampi(side, 0, paint_factions.size() - 1)]


static func set_paint_faction(side: int, faction: String) -> void:
	if side < 0 or side >= paint_factions.size() or faction.is_empty():
		return
	paint_factions[side] = faction
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("graphics", "paint_factions", paint_factions)
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


static func set_camera_shake(on: bool) -> void:
	camera_shake = on
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("camera", "shake", on)
	cfg.save(PATH)


## Cosmetic camera preference, independent of combat state and battle saves.
static func set_cinematic_camera(enabled: bool) -> void:
	cinematic_camera = enabled
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("camera", "cinematic", enabled)
	cfg.save(PATH)


static func set_sound_music(value: float) -> void:
	sound_music = clampf(value, 0.0, 1.0)
	_save_audio("music", sound_music)


static func set_radio_chatter(on: bool) -> void:
	radio_chatter = on
	_save_audio("radio", on)
