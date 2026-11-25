class_name CampaignStore
extends RefCounted
## Saves the company to user://campaign.json, with the battle it is in the
## middle of ({unit id: company 'Mech id}), so a battle saved and resumed
## later still writes back to the company.

const PATH := "user://campaign.json"


static func exists(path: String = PATH) -> bool:
	return FileAccess.file_exists(SaveProfiles.resolve(path))


static func load_company(path: String = PATH) -> Campaign:
	if not exists(path):
		return null
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(SaveProfiles.resolve(path)))
	return Campaign.from_dict(d) if d is Dictionary else null


static func save(c: Campaign, roster: Dictionary = {}, path: String = PATH) -> bool:
	var d := c.to_dict()
	if not roster.is_empty():
		var r := {}
		for uid: int in roster:
			r[str(uid)] = roster[uid]
		d["battle"] = r
	var f := FileAccess.open(SaveProfiles.resolve(path), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(d, "  "))
	return true


## The battle the company is fighting: {unit id: 'Mech id}, or {}.
static func pending_roster(path: String = PATH) -> Dictionary:
	if not exists(path):
		return {}
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(SaveProfiles.resolve(path)))
	var out := {}
	if d is Dictionary:
		var r: Dictionary = d.get("battle", {})
		for k: String in r:
			out[int(k)] = String(r[k])
	return out


## Forgets an unfinished company battle (its autosave was replaced): the
## contract is abandoned, its cost already paid.
static func drop_pending(path: String = PATH) -> void:
	var c := load_company(path)
	if c != null and not pending_roster(path).is_empty():
		c.contract = null
		c.offers.clear()
		save(c, {}, path)


## Writes a finished battle back and saves. Returns the after-action report.
static func finish(state: GameState, player_side: int, winner: int, frames: Array,
		path: String = PATH) -> String:
	var c := load_company(path)
	var roster := pending_roster(path)
	if c == null or roster.is_empty():
		return ""
	var kills := CampaignBattle.kill_credit_from_frames(frames)
	var report := CampaignBattle.finish(c, state, roster, winner == player_side, kills,
			ChaosRules.load_file(), player_side)
	c.offers.clear()  # a new board after every contract
	save(c, {}, path)
	return "\n".join(report)


static func delete(path: String = PATH) -> void:
	if exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveProfiles.resolve(path)))
