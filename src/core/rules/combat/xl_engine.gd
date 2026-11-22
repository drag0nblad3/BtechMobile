class_name XlEngine
extends RefCounted
## Extra-light and light engines (pp. 87, 99, 204): the engine reaches into
## both side torsos. Engine slots in a destroyed side torso count as destroyed and add
## engine hits, so losing either side torso of an Inner Sphere XL 'Mech
## (3 slots there) is the third engine hit and kills it. A Clan XL has 2
## slots there (ClanTech), so it survives one side torso unless the engine
## was already hit. A light engine has 2 there too. A compact engine fits in
## 3 center-torso slots. Half the weight of a standard engine; BV structure
## counts less (easier to kill). TODO(rules): BV multipliers simplified.

const BV_STRUCTURE_MULT := 0.75
const CLAN_BV_STRUCTURE_MULT := 0.875


## True if losing a side torso now would destroy the engine.
static func torso_loss_kills(u: Unit) -> bool:
	return side_slots(u.def) > 0 and u.engine_hits + side_slots(u.def) >= CritEffects.ENGINE_KILL


## Engine slots in each side torso: IS XL 3, Clan XL and light 2, else 0.
static func side_slots(def: UnitDef) -> int:
	match def.engine_type:
		"xl":
			return ClanTech.xl_side_slots(def)
		"light":
			return 2
	return 0


static func bv_structure_mult(def: UnitDef) -> float:
	if not def.is_xl():
		return 1.0
	return CLAN_BV_STRUCTURE_MULT if def.clan_part("engine") else BV_STRUCTURE_MULT


## Called when a side torso is destroyed; returns the engine hits it added.
static func on_torso_lost(u: Unit, loc: int) -> int:
	if side_slots(u.def) == 0:
		return 0
	var n := 0
	for s: CritSlot in u.slots[loc]:
		if s.kind == CritSlot.Kind.ENGINE and not s.hit:
			s.hit = true
			n += 1
	u.engine_hits += n
	if u.engine_hits >= CritEffects.ENGINE_KILL:
		var kind := "light" if u.def.engine_type == "light" else ("Clan XL" if u.def.clan_part("engine") else "XL")
		Damage.destroy_unit(u, "%s engine lost with the %s" % [kind, Location.name_for(u.def, loc).to_lower()])
	return n


## Tons of the engine: XL half a standard one, light three quarters, compact
## one and a half, rounded up to the half ton. TODO(rules): construction data,
## not in the Core Rulebook.
static func tons(standard_tons: float, engine_type: String) -> float:
	var mult: float = {"xl": 0.5, "light": 0.75, "compact": 1.5}.get(engine_type, 1.0)
	if standard_tons < 0 or mult == 1.0:
		return standard_tons
	return ceilf(snappedf(standard_tons * mult * 2.0, 0.0001)) / 2.0
