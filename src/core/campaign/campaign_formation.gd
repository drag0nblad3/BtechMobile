class_name CampaignFormation
extends RefCounted
## The Formation Type the company's lance fights as (Campaign Operations
## pp. 60-66): chosen on the campaign screen from the types the ready lance
## qualifies for, and set up on side 0 when the contract's battle starts.
## TODO(rules): the enemy lance fights without a formation.


## The ready lance as battle units (for the requirements checks).
static func lance(c: Campaign, db: UnitDb) -> Array[Unit]:
	var out: Array[Unit] = []
	for m in c.ready_mechs():
		var def := db.get_def(m.design)
		if def != null and out.size() < CampaignLaunch.LANCE:
			var u := Unit.new(out.size() + 1, def, 0, Hex.INVALID, 0)
			u.pilot = Pilot.new(4, 5)
			out.append(u)
	return out


static func options(c: Campaign, db: UnitDb) -> Array[String]:
	return FormationTypes.qualifying(lance(c, db))


## The chosen type, or "" if the lance no longer qualifies for it.
static func current(c: Campaign, db: UnitDb) -> String:
	return c.formation if options(c, db).has(c.formation) else ""


## Moves the choice to the next type the lance qualifies for, then none.
static func cycle(c: Campaign, db: UnitDb) -> String:
	var all: Array[String] = [""]
	all.append_array(options(c, db))
	c.formation = all[(all.find(current(c, db)) + 1) % all.size()]
	return ""


## Forms side 0 up; returns the formation's name, or "".
static func apply(c: Campaign, state: GameState) -> String:
	if c.formation == "" or Formation.setup(state, 0, c.formation).is_empty():
		return ""
	return FormationTypes.name_of(c.formation)
