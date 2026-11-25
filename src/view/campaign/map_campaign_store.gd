class_name MapCampaignStore
extends RefCounted
## Saves the map campaign to user://map_campaign.json, with the battle it is
## in the middle of (its index in this turn's meetings and both rosters,
## {unit id: 'Mech id}), so a saved and resumed battle still writes back.

const PATH := "user://map_campaign.json"


static func exists(path: String = PATH) -> bool:
	return FileAccess.file_exists(SaveProfiles.resolve(path))


static func _read(path: String) -> Dictionary:
	if not exists(path):
		return {}
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(SaveProfiles.resolve(path)))
	return d if d is Dictionary else {}


static func load_campaign(path: String = PATH) -> MapCampaign:
	var d := _read(path)
	return MapCampaignCodec.unpack(d["campaign"]) if d.has("campaign") else null


## `pending` is {index, rosters: [{uid: id}, {uid: id}]} or {}.
static func save(mc: MapCampaign, pending: Dictionary = {}, path: String = PATH) -> bool:
	var d := {"campaign": MapCampaignCodec.pack(mc)}
	if not pending.is_empty():
		var rs := []
		for r: Dictionary in pending["rosters"]:
			var out := {}
			for uid: int in r:
				out[str(uid)] = r[uid]
			rs.append(out)
		d["pending"] = {"index": int(pending["index"]), "rosters": rs}
	var f := FileAccess.open(SaveProfiles.resolve(path), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(d, "  "))
	return true


## The battle being fought: {index, rosters} with int unit ids, or {}.
static func pending(path: String = PATH) -> Dictionary:
	var p: Dictionary = _read(path).get("pending", {})
	if p.is_empty():
		return {}
	var rs: Array = []
	for r: Dictionary in p.get("rosters", []):
		var out := {}
		for k: String in r:
			out[int(k)] = String(r[k])
		rs.append(out)
	return {"index": int(p.get("index", 0)), "rosters": rs}


## Its autosave was replaced: the meeting stays on the list, to fight again.
static func drop_pending(path: String = PATH) -> void:
	var mc := load_campaign(path)
	if mc != null and not pending(path).is_empty():
		save(mc, {}, path)


## Writes a finished battle back; ends the turn when no meeting is left.
## Returns the after-action report.
static func finish(state: GameState, winner: int, frames: Array, path: String = PATH) -> String:
	var mc := load_campaign(path)
	var p := pending(path)
	if mc == null or p.is_empty() or int(p["index"]) >= mc.battles.size():
		return ""
	var kills := CampaignBattle.kill_credit_from_frames(frames)
	var report := MapBattle.finish(mc, mc.battles[int(p["index"])], state, p["rosters"], winner, kills)
	if mc.battles.is_empty():
		report.append_array(MapTurn.finish(mc, UnitDb.load_dir()))
	save(mc, {}, path)
	return "\n".join(report)


static func delete(path: String = PATH) -> void:
	if exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveProfiles.resolve(path)))
