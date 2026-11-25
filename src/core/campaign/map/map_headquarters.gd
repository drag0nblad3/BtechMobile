class_name MapHeadquarters
extends RefCounted
## Formation reorganization before strategic orders (Campaign Operations,
## post-battle recovery). Only co-located, grounded friendly formations.
## No repairs, purchases, or free replacements are granted here.


static func can_swap(mc: MapCampaign, a: MapLance, b: MapLance) -> bool:
	return a != null and b != null and a.side == 0 and b.side == 0 and a.on_map() and b.on_map() and a.zone == b.zone and mc.battles.is_empty() and mc.winner < 0 and a.order == MapLance.DEFEND and b.order == MapLance.DEFEND


static func swap_mechs(mc: MapCampaign, a: MapLance, b: MapLance, first: String, second: String) -> bool:
	if not can_swap(mc, a, b) or a == b or not a.mech_ids.has(first) or not b.mech_ids.has(second):
		return false
	var m := mc.player.mech(first)
	var n := mc.player.mech(second)
	if m == null or n == null or m.written_off or n.written_off:
		return false
	a.mech_ids[a.mech_ids.find(first)] = second
	b.mech_ids[b.mech_ids.find(second)] = first
	return true


static func swap_pilots(mc: MapCampaign, a: MapLance, b: MapLance, first: String, second: String) -> bool:
	if not can_swap(mc, a, b) or first == second or not a.mech_ids.has(first) or not b.mech_ids.has(second):
		return false
	var m := mc.player.mech(first)
	var n := mc.player.mech(second)
	if m == null or n == null or m.written_off or n.written_off:
		return false
	var p := mc.player.pilot(m.pilot_id)
	var q := mc.player.pilot(n.pilot_id)
	if p == null or q == null or p.dead or q.dead:
		return false
	var old := m.pilot_id
	m.pilot_id = n.pilot_id
	n.pilot_id = old
	return true
