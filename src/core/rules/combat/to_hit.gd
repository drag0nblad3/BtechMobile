class_name ToHit
extends RefCounted
## A to-hit number built from named modifiers, so the UI can explain it.
## Each modifier: {label, value, why}. `impossible` explains a shot that
## can't be taken at all (out of range, no line of sight, ...).

var mods: Array[Dictionary] = []
var impossible: String = ""
var spotter_id: int = -1  ## Indirect fire: the friendly 'Mech spotting.
var cover_hex: Vector2i = Hex.INVALID  ## Hill or building giving partial cover: leg hits strike it.
var legs_only := false  ## Water: the shot can only hit legs (Kick table, no partial cover).
var aim_loc := -1  ## Aimed shot (AimedShot): the location aimed at.
var aim_covered := false  ## The aimed target had partial cover: reroll leg hits.
var auto_hit: String = ""  ## Why the shot can't miss (e.g. a building next door); target() is then 2.


func add(label: String, value: int, why: String = "") -> void:
	mods.append({"label": label, "value": value, "why": why})


func target() -> int:
	if auto_hit != "":
		return 2
	var n := 0
	for m in mods:
		n += int(m["value"])
	return n


func possible() -> bool:
	return impossible == "" and target() <= 12


## Chance (0..1) to roll the target number or more on 2d6.
func chance() -> float:
	return Dice.chance_2d6(target()) if impossible == "" else 0.0


## "4 Gunnery +2 medium range +1 you walked = 7".
func summary() -> String:
	if impossible != "":
		return impossible
	var parts: Array[String] = []
	for m in mods:
		var v := int(m["value"])
		if parts.is_empty():
			parts.append("%d %s" % [v, m["label"]])
		elif v != 0:
			parts.append("%s%d %s" % ["+" if v > 0 else "", v, m["label"]])
	if auto_hit != "":
		return "%s: automatic hit" % auto_hit
	return "%s = %d" % [" ".join(parts), target()]
