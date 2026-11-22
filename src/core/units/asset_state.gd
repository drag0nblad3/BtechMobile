class_name AssetState
extends RefCounted
## What changes on an Asset card during play (book pp. 146-147): the
## Destroy Check number after Degradation, and this turn's damage tally.
## Damage itself is wiped every End Phase; only Degradation stays.

var card: AssetCard
var improved := false   ## Bought with improved Skill (p. 141).
var check: int          ## Current Destroy Check target number.
var damage := 0         ## Damage taken this turn, all phases.
var ai_hit := false     ## Hit by an Anti-Infantry weapon or fire this turn.
var flushed := false    ## Hit by enemy infantry in its building: no cover bonus (InfantryCover).
var last_attacker := -1 ## Unit id that dealt damage last (it rolls the check).
var auto_fail := false  ## Degraded to 2 or less: the next check destroys it.
var deployed_turn := -1 ## Turn it left an APC: no fire and TMM 0 (p. 148).
var indirect_turn := -1 ## Turn it fired indirectly: TMM 0 (p. 145).
var carried_by := -1    ## Unit id of the APC carrying it, -1 if on foot.
var altitude := 0       ## VTOL: its flight level (VtolFlight, p. 142).


func _init(c: AssetCard, improved_skill := false) -> void:
	card = c
	improved = improved_skill
	check = c.check


func skill() -> int:
	return card.skill_improved if improved else card.skill


func bv() -> int:
	return card.bv(improved)


func new_turn() -> void:
	damage = 0
	ai_hit = false
	flushed = false
	last_attacker = -1
