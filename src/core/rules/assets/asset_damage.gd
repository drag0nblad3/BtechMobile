class_name AssetDamage
extends RefCounted
## Damage to Battlefield Support Assets (book pp. 146-149). No hit
## locations: every hit adds to a running total for the turn, which the
## End Phase Destroy Check reads (DestroyCheck). Rear hits double (not
## infantry), area-effect damage doubles against infantry, and the armor
## Specials halve some Weapon Types.

## Armor Specials and the Weapon Types they halve (p. 149-150).
const HALVED_BY := {"BRA": ["DB", "M"], "RCA": ["AE", "M"], "RFA": ["DE", "P"]}


## Final damage after the target's Specials. `types` are WeaponDef codes.
static func adjusted(card: AssetCard, amount: int, types: Array, rear: bool) -> int:
	var dmg := amount
	for code: String in HALVED_BY:
		if card.has(code) and _any(types, HALVED_BY[code]):
			dmg = ceili(dmg / 2.0)
	if card.has("FR") and types.has("H"):
		dmg = ceili(dmg / 2.0)  # Fire Resistant (p. 149)
	if types.has("AE") and card.is_infantry():
		dmg *= 2
	if rear and not card.nimble():
		dmg *= 2  # Rear Damage (p. 147)
	return dmg


## One hit on an Asset. `arc_id` is the side it was struck on (FiringArc).
## Returns the damage taken.
static func take(emit: Callable, target: Unit, amount: int, source_id: int, source: String,
		types: Array = [], arc_id: int = FiringArc.FRONT) -> int:
	if target.destroyed or amount <= 0:
		return 0
	var card := target.asset.card
	var rear := arc_id == FiringArc.REAR and not card.nimble()
	var dmg := adjusted(card, amount, types, rear)
	target.asset.damage += dmg
	target.asset.last_attacker = source_id
	if types.has("AI") and target.def.asset.kind == AssetCard.INFANTRY:
		target.asset.ai_hit = true
	emit.call(GameEvent.DAMAGE, {"unit_id": target.id, "source_id": source_id, "source": source,
			"amount": dmg, "loc": -1, "rear": rear, "steps": [], "covered": false, "tac": false,
			"asset": true, "raw": amount, "turn_total": target.asset.damage})
	return dmg


## A weapon hit: its Weapon Types, plus 2 damage per heat point for flamers
## and the like (Assets have no heat scale, p. 148).
static func weapon_hit(emit: Callable, attacker: Unit, w: WeaponDef, target: Unit,
		amount: int, arc_id: int) -> void:
	var types := w.attack_types()
	if w.heat_damage and not target.asset.card.has("FR"):
		amount += 2 * w.heat_points
	take(emit, target, amount, attacker.id, w.name, types, arc_id)


## Heat from outside sources in the Heat Phase (fire hexes): 2 damage per
## point, none with Fire Resistant. Fire counts as AI against conventional
## infantry (p. 148).
static func heat(emit: Callable, u: Unit, points: int, source: String) -> void:
	if points <= 0 or u.asset.card.has("FR"):
		return
	take(emit, u, 2 * points, -1, source, ["AI"] if source == "fire" else [])


static func _any(a: Array, b: Array) -> bool:
	for x in a:
		if b.has(x):
			return true
	return false
