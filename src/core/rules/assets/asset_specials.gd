class_name AssetSpecials
extends RefCounted
## Asset card Specials that plug into existing systems (book pp. 148-151):
## AMS (-4 to Cluster Hits rolls against it), ECM (a Guardian ECM bubble),
## PRB (a probe with range 4), SWARM (extra damage groupings against a
## target in its own hex). Armor Specials live in AssetDamage, No Turret in
## AssetFire, APC/Mechanized in AssetTransport.
## Indirect Fire lives in AssetIndirect.
## TODO(rules): Artillery, Arrow IV, Narc, TAG and Popup.


## Card Specials that become equipment on the design.
static func setup_def(def: UnitDef) -> void:
	if def.asset.has("ECM"):
		def.ecm_loc = Location.CT
	if def.asset.has("PRB"):
		def.probe = "beagle_probe"  # an Asset's probe reaches 4 hexes (p. 150)
		def.probe_loc = Location.CT


## Does the target's AMS Special cut this missile attack's Cluster Hits roll?
static func ams(target: Unit, w: WeaponDef) -> bool:
	return target.asset != null and target.asset.card.has("AMS") and w.type == "missile"


## Extra groupings a swarm adds against this target (0 if none).
static func swarm_groupings(attacker: Unit, target: Unit) -> int:
	if attacker.asset == null or not attacker.asset.card.has("SWARM") or attacker.coord != target.coord:
		return 0
	var ba := attacker.asset.card.kind == AssetCard.BATTLE_ARMOR
	if target.asset != null:
		var k := target.asset.card.kind
		if k == AssetCard.VTOL or k == AssetCard.BATTLE_ARMOR:
			return 0
		if k == AssetCard.INFANTRY and not ba:
			return 0
	return 2 if ba else 1


## Adds the swarm's extra attacks to a declared volley (same weapon, same target).
static func add_swarm(state: GameState, attacker: Unit, decl: Array[Dictionary]) -> void:
	if decl.is_empty() or decl[0].has("target_hex"):
		return
	var target := state.unit_by_id(int(decl[0]["target_id"]))
	for i in swarm_groupings(attacker, target):
		var extra: Dictionary = decl[0].duplicate()
		extra["swarm"] = true
		decl.append(extra)
