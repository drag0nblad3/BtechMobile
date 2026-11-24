class_name CampaignBattle
extends RefCounted
## Moves the company in and out of a battle. `prepare` puts each deployed
## 'Mech's damage and MechWarrior onto the units a ForceBuilder made for
## them; `finish` writes the battle back: damage, wounds, deaths, kills and
## experience, and returns an after-action report. Experience and healing
## numbers are the app's own (CampaignRules). TODO(rules)

## Reasons a unit left the map without being wrecked.
const LEFT_MAP := ["left the battlefield", "scattered off the battlefield", "pushed off the battlefield"]
const PILOT_KILLED := ["MechWarrior killed", "head destroyed", "cockpit destroyed", "cockpit flooded"]
const SURRENDERED := "surrendered: it couldn't withdraw"


## Designs to put in the ForceBuilder roster, in deploy order.
static func designs(c: Campaign, mech_ids: Array) -> Array[String]:
	var out: Array[String] = []
	for id: String in mech_ids:
		out.append(c.mech(id).design)
	return out


## Matches each of `mech_ids` to a unit of its design on `side` and applies
## each one's damage and pilot. Returns {unit id: campaign mech id}.
static func prepare(c: Campaign, state: GameState, side: int, mech_ids: Array) -> Dictionary:
	var roster := {}
	var used := {}
	for id: String in mech_ids:
		var m := c.mech(id)
		for u in state.all_units():
			if m != null and u.side == side and not used.has(u.id) and u.def.id == m.design:
				MechCondition.apply(u, m.condition)
				u.pilot = c.pilot(m.pilot_id).to_pilot()
				roster[u.id] = m.id
				used[u.id] = true
				break
	return roster


## Who gets credit for each kill: the last unit to damage it.
## `events` is the battle's GameEvents. Returns {killer unit id: kills}.
static func kill_credit(events: Array) -> Dictionary:
	var last_hit := {}
	var kills := {}
	for e: GameEvent in events:
		if e.type == GameEvent.DAMAGE and int(e.data.get("source_id", -1)) >= 0:
			last_hit[int(e.data["unit_id"])] = int(e.data["source_id"])
		elif e.type == GameEvent.UNIT_DESTROYED and last_hit.has(int(e.data["unit_id"])):
			var k: int = last_hit[int(e.data["unit_id"])]
			kills[k] = int(kills.get(k, 0)) + 1
	return kills


## The same from a BattleRecorder's frames (survives saving mid-battle).
static func kill_credit_from_frames(frames: Array) -> Dictionary:
	var events: Array = []
	for f: Dictionary in frames:
		for fact: Dictionary in f.get("events", []):
			events.append(GameEvent.new(StringName(fact.get("event", "")), fact.get("data", {})))
	return kill_credit(events)


## Writes a finished battle back into the company. Returns report lines.
static func finish(c: Campaign, rules: CampaignRules, state: GameState, roster: Dictionary,
		won: bool, kills: Dictionary = {}) -> Array[String]:
	var report: Array[String] = []
	c.battles += 1
	report.append("Battle %d: %s." % [c.battles, "victory" if won else "defeat"])
	for uid: int in roster:
		var u := state.unit_by_id(uid)
		var m := c.mech(roster[uid])
		if u == null or m == null:
			continue
		var p := c.pilot(m.pilot_id)
		report.append(_mech_result(u, m, p.name if p != null else "Unassigned"))
		if p != null:
			report.append(_pilot_result(rules, u, p, won, int(kills.get(uid, 0))))
	var heal := rules.wounds_healed()
	var healed := 0
	for p in c.pilots:
		if not p.dead and p.wounds > 0 and heal > 0:
			p.wounds = maxi(0, p.wounds - heal)
			healed += 1
	if healed > 0:
		report.append("Between battles each MechWarrior heals %d wound%s." % [heal, "" if heal == 1 else "s"])
	c.log.append(report[0])
	c.last_report = report.duplicate()
	return report


static func _mech_result(u: Unit, m: CampaignMech, pilot_name: String) -> String:
	var who := "%s's %s" % [pilot_name, ("%s %s" % [u.def.name, u.def.model]).strip_edges()]
	m.condition = MechCondition.lasting(u)
	if u.destroyed and u.destroyed_reason in LEFT_MAP:
		m.condition["destroyed"] = false
		m.condition["destroyed_reason"] = ""
	if u.destroyed_reason == SURRENDERED:
		m.written_off = true
		return "%s surrendered and is lost to the enemy." % who
	if MechCondition.written_off(m.condition):
		m.written_off = true
		return "%s is a write-off: its center torso is gone." % who
	if bool(m.condition.get("destroyed", false)):
		return "%s was knocked out (%s) but can be rebuilt." % [who, u.destroyed_reason]
	if m.condition.is_empty():
		return "%s came back without a scratch." % who
	return "%s needs repairs." % who


static func _pilot_result(rules: CampaignRules, u: Unit, p: CampaignPilot, won: bool, kills: int) -> String:
	p.battles += 1
	p.kills += kills
	p.wounds = u.pilot.hits
	if u.pilot.is_dead() or (u.destroyed and u.destroyed_reason in PILOT_KILLED):
		p.dead = true
		p.wounds = Pilot.MAX_HITS
		return "%s was killed in action." % p.name
	var gained := rules.xp("battle") + rules.xp("kill") * kills + (rules.xp("win") if won else 0)
	p.xp += gained
	var text := "%s earned %d experience" % [p.name, gained]
	if kills > 0:
		text += " with %d kill%s" % [kills, "" if kills == 1 else "s"]
	if p.wounds > 0:
		text += " and took %d wound%s" % [p.wounds, "" if p.wounds == 1 else "s"]
	return text + "."
