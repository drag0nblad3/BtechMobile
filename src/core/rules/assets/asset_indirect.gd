class_name AssetIndirect
extends RefCounted
## Indirect Fire Special (IF X, book p. 145). Instead of its regular
## attacks, an Asset that spent no MP this turn may make X indirect attacks:
## range 7/14/21, 5 damage each, an extra -2 to hit, and it loses its TMM
## for the turn. Without line of sight a friendly spotter is needed and the
## usual indirect modifiers apply (p. 70). Assets spot as Running (+2),
## except infantry, emplacements and the SPOTTER Special (as not moved).
## TODO(rules): with its own line of sight the attack is made directly (no
## spotter modifiers, still -2); the lost TMM only counts for shots declared
## after the Asset's own.

const ID := "asset_indirect"


static func weapon() -> WeaponDef:
	var w := WeaponDef.new()
	w.id = ID
	w.name = "Indirect fire"
	w.type = "asset"
	w.damage = 5
	w.short_range = 7
	w.medium_range = 14
	w.long_range = 21
	w.indirect = true
	return w


static func is_indirect(w: WeaponDef) -> bool:
	return w.id == ID


## To-hit for one indirect attack; `th` is empty, the shared Asset checks done.
static func to_hit(state: GameState, attacker: Unit, w: MountedWeapon, target: Unit, th: ToHit) -> ToHit:
	if attacker.move_mode >= 0:
		th.impossible = "Indirect fire only if it spent no MP this turn"
		return th
	var dist := Hex.distance(attacker.coord, target.coord)
	if dist == 0:
		th.impossible = "Indirect fire can't land in its own hex"
		return th
	if w.def.bracket(dist) == WeaponDef.Bracket.OUT:
		th.impossible = "Out of range (%d hexes, max %d)" % [dist, w.def.long_range]
		return th
	var los := LineOfSight.check(state.map, attacker, target)
	var spotter: Unit = null
	if los["blocked"]:
		spotter = IndirectFire.spotter(state, attacker, target)
		if spotter == null:
			th.impossible = "No line of sight (%s); no friendly unit can spot" % los["reason"]
			return th
		los = LineOfSight.check(state.map, spotter, target)
		los["cover"] = Hex.INVALID
	th.add("Skill", attacker.asset.skill(), "The Asset card's Skill is the base number; Assets never pay for their own movement.")
	AssetFire.add_range(th, w, dist)
	th.add("indirect special", -2, "Its Indirect Fire Special: -2, but it gives up its own TMM this turn.")
	if spotter != null:
		IndirectFire.add_mods(th, state, spotter, target)
		th.spotter_id = spotter.id
		th.indirect = true
	ToHitCalc.add_conditions(th, state, attacker, target, los)
	return th


## Spotter movement modifier for an Asset (p. 145, SPOTTER p. 151).
static func spotter_mod(u: Unit) -> int:
	var c := u.asset.card
	return 0 if c.is_infantry() or c.kind == AssetCard.EMPLACEMENT or c.has("SPOTTER") else 2


## Keeps one kind of attack: indirect or regular, whichever comes first.
static func filter(decl: Array[Dictionary], attacker: Unit) -> Array[Dictionary]:
	if decl.is_empty():
		return decl
	var want := is_indirect(attacker.weapons[decl[0]["weapon_index"]].def)
	var out: Array[Dictionary] = []
	for d in decl:
		if is_indirect(attacker.weapons[d["weapon_index"]].def) == want:
			out.append(d)
	return out


## After declaring: firing indirectly costs the Asset its TMM this turn.
static func record(state: GameState, attacker: Unit, decl: Array[Dictionary]) -> void:
	if attacker.asset == null:
		return
	for d in decl:
		if is_indirect(attacker.weapons[d["weapon_index"]].def):
			attacker.asset.indirect_turn = state.turn
			return
