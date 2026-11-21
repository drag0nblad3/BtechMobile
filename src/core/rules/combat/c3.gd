class_name C3
extends RefCounted
## C3 computer networks (book pp. 198-199). A C3 Master links up to three
## C3 Slaves (or three other Masters) of its side. Every networked 'Mech
## takes its Range Modifier from the networked 'Mech closest to the target
## that can see it; minimum and maximum ranges still use its own distance.
## The network is down while its Master is gone, shut down or its computer
## is wrecked. No C3 help for indirect fire. Hostile ECM (6 hexes) around
## the attacker, the closest member or the Master costs +1 per range bracket
## the network gained (never stacking). C3 adds to Battle Value (p. 222).
## TODO(rules): networks are formed for you (first Master, then up to three
## Slaves, or Masters if no Slaves); company networks, submerged computers,
## stealth, C3i and the Master's TAG function are not modelled.
## Construction (Master 5 t / 5 slots, Slave 1 t / 1 slot) is general knowledge.

const MASTER_TONS := 5.0
const MASTER_SLOTS := 5
const SLAVE_TONS := 1.0
const MAX_LINKS := 3


static func has(def: UnitDef) -> bool:
	return def.c3_master_loc >= 0 or def.c3_slave_loc >= 0


static func is_master(def: UnitDef) -> bool:
	return def.c3_master_loc >= 0


## Its C3 computer is working this turn.
static func working(u: Unit) -> bool:
	if not has(u.def) or u.destroyed or u.shutdown:
		return false
	var loc := u.def.c3_master_loc if is_master(u.def) else u.def.c3_slave_loc
	if u.is_location_out(loc):
		return false
	for s: CritSlot in u.slots[loc]:
		if s.kind == CritSlot.Kind.C3 and s.hit:
			return false
	return true


## Designs in a roster that form a network: [master index, member indexes...]
## or [] when there's no network.
static func form(defs: Array) -> Array[int]:
	var out: Array[int] = []
	var master := -1
	for i in defs.size():
		if is_master(defs[i]):
			master = i
			break
	if master < 0:
		return out
	var slaves: Array[int] = []
	var masters: Array[int] = []
	for i in defs.size():
		if i != master and has(defs[i]):
			(masters if is_master(defs[i]) else slaves).append(i)
	var links := slaves if not slaves.is_empty() else masters
	if links.is_empty():
		return out
	out.append(master)
	out.append_array(links.slice(0, MAX_LINKS))
	return out


## The live network `u` belongs to: its Master first. [] if none or down.
static func network(state: GameState, u: Unit) -> Array[Unit]:
	var side: Array = state.units.filter(func(o: Unit) -> bool: return o.side == u.side)
	var idx := form(side.map(func(o: Unit) -> UnitDef: return o.def))
	var out: Array[Unit] = []
	for i in idx:
		out.append(side[i])
	if not out.has(u) or not working(out[0]):
		out.clear()
	return out


## Battle Value increase per networked unit: +10% for two, +5% per extra, at most +40%.
static func bv_percent(members: int) -> int:
	return 0 if members < 2 else mini(40, 10 + 5 * (members - 2))


## A better range bracket through the network for `attacker`'s shot at
## `target` with profile `p` (now in bracket `br`):
## {br, via: Unit, dist, ecm: penalty} or {} when the network doesn't help.
static func improve(state: GameState, attacker: Unit, target: Unit, p: WeaponDef, br: int) -> Dictionary:
	var net := network(state, attacker)
	if net.is_empty() or not working(attacker):
		return {}
	var master_jammed := C3Boosted.jammed(state, attacker.side, net[0])
	var self_jammed := C3Boosted.jammed(state, attacker.side, attacker)
	var best := {}
	var best_cost := _cost(br, 0)
	for m in net:
		if m == attacker or not working(m) or LineOfSight.check(state.map, m, target)["blocked"]:
			continue
		var d := Hex.distance(m.coord, target.coord)
		var mb := p.bracket(d)
		if mb == WeaponDef.Bracket.OUT or mb >= br:
			continue
		var jammed := self_jammed or master_jammed or C3Boosted.jammed(state, attacker.side, m)
		var ecm := br - mb if jammed else 0
		if _cost(mb, ecm) < best_cost:
			best_cost = _cost(mb, ecm)
			best = {"br": mb, "via": m, "dist": d, "ecm": ecm}
	return best


static func _cost(br: int, ecm: int) -> int:
	return ecm + {WeaponDef.Bracket.MEDIUM: 2, WeaponDef.Bracket.LONG: 4}.get(br, 0)


static func add_mods(th: ToHit, c3: Dictionary) -> void:
	th.add("C3 network", 0, "%s sees the target %d hexes away, so the whole network uses that range." % [
			Names.unit(c3["via"]), c3["dist"]])
	if c3["ecm"] > 0:
		th.add("ECM vs C3", c3["ecm"], "Enemy ECM degrades the network link: +1 for each range bracket C3 gained.")
