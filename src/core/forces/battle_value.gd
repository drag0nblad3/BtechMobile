class_name BattleValue
extends RefCounted
## Battle Value: one number for how much a design is worth in a fight, used
## to balance forces. Defensive part (armor, structure, how hard it is to hit)
## plus offensive part (weapons it can fire without overheating, ammo, speed).
## TODO(rules): simplified BV 2 for standard-tech 'Mechs. Rear weapons count
## half, every ton of ammo costs 15, no CASE, no pilot skill adjustment.

const ARMOR_MULT := 2.5
const STRUCTURE_MULT := 1.5
const GYRO_MULT := 0.5
const AMMO_PENALTY := 15
const RUN_HEAT := 2
const JUMP_HEAT_MIN := 3
const ECM_BV := 61.0  ## Guardian ECM counts as defensive equipment.


## Total BV, rounded.
static func of(def: UnitDef) -> int:
	return int(breakdown(def)["total"])


## All the parts, for explanations. Keys: total, defensive, offensive,
## armor, structure, gyro, ams, ecm, ammo_penalty, tmm, def_factor, weapons, ammo,
## tonnage, heat_capacity, speed_mp, speed_factor, halved (weapon names).
static func breakdown(def: UnitDef) -> Dictionary:
	var b := {}
	b["armor"] = def.total_armor() * ARMOR_MULT
	var structure := 0
	for loc in Location.COUNT:
		structure += StructureTable.points(def.tonnage, loc)
	b["structure"] = structure * STRUCTURE_MULT * XlEngine.bv_structure_mult(def)
	b["gyro"] = def.tonnage * GYRO_MULT
	b["ammo_penalty"] = def.ammo_mounts.size() * AMMO_PENALTY
	var tmm := maxi(ToHitCalc.target_movement_mod(def.run_mp()),
			ToHitCalc.target_movement_mod(def.jump_mp, true) if def.jump_mp > 0 else 0)
	b["tmm"] = tmm
	b["def_factor"] = 1.0 + tmm / 10.0
	b["ams"] = def.weapon_mounts.reduce(func(t: float, m: Dictionary) -> float:
		return t + (float(m["weapon"].bv) if m["weapon"].ams else 0.0), 0.0)
	b["ecm"] = ECM_BV if def.ecm_loc >= 0 else 0.0
	var base: float = b["armor"] + b["structure"] + b["gyro"] + b["ams"] + b["ecm"] - b["ammo_penalty"]
	b["defensive"] = maxf(1.0, base) * b["def_factor"]
	_weapons(def, b)
	b["ammo"] = _ammo(def)
	b["tonnage"] = float(def.tonnage)
	b["speed_mp"] = def.run_mp() + roundi(def.jump_mp / 2.0)
	b["speed_factor"] = snappedf(pow(1.0 + (b["speed_mp"] - 5) / 10.0, 1.2), 0.01)
	b["offensive"] = (b["weapons"] + b["ammo"] + b["tonnage"]) * b["speed_factor"]
	b["total"] = roundi(b["defensive"] + b["offensive"])
	return b


## Weapons from best to worst; once their heat passes what the 'Mech can sink
## while moving, the rest count half.
static func _weapons(def: UnitDef, b: Dictionary) -> void:
	var move_heat := RUN_HEAT
	if def.jump_mp > 0:
		move_heat = maxi(move_heat, maxi(JUMP_HEAT_MIN, def.jump_mp))
	var capacity := 6 + def.heat_sinks * def.heat_per_sink() - move_heat
	b["heat_capacity"] = capacity
	var mounts := def.weapon_mounts.duplicate()
	mounts.sort_custom(func(x: Dictionary, y: Dictionary) -> bool:
		var wx: WeaponDef = x["weapon"]
		var wy: WeaponDef = y["weapon"]
		return wx.bv > wy.bv if wx.bv != wy.bv else wx.heat < wy.heat)
	var total := 0.0
	var heat := 0
	var halved: Array[String] = []
	for m: Dictionary in mounts:
		var w: WeaponDef = m["weapon"]
		if w.ams:
			continue  # defensive (added to the defensive part)
		var value := float(w.bv)
		if m["rear"]:
			value *= 0.5
		if heat > capacity:
			value *= 0.5
			halved.append(w.name)
		heat += w.heat
		total += value
	b["weapons"] = total
	b["halved"] = halved


## Ammo is worth no more than the weapons that fire it.
static func _ammo(def: UnitDef) -> float:
	var per_weapon := {}
	for a: Dictionary in def.ammo_mounts:
		var w: WeaponDef = a["weapon"]
		per_weapon[w.id] = int(per_weapon.get(w.id, 0)) + w.ammo_bv
	var cap := {}
	for m: Dictionary in def.weapon_mounts:
		var w: WeaponDef = m["weapon"]
		cap[w.id] = int(cap.get(w.id, 0)) + w.bv
	var total := 0.0
	for id: String in per_weapon:
		total += mini(per_weapon[id], int(cap.get(id, 0)))
	return total
