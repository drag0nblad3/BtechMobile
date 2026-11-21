class_name GameSettings
extends RefCounted
## Player preferences saved in user://settings.cfg (survives app restarts).
## The explanation level (ExplainLevel: full / light / off) and training
## campaign progress ({mission id: {won, kills}}, see TrainingCampaign).

const PATH := "user://settings.cfg"

static var explain_level: int = ExplainLevel.FULL
static var training: Dictionary = {}
static var _loaded := false


static func load_settings() -> void:
	if _loaded:
		return
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		explain_level = clampi(int(cfg.get_value("explain", "level", ExplainLevel.FULL)), 0, 2)
		training = cfg.get_value("training", "progress", {})


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
