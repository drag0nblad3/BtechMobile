class_name BotSkill
extends RefCounted
## How well the computer plays (separate from its MechWarriors' gunnery and
## piloting). Novice rushes the nearest enemy, ignores heat and makes sloppy
## moves; Regular plays sensibly but skips the advanced tricks; Veteran uses
## every tactic the bot knows; Elite also guards itself harder and hunts for
## shots into rear armor. `Bot.act` sets the level before each decision.
## Move jitter is a hash of unit, turn and hex, so it never touches the dice
## and seeded games still replay identically.

enum Level { NOVICE, REGULAR, VETERAN, ELITE }

const NAMES := ["Novice", "Regular", "Veteran", "Elite"]
const BLURBS := [
	"Rushes the nearest enemy, fires everything and overheats. Good for a first game.",
	"Picks sensible moves and targets, minds its heat, skips advanced tricks.",
	"Uses every tactic it knows: aimed shots, MASC, charges, weapon modes.",
	"Veteran play that also guards its armor harder and hunts for rear shots.",
]

static var level: int = Level.VETERAN


static func use(l: int) -> void:
	level = clampi(l, Level.NOVICE, Level.ELITE)


static func name_of(l: int) -> String:
	return NAMES[clampi(l, 0, NAMES.size() - 1)]


static func next(l: int) -> int:
	return (l + 1) % NAMES.size()


## Weight on the damage a move risks taking next phase.
static func taken_weight() -> float:
	return [0.2, 0.6, 0.8, 1.0][level]


## Heat it aims to end the turn at, and how far it stretches for a kill.
static func heat_limit() -> int:
	return [13, 6, 4, 4][level]


static func heat_stretch() -> int:
	return [16, 9, 8, 8][level]


## Score bonus per enemy whose rear arc a move ends in.
static func rear_bonus() -> float:
	return 2.0 if level == Level.ELITE else 0.0


## Only shoots at the nearest enemy instead of the best target.
static func nearest_only() -> bool:
	return level == Level.NOVICE


## Torso twists, charges and Narc beacons.
static func basic_tricks() -> bool:
	return level >= Level.REGULAR


## Aimed shots, MASC/superchargers, Ultra/LB-X modes, clubs.
static func advanced_tricks() -> bool:
	return level >= Level.VETERAN


## Score jitter for one candidate move: sloppier levels misjudge more.
static func jitter(u: Unit, turn: int, k: Vector3i) -> float:
	var amp: float = [6.0, 2.0, 0.0, 0.0][level]
	if amp == 0.0:
		return 0.0
	var h := posmod(hash([u.id, turn, k.x, k.y, k.z]), 1000)
	return amp * (float(h) / 1000.0 - 0.5)
