class_name ConditionText
extends RefCounted
## Plain words for a company 'Mech's state between battles: how much armor
## is left, what is broken, and its weakest location, so a player can see
## what each repair would buy them.


static func summary(m: CampaignMech, db: UnitDb) -> String:
	if m.written_off:
		return "Written off."
	if m.condition.is_empty():
		return "Ready, no damage."
	var u := m.to_unit(db, 0, 0, Pilot.new())
	var fresh := Unit.new(0, u.def, 0, Hex.INVALID, 0)
	var parts := PackedStringArray()
	if u.destroyed:
		parts.append("Knocked out (%s)" % u.destroyed_reason)
	parts.append("Armor %d%%" % roundi(100.0 * _sum(u.armor, u.rear_armor) / maxf(1.0, _sum(fresh.armor, fresh.rear_armor))))
	var dented := PackedStringArray()
	for loc in Location.COUNT:
		if u.structure[loc] < fresh.structure[loc]:
			dented.append(Location.code(loc) + (" gone" if u.structure[loc] <= 0 else ""))
	if not dented.is_empty():
		parts.append("structure hit: " + ", ".join(dented))
	var crits := 0
	for row: Array in u.slots:
		for s: CritSlot in row:
			crits += 1 if s.hit else 0
	if crits > 0:
		parts.append("%d critical hit%s" % [crits, "" if crits == 1 else "s"])
	var out := u.weapons.filter(func(w: MountedWeapon) -> bool: return w.destroyed).size()
	if out > 0:
		parts.append("%d weapon%s out" % [out, "" if out == 1 else "s"])
	var shots := 0
	var full := 0
	for i in u.ammo.size():
		shots += 0 if u.ammo[i].destroyed else u.ammo[i].shots
		full += fresh.ammo[i].shots
	if shots < full:
		parts.append("ammo %d/%d" % [shots, full])
	return " · ".join(parts) + "."


## The damaged location with the least of its protection left, as advice. "" when nothing is hurt.
static func weakest(m: CampaignMech, db: UnitDb) -> String:
	if m.condition.is_empty() or m.written_off:
		return ""
	var u := m.to_unit(db, 0, 0, Pilot.new())
	var fresh := Unit.new(0, u.def, 0, Hex.INVALID, 0)
	var best := -1
	var best_share := 1.0
	for loc in Location.COUNT:
		var whole := fresh.armor[loc] + fresh.rear_armor[loc] + fresh.structure[loc]
		var share := float(u.armor[loc] + u.rear_armor[loc] + u.structure[loc]) / maxf(1.0, whole)
		if u.structure[loc] > 0 and share < best_share:
			best = loc
			best_share = share
	if best < 0:
		return ""
	return "Weakest spot: %s, %d armor and %d structure left. A hit there could cost the location and everything mounted in it." % [
		Location.name_of(best), u.armor[best], u.structure[best]]


static func _sum(a: Array[int], b: Array[int]) -> float:
	var t := 0
	for v in a + b:
		t += v
	return float(t)
