class_name AssetCard
extends RefCounted
## A Battlefield Support Asset card (book pp. 140-141): vehicles, infantry,
## VTOLs and emplacements. One attack, a fixed TMM, and a Destroy Check
## instead of armor and hit locations. Loaded from data/assets/<id>.json.

## Asset types (card header).
const VEHICLE := "vehicle"
const INFANTRY := "infantry"          ## Conventional infantry.
const BATTLE_ARMOR := "battle_armor"
const VTOL := "vtol"
const EMPLACEMENT := "emplacement"

## Force builder tip (full explanations), our own wording.
const TIP := "Assets fight by simpler rules: one attack a turn at the card's Skill, a fixed defence (TMM), and no armor diagram. Damage in a turn that reaches the Threshold forces a Destroy Check against the Check number."

## Movement types (p. 142): foot, hover, jump, tracked, VTOL, wheeled; "" immobile.
const MOTIVES := ["f", "h", "j", "t", "v", "w"]
const MOTIVE_NAMES := {"f": "foot", "h": "hover", "j": "jump", "t": "tracked",
		"v": "VTOL", "w": "wheeled", "": "immobile"}

var kind := VEHICLE
var motive := "t"
var mp := 0
var tmm := 0
var short_range := 0
var medium_range := 0
var long_range := 0
var skill := 6
var skill_improved := 5  ## Grey value in brackets; equals skill if none.
var damage := 0          ## Damage per grouping.
var groupings := 1       ## Separate attacks per turn, all at one target.
var check := 7           ## Destroy Check target number.
var threshold := 5       ## Damage in one turn that triggers a Destroy Check.
var bsp := 0             ## Battlefield Support Point cost.
var bsp_improved := 0    ## Cost with improved Skill, 0 if it can't be bought.
## Specials by code (p. 148): "APC" -> 2, "NOTUR" -> 1, "AI" -> 1, ...
var specials: Dictionary = {}
## Mechanized/motorized infantry: rides a vehicle with this motive.
var mechanized := false


static func from_dict(d: Dictionary) -> AssetCard:
	var c := AssetCard.new()
	c.kind = d.get("type", VEHICLE)
	c.motive = d.get("motive", "")
	c.mp = int(d.get("mp", 0))
	c.tmm = int(d.get("tmm", 0))
	var r: Array = d.get("range", [0, 0, 0])
	c.short_range = int(r[0])
	c.medium_range = int(r[1])
	c.long_range = int(r[2])
	c.skill = int(d.get("skill", 6))
	c.skill_improved = int(d.get("skill_improved", c.skill))
	c.damage = int(d.get("damage", 0))
	c.groupings = int(d.get("groupings", 1))
	c.check = int(d.get("check", 7))
	c.threshold = int(d.get("threshold", 5))
	c.bsp = int(d.get("bsp", 0))
	c.bsp_improved = int(d.get("bsp_improved", 0))
	c.specials = d.get("specials", {})
	c.mechanized = bool(d.get("mechanized", false))
	return c


## Any infantry: conventional or battle armor (p. 141).
func is_infantry() -> bool:
	return kind == INFANTRY or kind == BATTLE_ARMOR


func is_vehicle() -> bool:
	return kind == VEHICLE or kind == VTOL


func immobile() -> bool:
	return kind == EMPLACEMENT or motive == "" or has("IMMOBILE")


## No facing: turning is free and there is no rear arc (Nimble, p. 150).
func nimble() -> bool:
	return is_infantry() or has("NIMBLE")


func has(code: String) -> bool:
	return specials.has(code)


func special(code: String) -> int:
	return int(specials.get(code, 0))


## Battle Value when mixed with 'Mechs: 20 BV per BSP (p. 157).
func bv(improved := false) -> int:
	return 20 * (bsp_improved if improved and bsp_improved > 0 else bsp)


## The card's attack as a weapon the combat code can fire: no heat, no ammo,
## no minimum range (p. 144). One copy is mounted per damage grouping.
func attack_weapon(asset_name: String) -> WeaponDef:
	var w := WeaponDef.new()
	w.id = "asset_attack"
	w.name = "%s attack" % asset_name
	w.type = "asset"
	w.damage = damage
	w.short_range = short_range
	w.medium_range = medium_range
	w.long_range = long_range
	w.ai = has("AI")
	return w


func motive_name() -> String:
	return MOTIVE_NAMES.get(motive, motive)


## Card line for the force builder, e.g. "4t, TMM +1, 1/2/3, Skill 6, 3x1".
func summary() -> String:
	var move := "immobile" if immobile() else "%d%s" % [mp, motive]
	return "%s, TMM %+d, %d/%d/%d, Skill %d, %dx%d, Check %d, Threshold %d" % [
			move, tmm, short_range, medium_range, long_range, skill, damage, groupings, check, threshold]
