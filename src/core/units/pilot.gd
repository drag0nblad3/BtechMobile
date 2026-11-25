class_name Pilot
extends RefCounted
## MechWarrior: skills and wounds. Lower skill numbers are better.

const MAX_HITS := 6
## Consciousness roll needed (2d6 >=) after taking the Nth hit.
const CONSCIOUS_ROLL := [0, 3, 5, 7, 10, 11]

var name: String = "MechWarrior"
var gunnery: int = 4
var piloting: int = 5
var hits: int = 0
var conscious: bool = true
var roll_owed: bool = false   ## Took a hit this phase; consciousness roll pending.
var out_since_turn: int = -1  ## Turn the warrior was knocked out.
var abilities: Array[String] = []  ## Special Pilot Abilities (Spa ids).
var lucky := 0  ## Lucky rerolls left this battle (Lucky).
var quarry := -1  ## Blood Stalker's target: unit id, -1 none yet, -2 used up.


func _init(gun: int = 4, pilot: int = 5) -> void:
	gunnery = gun
	piloting = pilot


func is_dead() -> bool:
	return hits >= MAX_HITS


func consciousness_target() -> int:
	return CONSCIOUS_ROLL[mini(hits, MAX_HITS - 1)]
