class_name Campaign
extends RefCounted
## A mercenary company that lasts from battle to battle: its 'Mechs with
## their damage, its MechWarriors with wounds and records, and a
## log of battles, its Warchest, Support Points and current contract. Plain data;
## CampaignBattle moves it in and out of games.

var name := ""
var wp := 0  ## Warchest Points (Chaos Campaign).
var on_debt := false  ## The last contract was taken on Warchest debt.
var contract: Contract = null  ## The contract being fought, if any.
var offers: Array[Contract] = []  ## Contracts on the board now.
var last_met := 0  ## Objectives met in the last contract (salvage needs one).
var sp := 0  ## Support Points (optional rule, pp. 161-164).
var size_mod := 1  ## Base Force Size Modifier: lances at creation, fixed.
var month := 1  ## Campaign months; each stop between contracts is one.
var converted := 0  ## WP turned into SP this month (at most 100).
var done: Array[String] = []  ## Once-a-month jobs done: "train:<pilot>:g", "heal:<pilot>".
var battles := 0
var mechs: Array[CampaignMech] = []
var pilots: Array[CampaignPilot] = []
var log: Array[String] = []  ## One headline per battle.
var last_report: Array[String] = []  ## The latest after-action report.
var _next_id := 1


## A new company from the starting lance in the rules file.
static func create(rules: CampaignRules, chaos: ChaosRules = null) -> Campaign:
	var c := Campaign.new()
	c.name = String(rules.data.get("company_name", "Mercenary Company"))
	c.wp = chaos.starting_wp() if chaos != null else 0
	var lance := maxi(1, chaos.sp("lance_size")) if chaos != null else 4
	c.size_mod = maxi(1, ceili(rules.starting_lance().size() / float(lance)))
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


## Living MechWarriors with no 'Mech of their own (hired, or theirs is lost).
func free_pilots() -> Array[CampaignPilot]:
	var out: Array[CampaignPilot] = []
	for p in pilots:
		if p.dead:
			continue
		var seated := false
		for m in mechs:
			seated = seated or (m.pilot_id == p.id and not m.written_off)
		if not seated:
			out.append(p)
	return out


func _take_id() -> int:
	_next_id += 1
	return _next_id - 1


func to_dict() -> Dictionary:
	return {"version": 3, "name": name, "wp": wp, "on_debt": on_debt, "last_met": last_met,
		"sp": sp, "size_mod": size_mod, "month": month, "converted": converted, "done": Array(done),
		"contract": contract.to_dict() if contract != null else {},
		"offers": offers.map(func(k: Contract) -> Dictionary: return k.to_dict()), "battles": battles, "next_id": _next_id,
		"mechs": mechs.map(func(m: CampaignMech) -> Dictionary: return m.to_dict()),
		"pilots": pilots.map(func(p: CampaignPilot) -> Dictionary: return p.to_dict()),
		"log": Array(log), "last_report": Array(last_report)}


static func from_dict(d: Dictionary) -> Campaign:
	var c := Campaign.new()
	c.name = String(d.get("name", ""))
	c.wp = int(d.get("wp", 0))
	c.on_debt = bool(d.get("on_debt", false))
	c.last_met = int(d.get("last_met", 0))
	c.sp = int(d.get("sp", 0))
	c.month = int(d.get("month", 1))
	c.converted = int(d.get("converted", 0))
	for k in d.get("done", []):
		c.done.append(String(k))
	var k: Dictionary = d.get("contract", {})
	c.contract = Contract.from_dict(k) if not k.is_empty() else null
	for o: Dictionary in d.get("offers", []):
		c.offers.append(Contract.from_dict(o))
	c.battles = int(d.get("battles", 0))
	c._next_id = int(d.get("next_id", 1))
	for m: Dictionary in d.get("mechs", []):
		c.mechs.append(CampaignMech.from_dict(m))
	for p: Dictionary in d.get("pilots", []):
		c.pilots.append(CampaignPilot.from_dict(p))
	c.size_mod = int(d.get("size_mod", maxi(1, ceili(c.mechs.size() / 4.0))))
	for line in d.get("log", []):
		c.log.append(String(line))
	for line in d.get("last_report", []):
		c.last_report.append(String(line))
	return c
