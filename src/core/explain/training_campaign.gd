class_name TrainingCampaign
extends RefCounted
## The training campaign: connected training games, each opening with a
## scripted set-up and lessons for the rules it introduces, then played out
## freely against the computer. Core rules come first; smaller rules wait for
## later games. Data: data/training/campaign.json. Progress is a Dictionary
## {mission id: {"won": bool, "kills": int}} that the view saves.

const PATH := "res://data/training/campaign.json"

var name := ""
var intro := ""
var missions: Array[Dictionary] = []


static func load_file(path: String = PATH) -> TrainingCampaign:
	var c := TrainingCampaign.new()
	var data: Dictionary = JsonFile.read(path)
	c.name = data.get("name", "")
	c.intro = data.get("intro", "")
	for m: Dictionary in data.get("missions", []):
		c.missions.append(m)
	return c


func index_of(id: String) -> int:
	for i in missions.size():
		if missions[i].get("id", "") == id:
			return i
	return -1


## A mission opens once the one before it has been played (won or lost).
func unlocked(i: int, progress: Dictionary) -> bool:
	return i == 0 or (i > 0 and i < missions.size() and progress.has(missions[i - 1]["id"]))


## First unplayed mission, or the last one when all are done.
func next_index(progress: Dictionary) -> int:
	for i in missions.size():
		if not progress.has(missions[i]["id"]):
			return i
	return missions.size() - 1


func finished(progress: Dictionary) -> bool:
	for m in missions:
		if not progress.has(m["id"]):
			return false
	return true


func scenario_path(i: int) -> String:
	return "res://data/scenarios/%s.json" % missions[i]["scenario"]


## Result of a finished training battle for the player's side.
## `winner` comes from the GAME_OVER event.
static func result(s: GameState, player_side: int, winner: int) -> Dictionary:
	var kills := 0
	for u in s.units:
		if u.side != player_side and u.destroyed:
			kills += 1
	return {"won": winner == player_side, "kills": kills}


## Keep the best result without losing retry counts or earlier victories.
## Old records had only won/kills; treat those as one prior attempt.
static func merge_result(previous: Dictionary, result: Dictionary) -> Dictionary:
	var old_attempts := int(previous.get("attempts", 0 if previous.is_empty() else 1))
	var old_wins := int(previous.get("wins", 1 if previous.get("won", false) else 0))
	return {
		"won": bool(previous.get("won", false)) or bool(result.get("won", false)),
		"kills": maxi(int(previous.get("kills", 0)), int(result.get("kills", 0))),
		"attempts": old_attempts + 1,
		"wins": old_wins + (1 if result.get("won", false) else 0),
		"practice": maxi(int(previous.get("practice", 0)), int(result.get("practice", 0))),
		"practice_total": int(result.get("practice_total", previous.get("practice_total", 0))),
	}


## Debrief after a mission: story text plus the cadet's running record.
func debrief(i: int, won: bool, progress: Dictionary) -> String:
	var m := missions[i]
	var text: String = m.get("debrief_win" if won else "debrief_loss", "")
	var wins := 0
	var kills := 0
	var attempts := 0
	for id: String in progress:
		wins += 1 if progress[id].get("won", false) else 0
		kills += int(progress[id].get("kills", 0))
		attempts += int(progress[id].get("attempts", 1))
	text += "\n\nCadet record: %d of %d missions won, %d attempts, %d best enemy kills across missions." % [wins, missions.size(), attempts, kills]
	if i + 1 < missions.size():
		text += "\nNext: %s." % missions[i + 1]["title"]
	return text


## The rules notebook: every lesson of the missions played so far, grouped
## by mission, so a learner can reread them. [{mission, title, text}]
func notebook(progress: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in missions.size():
		if not progress.has(missions[i]["id"]):
			continue
		for l: Dictionary in Tutorial.from_scenario(scenario_path(i)).lessons:
			if l.get("event", "") != "game_over":
				out.append({"mission": missions[i]["title"], "title": l.get("title", ""), "text": l.get("text", "")})
	return out
