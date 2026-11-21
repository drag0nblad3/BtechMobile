class_name AssetFire
extends RefCounted
## To-hit numbers involving Assets (book pp. 144-145).
## Shooting: the card's Skill is the base, no attacker movement modifier,
## no minimum range, a 360-degree arc (forward only with No Turret), one
## target a turn, and infantry may shoot into their own hex.
## Being shot: a fixed TMM whether it moved or not, but only the higher of
## TMM and the terrain of its hex; emplacements are immobile (-4); VTOLs
## take no terrain modifier.


## A shot by an Asset's attack (one damage grouping).
static func to_hit(state: GameState, attacker: Unit, w: MountedWeapon, target: Unit) -> ToHit:
	var th := ToHit.new()
	var card := attacker.asset.card
	if target == null or target.destroyed:
		th.impossible = "No target"
		return th
	if target.asset != null and target.asset.carried_by >= 0:
		th.impossible = "It is riding inside a transport"
		return th
	if attacker.asset.deployed_turn == state.turn:
		th.impossible = "Infantry can't shoot on the turn it leaves its transport"
		return th
	var dist := Hex.distance(attacker.coord, target.coord)
	if dist == 0 and not card.is_infantry():
		th.impossible = "Only infantry can attack a unit in its own hex"
		return th
	if card.has("NOTUR") and dist > 0 \
			and FiringArc.fire_arc(attacker.coord, attacker.facing, target.coord) != FiringArc.FRONT:
		th.impossible = "No turret: it can only fire into its front arc"
		return th
	var los := LineOfSight.check(state.map, attacker, target) if dist > 0 else LineOfSight.none()
	if los["blocked"]:
		th.impossible = "No line of sight (%s)" % los["reason"]
		return th
	var br := w.def.bracket(dist)
	if br == WeaponDef.Bracket.OUT:
		th.impossible = "Out of range (%d hexes, max %d)" % [dist, w.def.long_range]
		return th
	th.add("Skill", attacker.asset.skill(), "The Asset card's Skill is the base number; Assets never pay for their own movement.")
	match br:
		WeaponDef.Bracket.MEDIUM:
			th.add("medium range", 2, "%d hexes is medium range for this Asset (%s)." % [dist, w.def.range_text()])
		WeaponDef.Bracket.LONG:
			th.add("long range", 4, "%d hexes is long range for this Asset (%s)." % [dist, w.def.range_text()])
	ToHitCalc.add_conditions(th, state, attacker, target, los)
	return th


## Target modifiers for an Asset target, in place of target movement and
## the terrain of its hex.
static func add_target_mods(th: ToHit, state: GameState, target: Unit) -> void:
	var card := target.asset.card
	if card.kind == AssetCard.EMPLACEMENT or card.has("IMMOBILE"):
		th.add("target immobile", -4, "Emplacements can't dodge: -4.")
		return
	var tmm := 0 if target.asset.deployed_turn == state.turn else card.tmm
	var terrain := 0 if card.kind == AssetCard.VTOL else terrain_mod(state, target)
	if terrain >= tmm and terrain > 0:
		th.add("target in cover", terrain, "The terrain of its hex (%+d) beats its movement modifier (%+d); Assets use only the higher." % [terrain, tmm])
	elif tmm != 0:
		th.add("target TMM", tmm, "Assets have a fixed target movement modifier from their card, moving or not (higher than its terrain, %+d)." % terrain)


## Terrain modifier of the Asset's own hex: woods, smoke, or inside a building.
static func terrain_mod(state: GameState, target: Unit) -> int:
	var tile := state.map.get_tile(target.coord)
	if tile == null:
		return 0
	var woods := LineOfSight.woods_value(tile)
	var n := woods + Obscurant.to_hit_mod(state.map, target, woods)
	return maxi(n, BuildingRules.inside_mod(state.map, target))
