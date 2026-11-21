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


## Debrief after a mission: story text plus the cadet's running record.
func debrief(i: int, won: bool, progress: Dictionary) -> String:
	var m := missions[i]
	var text: String = m.get("debrief_win" if won else "debrief_loss", "")
	var wins := 0
	var kills := 0
	for id: String in progress:
		wins += 1 if progress[id].get("won", false) else 0
		kills += int(progress[id].get("kills", 0))
	text += "\n\nCadet record: %d of %d missions won, %d enemy 'Mechs destroyed." % [wins, missions.size(), kills]
	if i + 1 < missions.size():
		text += "\nNext: %s." % missions[i + 1]["title"]
	return text
