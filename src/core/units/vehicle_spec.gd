class_name VehicleSpec
extends RefCounted
## What a combat vehicle's record sheet adds to a design (UnitDef.vehicle):
## motive type, Cruising MP, engine and turret. Flank MP = Cruise x 1.5.

const MOTIVES := ["t", "w", "h"]
const MOTIVE_NAMES := {"t": "Tracked", "w": "Wheeled", "h": "Hover"}

var motive := "t"
var cruise_mp := 0
var engine := "fusion"  ## "fusion" or "ice"
var turret := false


static func from_dict(d: Dictionary) -> VehicleSpec:
	var v := VehicleSpec.new()
	v.motive = d.get("motive", "t")
	assert(MOTIVES.has(v.motive), "unknown vehicle motive %s" % v.motive)
	v.cruise_mp = int(d["cruise_mp"])
	v.engine = d.get("engine", "fusion")
	v.turret = bool(d.get("turret", false))
	return v


func flank_mp() -> int:
	return ceili(cruise_mp * 1.5)


func motive_name() -> String:
	return MOTIVE_NAMES.get(motive, motive)
