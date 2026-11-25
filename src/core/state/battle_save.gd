class_name BattleSave
extends RefCounted
## Compressed autosave and last-battle replay in the active save profile.
## Saves contain data only; no arbitrary Godot objects/scripts are loaded.

const VERSION := 2
const LEGACY_VERSION := 1
const SAVE_PATH := "user://battle_autosave.zst"
const REPLAY_PATH := "user://last_battle_replay.zst"


static func capture(c: GameController, bots: Array, skill: int,
		training: int, frames: Array, tutorial_path: String = "") -> Dictionary:
	return {"schema": VERSION, "state": BattleCodec.pack(c.state),
			"seed": str(c.dice._rng.seed), "rng": str(c.dice._rng.state),
			"history": BattleCodec.pack(c.history), "bots": bots.duplicate(),
			"skill": skill, "training": training, "tutorial": tutorial_path,
			"frames": frames.duplicate(), "finished": c.state.game_over}


static func restore(d: Dictionary, db: UnitDb, terrain: TerrainDb) -> Dictionary:
	if not _supported(d) or not d.has("state") \
			or not d.has("seed") or not d.has("rng"):
		return {}
	var s: GameState = BattleCodec.unpack(d["state"], db, terrain)
	if s == null:
		return {}
	var c := GameController.new(s, 1)
	c.dice._rng.seed = int(String(d["seed"]))
	c.dice._rng.state = int(String(d["rng"]))
	if d.has("history"):
		var entries: Array = BattleCodec.unpack(d["history"], db, terrain)
		c.history.assign(entries)
	return {"controller": c, "bots": d.get("bots", []),
			"skill": int(d.get("skill", BotSkill.Level.REGULAR)),
			"training": int(d.get("training", -1)),
			"tutorial": String(d.get("tutorial", "")),
			"frames": d.get("frames", [])}


static func save_game(c: GameController, bots: Array, skill: int,
		training: int, frames: Array, tutorial_path: String = "") -> bool:
	return _write(SAVE_PATH, capture(c, bots, skill, training, frames, tutorial_path))


static func load_game() -> Dictionary:
	var d := _read(SAVE_PATH)
	if d.is_empty():
		return {}
	return restore(d, UnitDb.load_dir(), TerrainDb.load_file())


static func has_game() -> bool:
	var d := _read(SAVE_PATH)
	return d.has("state") and not bool(d.get("finished", false)) \
			and not bool(d.get("game_over", false))


static func save_replay(frames: Array) -> bool:
	if frames.is_empty():
		return false
	return _write(REPLAY_PATH, {"schema": VERSION, "frames": frames})


static func load_replay() -> Array:
	var d := _read(REPLAY_PATH)
	return d.get("frames", [])


static func has_replay() -> bool:
	return FileAccess.file_exists(SaveProfiles.resolve(REPLAY_PATH))


static func _write(path: String, data: Dictionary) -> bool:
	path = SaveProfiles.resolve(path)
	var tmp := path + ".tmp"
	var file := FileAccess.open_compressed(tmp, FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	if file == null:
		push_error("Cannot write battle save: " + str(FileAccess.get_open_error()))
		return false
	var payload := data.duplicate()
	if int(payload.get("schema", -1)) == VERSION and payload.get("frames") is Array:
		payload["frames"] = BattleFrameStorage.encode(payload["frames"])
		payload["frame_encoding"] = "property_delta"
	file.store_string(JSON.stringify(payload))
	file.flush()
	file = null
	var err := DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp),
			ProjectSettings.globalize_path(path))
	if err != OK:
		push_error("Cannot replace battle save: " + str(err))
	return err == OK


static func _read(path: String) -> Dictionary:
	path = SaveProfiles.resolve(path)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open_compressed(path, FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or not _supported(parsed):
		return {}
	if parsed.get("frame_encoding", "") == "property_delta":
		var encoded: Array = parsed.get("frames", [])
		var decoded := BattleFrameStorage.decode(encoded)
		if decoded.size() != encoded.size():
			return {}
		parsed["frames"] = decoded
		parsed.erase("frame_encoding")
	return parsed


static func _supported(data: Dictionary) -> bool:
	return int(data.get("schema", -1)) in [LEGACY_VERSION, VERSION]
