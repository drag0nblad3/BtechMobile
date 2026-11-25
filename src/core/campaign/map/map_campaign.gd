class_name MapCampaign
extends RefCounted
## A map-based campaign (Campaign Operations pp. 142-155): the region, both
## rosters (Campaign objects hold 'Mechs, MechWarriors and damage), every
## lance on the map and the strategic turn count. The player's company of
## three lances lands on the south edge; the defender keeps a lance at
## each key location plus a reserve at the capital.

const PATH := "res://data/campaign/map_campaign.json"
const LANCE := 4
const LANCE_NAMES := ["Alpha", "Bravo", "Charlie", "Delta", "Echo"]

var rules: Dictionary = {}
var region: MapRegion
var player: Campaign
var enemy: Campaign
var lances: Array[MapLance] = []
var turn := 1
var battles: Array[Dictionary] = []  ## This turn's meetings still to fight (MapTurn).
var log: Array[String] = []
var scouted: Array[Vector2i] = []  ## Zones the invader's Scout orders saw this turn (MapFog).
var winner := -1
var operation := 1
var reports: Array[Dictionary] = []
var intel: Dictionary = {}  ## "x,y" -> last observed day and strength.


static func load_rules() -> Dictionary:
	return JsonFile.read(PATH)


static func create(db: UnitDb, rng: RandomNumberGenerator, rules_in: Dictionary = {}) -> MapCampaign:
	var mc := MapCampaign.new()
	mc.rules = rules_in if not rules_in.is_empty() else load_rules()
	mc.region = MapRegionGen.generate(mc.rules, rng)
	mc.player = Campaign.new()
	mc.player.name = "Kestrel's Irregulars"
	var ids: Array[String] = []
	for e: Dictionary in mc.rules.get("starting_company", []):
		var p := mc.player.add_pilot(String(e["pilot"]), int(e.get("gunnery", 4)), int(e.get("piloting", 5)))
		var m := mc.player.add_mech(String(e["design"]))
		m.pilot_id = p.id
		ids.append(m.id)
	var landing := Vector2i(mc.region.width / 2, mc.region.height - 1)
	for i in ceili(ids.size() / float(LANCE)):
		mc.add_lance(0, landing, ids.slice(i * LANCE, (i + 1) * LANCE))
	mc._enemy_forces(db, rng)
	MapOperations.observe(mc)
	return mc


## Lances of `side` still on the map.
func lances_of(side: int) -> Array[MapLance]:
	var out: Array[MapLance] = []
	for l in lances:
		if l.side == side:
			out.append(l)
	return out


func roster(side: int) -> Campaign:
	return player if side == 0 else enemy


func lance(id: String) -> MapLance:
	for l in lances:
		if l.id == id:
			return l
	return null


## 'Mechs of the lance that can fight now.
func fit_mechs(l: MapLance) -> Array[String]:
	var c := roster(l.side)
	var out: Array[String] = []
	for id in l.mech_ids:
		var m := c.mech(id)
		var p := c.pilot(m.pilot_id) if m != null else null
		if m != null and m.can_deploy() and p != null and p.can_fight():
			out.append(id)
	return out


## A new lance of `side` at `zone` (ids stay unique after lances are lost).
func add_lance(side: int, zone: Vector2i, ids: Array) -> MapLance:
	var l := MapLance.new()
	var n := lances_of(side).size()
	while lance("%s%d" % ["p" if side == 0 else "e", n + 1]) != null:
		n += 1
	l.id = "%s%d" % ["p" if side == 0 else "e", n + 1]
	l.name = ("%s Lance" % LANCE_NAMES[n % LANCE_NAMES.size()]) if side == 0 else "Defender Lance %d" % (n + 1)
	l.side = side
	l.zone = zone
	l.mech_ids.assign(ids)
	lances.append(l)
	return l


## A lance per key location, and reserves at the capital, sized near the
## player's average lance BV with official designs (EnemyForce).
func _enemy_forces(db: UnitDb, rng: RandomNumberGenerator) -> void:
	enemy = Campaign.new()
	enemy.name = "Defenders"
	var fb := ForceBuilder.new(db, ForceBuilder.BUDGETS.back())
	for m in player.mechs:
		fb.add(0, m.design)
	var target := fb.bv(0) / maxi(1, lances_of(0).size())
	var skill: Array = ChaosRules.load_file().data.get("skill_levels", {}).get(String(rules.get("enemy_skill", "regular")), [4, 5])
	fb.skills[1] = Vector2i(int(skill[0]), int(skill[1]))
	var spots: Array[Vector2i] = []
	for loc in region.locations:
		if bool(rules.get("locations", {}).get(loc["kind"], {}).get("garrison", true)):
			spots.append(loc["zone"])
	var capital: Vector2i = region.locations[0]["zone"]
	for i in int(rules.get("enemy_reserve_lances", 1)):
		spots.append(capital)
	for z in spots:
		var ids: Array[String] = []
		for d in EnemyForce.pick(fb, target, rng):
			var p := enemy.add_pilot("Defender %d" % (enemy.pilots.size() + 1), fb.skills[1].x, fb.skills[1].y)
			var m := enemy.add_mech(d)
			m.pilot_id = p.id
			ids.append(m.id)
		add_lance(1, z, ids)
