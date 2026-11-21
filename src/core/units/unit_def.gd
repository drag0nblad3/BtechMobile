class_name UnitDef
extends RefCounted
## Static unit design (one variant), loaded from data/units/<id>.json.
## Data only: runtime damage lives in Unit. See docs/data-formats.md.

## Engine-integral heat sinks that take no critical slots.
## TODO(rules): really engine rating / 25; 10 for every 'Mech here.
const ENGINE_HEAT_SINKS := 10

var id: String
var name: String      ## e.g. "Atlas"
var model: String     ## e.g. "AS7-D"
var tonnage: int
var walk_mp: int
var jump_mp: int
var heat_sinks: int = 10
## Double heat sinks (p. 89): each removes 2 heat and fills 3 slots (2 if Clan).
var double_heat_sinks := false
## Locations protected by CASE (p. 96).
## Physical weapons: [{kind: "hatchet"|"sword", loc}] (MeleeWeapons).
var melee: Array[Dictionary] = []
var case_locs: Array[int] = []
var ecm_loc := -1  ## Location of a Guardian ECM suite (Ecm), -1 none.
var tc_loc := -1  ## Location of a targeting computer (TargetingComputer), -1 none.
## "standard" or "xl" (XlEngine: 3 engine slots in each side torso, 2 if Clan).
var engine_type := "standard"
## "inner_sphere" or "clan" (ClanTech: smaller XL engine and double heat
## sinks, free CASE everywhere, lighter armor and targeting computers).
var tech_base := "inner_sphere"
## OmniMech (book p. 20, OmniConfig): a construction feature; same rules in play.
var omni := false
var chassis := ""  ## OmniMech chassis id ("timber_wolf"), "" for others.
var config := ""  ## OmniMech configuration ("Prime", "A"), "" for others.
## "standard" or "endo_steel"; armor "standard" or "ferro_fibrous". Their
## bulky slots are listed as equipment ("endo_steel", "ferro_fibrous").
var structure_type := "standard"
var armor_type := "standard"
var role: String = ""    ## One-line tactical summary for the force builder.
var sprite: String = ""  ## Folder under res://assets/mechs/, "" = placeholder.
var armor: Array[int] = []       ## Per Location, front.
var rear_armor: Array[int] = []  ## Per Location (torsos only).
## [{weapon: WeaponDef, loc: int, rear: bool}] in record-sheet order.
var weapon_mounts: Array[Dictionary] = []
## [{weapon: WeaponDef, loc: int}], one entry per ton of ammo.
var ammo_mounts: Array[Dictionary] = []
## Location -> Array[String] of other slot items ("heat_sink", "jump_jet").
var other_items: Dictionary = {}
## Location -> Array[String] of endo steel / ferro-fibrous slots.
var bulk_slots: Dictionary = {}
## Location -> Array[String] of actuators the design lacks ("hand", ...).
var missing_actuators: Dictionary = {}


static func from_dict(d: Dictionary, weapons: WeaponDb = null) -> UnitDef:
	var u := UnitDef.new()
	u.id = d["id"]
	u.name = d["name"]
	u.model = d.get("model", "")
	u.tonnage = int(d["tonnage"])
	u.walk_mp = int(d["walk_mp"])
	u.jump_mp = int(d.get("jump_mp", 0))
	u.heat_sinks = int(d.get("heat_sinks", ENGINE_HEAT_SINKS))
	u.double_heat_sinks = d.get("heat_sink_type", "single") == "double"
	u.engine_type = d.get("engine_type", "standard")
	u.tech_base = d.get("tech_base", "inner_sphere")
	u.omni = bool(d.get("omni", false))
	u.chassis = d.get("chassis", "")
	u.config = d.get("config", "")
	u.structure_type = d.get("structure_type", "standard")
	u.armor_type = d.get("armor_type", "standard")
	u.role = d.get("role", "")
	u.sprite = d.get("sprite", "")
	var arm: Dictionary = d.get("armor", {})
	var rear: Dictionary = d.get("rear_armor", {})
	for loc in Location.COUNT:
		u.armor.append(int(arm.get(Location.code(loc), 0)))
		u.rear_armor.append(int(rear.get(Location.code(loc), 0)))
	for code: String in d.get("missing_actuators", {}):
		u.missing_actuators[Location.from_code(code)] = d["missing_actuators"][code]
	var eq: Dictionary = d.get("equipment", {})
	for code: String in eq:
		for item: String in eq[code]:
			var rep := item.split("*")  # "endo_steel*3" = three slots
			for i in (int(rep[1]) if rep.size() > 1 else 1):
				u._add_item(Location.from_code(code), rep[0], weapons)
	return u


## Items: "<weapon id>", "<weapon id>@rear", "<launcher>+artemis", "ammo:<weapon id>",
## "ammo:<weapon id>:cluster", "heat_sink", "jump_jet", "case", "hatchet", "sword",
## "endo_steel", "ferro_fibrous", "targeting_computer", "guardian_ecm"; "<item>*N" repeats an item N times.
func _add_item(loc: int, item: String, weapons: WeaponDb) -> void:
	if item == "endo_steel" or item == "ferro_fibrous":
		if not bulk_slots.has(loc):
			bulk_slots[loc] = []
		bulk_slots[loc].append(item)
		return
	if item == "guardian_ecm":
		ecm_loc = loc
		return
	if item == "targeting_computer":
		tc_loc = loc
		return
	if item == "case":
		case_locs.append(loc)
		return
	if item == "hatchet" or item == "sword":
		melee.append({"kind": item, "loc": loc})
		return
	if item == "heat_sink" or item == "jump_jet":
		if not other_items.has(loc):
			other_items[loc] = []
		other_items[loc].append(item)
		return
	assert(weapons != null, "%s: equipment needs a WeaponDb" % id)
	if item.begins_with("ammo:"):
		var ap := item.substr(5).split(":")
		var aw := weapons.get_def(ap[0])
		assert(aw != null, "%s: unknown ammo %s" % [id, item])
		ammo_mounts.append({"weapon": aw, "loc": loc, "kind": ap[1] if ap.size() > 1 else ""})
		return
	var artemis := item.ends_with("+artemis")
	var parts := item.trim_suffix("+artemis").split("@")
	var w := weapons.get_def(parts[0])
	assert(w != null, "%s: unknown weapon %s" % [id, item])
	weapon_mounts.append({"weapon": w, "loc": loc, "rear": parts.size() > 1, "artemis": artemis})


## Running MP = walking MP x 1.5, rounded up.
func run_mp() -> int:
	return ceili(walk_mp * 1.5)


func display_name() -> String:
	return ("%s %s" % [name, model]).strip_edges()


## 0 light (under 40 t), 1 medium, 2 heavy, 3 assault (80 t+).
static func class_index(tons: int) -> int:
	if tons < 40:
		return 0
	if tons < 60:
		return 1
	if tons < 80:
		return 2
	return 3


func weight_class() -> String:
	if tonnage < 40:
		return "Light"
	if tonnage < 60:
		return "Medium"
	if tonnage < 80:
		return "Heavy"
	return "Assault"


func total_armor() -> int:
	var n := 0
	for loc in Location.COUNT:
		n += armor[loc] + rear_armor[loc]
	return n


## Heat one working heat sink removes.
func heat_per_sink() -> int:
	return 2 if double_heat_sinks else 1


## Slots (and tons) of a hatchet or sword. TODO(rules): construction data,
## not in the Core Rulebook: hatchet tons/15, sword tons/20 (half tons).
func melee_slots(kind: String) -> int:
	return ceili(tonnage / 15.0)


func melee_tons(kind: String) -> float:
	if kind == "sword":
		return ceilf(tonnage / 20.0 * 2.0) / 2.0
	return ceilf(tonnage / 15.0)


func is_xl() -> bool:
	return engine_type == "xl"


func is_clan() -> bool:
	return tech_base == "clan"


## Clan 'Mechs have CASE built into every location (ClanTech).
func has_case(loc: int) -> bool:
	return is_clan() or case_locs.has(loc)


func has_actuator(loc: int, actuator: String) -> bool:
	return not missing_actuators.get(loc, []).has(actuator)
