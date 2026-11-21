class_name GameSettings
extends RefCounted
## Player preferences saved in user://settings.cfg (survives app restarts).
## The explanation level (ExplainLevel: full / light / off) and how well
## the computer plays (BotSkill.Level).

const PATH := "user://settings.cfg"

static var explain_level: int = ExplainLevel.FULL
static var ai_level: int = BotSkill.Level.REGULAR
static var _loaded := false


static func load_settings() -> void:
	if _loaded:
		return
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		explain_level = clampi(int(cfg.get_value("explain", "level", ExplainLevel.FULL)), 0, 2)
		ai_level = clampi(int(cfg.get_value("ai", "level", BotSkill.Level.REGULAR)), 0, BotSkill.NAMES.size() - 1)


static func set_explain_level(level: int) -> void:
	explain_level = clampi(level, 0, 2)
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("explain", "level", explain_level)
	cfg.save(PATH)


static func set_ai_level(level: int) -> void:
	ai_level = clampi(level, 0, BotSkill.NAMES.size() - 1)
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("ai", "level", ai_level)
	cfg.save(PATH)
