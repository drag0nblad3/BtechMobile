class_name SaveProfiles
extends RefCounted
## Independent local save workspaces. Slot 1 keeps the original files;
## battle, replay and both campaign types always travel in the same workspace.
const COUNT := 5
const CONFIG := "user://save_slots.cfg"
const FILES := ["battle_autosave.zst", "last_battle_replay.zst", "campaign.json", "map_campaign.json"]
static var _active := -1


static func active() -> int:
	if _active < 0:
		var cfg := ConfigFile.new()
		cfg.load(CONFIG)
		_active = clampi(int(cfg.get_value("slots", "active", 0)), 0, COUNT - 1)
	return _active


static func select(slot: int) -> bool:
	if slot < 0 or slot >= COUNT:
		return false
	var cfg := ConfigFile.new()
	cfg.load(CONFIG)
	cfg.set_value("slots", "active", slot)
	if cfg.save(CONFIG) != OK:
		return false
	_active = slot
	return true


static func path_for(path: String, slot: int) -> String:
	# Explicit test paths and other settings are not redirected.
	if slot <= 0 or not path.begins_with("user://") or not FILES.has(path.trim_prefix("user://")):
		return path
	return "user://slot_%d_%s" % [slot + 1, path.get_file()]


static func resolve(path: String) -> String:
	return path_for(path, active())


static func contents(slot: int) -> String:
	var found: Array[String] = []
	var names := ["Battle", "Replay", "Campaign", "Map campaign"]
	for i in FILES.size():
		if FileAccess.file_exists(path_for("user://" + FILES[i], slot)):
			found.append(names[i])
	return "Empty" if found.is_empty() else ", ".join(found)
