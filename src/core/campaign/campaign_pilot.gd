class_name CampaignPilot
extends RefCounted
## A MechWarrior in the company: skills, wounds and record carried from
## battle to battle. Lower skill numbers are better.

var id := ""
var name := "MechWarrior"
var gunnery := 4
var piloting := 5
var wounds := 0  ## Pilot hits still unhealed (Pilot.MAX_HITS kills).
var kills := 0
var battles := 0
var fought_last := false  ## Fought in the last contract (cheaper skill training).
var dead := false
var abilities: Array[String] = []  ## Special Pilot Abilities ("id" or "id:choice"; SpaShop).
var spa_month := -99  ## Campaign month of the last ability learned.


func can_fight() -> bool:
	return not dead and wounds < Pilot.MAX_HITS


## A battle Pilot for this warrior, starting with today's wounds.
func to_pilot() -> Pilot:
	var p := Pilot.new(gunnery, piloting)
	p.name = name
	p.hits = wounds
	for a in abilities:
		Spa.grant(p, a.get_slice(":", 0), 1, a.get_slice(":", 1) if a.contains(":") else "")
	return p


func to_dict() -> Dictionary:
	return {"id": id, "name": name, "gunnery": gunnery, "piloting": piloting, "wounds": wounds,
		"kills": kills, "battles": battles, "fought_last": fought_last, "dead": dead,
		"abilities": Array(abilities), "spa_month": spa_month}


static func from_dict(d: Dictionary) -> CampaignPilot:
	var p := CampaignPilot.new()
	p.id = String(d.get("id", ""))
	p.name = String(d.get("name", p.name))
	p.gunnery = int(d.get("gunnery", p.gunnery))
	p.piloting = int(d.get("piloting", p.piloting))
	p.wounds = int(d.get("wounds", 0))
	p.kills = int(d.get("kills", 0))
	p.battles = int(d.get("battles", 0))
	p.fought_last = bool(d.get("fought_last", false))
	p.dead = bool(d.get("dead", false))
	for a in d.get("abilities", []):
		p.abilities.append(String(a))
	p.spa_month = int(d.get("spa_month", -99))
	return p
