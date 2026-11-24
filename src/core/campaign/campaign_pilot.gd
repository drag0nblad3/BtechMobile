class_name CampaignPilot
extends RefCounted
## A MechWarrior in the company: skills, wounds and record carried from
## battle to battle. Lower skill numbers are better.

var id := ""
var name := "MechWarrior"
var gunnery := 4
var piloting := 5
var wounds := 0  ## Pilot hits still unhealed (Pilot.MAX_HITS kills).
var xp := 0
var kills := 0
var battles := 0
var dead := false


func can_fight() -> bool:
	return not dead and wounds < Pilot.MAX_HITS


## A battle Pilot for this warrior, starting with today's wounds.
func to_pilot() -> Pilot:
	var p := Pilot.new(gunnery, piloting)
	p.name = name
	p.hits = wounds
	return p


func to_dict() -> Dictionary:
	return {"id": id, "name": name, "gunnery": gunnery, "piloting": piloting, "wounds": wounds,
		"xp": xp, "kills": kills, "battles": battles, "dead": dead}


static func from_dict(d: Dictionary) -> CampaignPilot:
	var p := CampaignPilot.new()
	p.id = String(d.get("id", ""))
	p.name = String(d.get("name", p.name))
	p.gunnery = int(d.get("gunnery", p.gunnery))
	p.piloting = int(d.get("piloting", p.piloting))
	p.wounds = int(d.get("wounds", 0))
	p.xp = int(d.get("xp", 0))
	p.kills = int(d.get("kills", 0))
	p.battles = int(d.get("battles", 0))
	p.dead = bool(d.get("dead", false))
	return p
