class_name Campaign
extends RefCounted
## A mercenary company that lasts from battle to battle: its 'Mechs with
## their damage, its MechWarriors with wounds and experience, money, and a
## log of battles. Plain data; CampaignBattle moves it in and out of games.

var name := ""
var funds := 0
var battles := 0
var mechs: Array[CampaignMech] = []
var pilots: Array[CampaignPilot] = []
var log: Array[String] = []  ## One headline per battle.
var last_report: Array[String] = []  ## The latest after-action report.
var _next_id := 1


## A new company from the starting lance in the rules file.
static func create(rules: CampaignRules) -> Campaign:
	var c := Campaign.new()
	c.name = String(rules.data.get("company_name", "Mercenary Company"))
	c.funds = int(rules.data.get("starting_funds", 0))
	for entry: Dictionary in rules.starting_lance():
		var p := c.add_pilot(String(entry.get("pilot", "MechWarrior")),
				int(entry.get("gunnery", 4)), int(entry.get("piloting", 5)))
		c.add_mech(String(entry["design"])).pilot_id = p.id
	return c


func add_mech(design: String) -> CampaignMech:
	var m := CampaignMech.new()
	m.id = "m%d" % _take_id()
	m.design = design
	mechs.append(m)
	return m


func add_pilot(pilot_name: String, gunnery: int, piloting: int) -> CampaignPilot:
	var p := CampaignPilot.new()
	p.id = "p%d" % _take_id()
	p.name = pilot_name
	p.gunnery = gunnery
	p.piloting = piloting
	pilots.append(p)
	return p


func mech(id: String) -> CampaignMech:
	for m in mechs:
		if m.id == id:
			return m
	return null


func pilot(id: String) -> CampaignPilot:
	for p in pilots:
		if p.id == id:
			return p
	return null


## 'Mechs that can fight now: whole, with a MechWarrior fit to fight.
func ready_mechs() -> Array[CampaignMech]:
	var out: Array[CampaignMech] = []
	for m in mechs:
		var p := pilot(m.pilot_id)
		if m.can_deploy() and p != null and p.can_fight():
			out.append(m)
	return out


func _take_id() -> int:
	_next_id += 1
	return _next_id - 1


func to_dict() -> Dictionary:
	return {"version": 1, "name": name, "funds": funds, "battles": battles, "next_id": _next_id,
		"mechs": mechs.map(func(m: CampaignMech) -> Dictionary: return m.to_dict()),
		"pilots": pilots.map(func(p: CampaignPilot) -> Dictionary: return p.to_dict()),
		"log": Array(log), "last_report": Array(last_report)}


static func from_dict(d: Dictionary) -> Campaign:
	var c := Campaign.new()
	c.name = String(d.get("name", ""))
	c.funds = int(d.get("funds", 0))
	c.battles = int(d.get("battles", 0))
	c._next_id = int(d.get("next_id", 1))
	for m: Dictionary in d.get("mechs", []):
		c.mechs.append(CampaignMech.from_dict(m))
	for p: Dictionary in d.get("pilots", []):
		c.pilots.append(CampaignPilot.from_dict(p))
	for line in d.get("log", []):
		c.log.append(String(line))
	for line in d.get("last_report", []):
		c.last_report.append(String(line))
	return c
