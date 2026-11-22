class_name BattleRecorder
extends RefCounted
## Key battle events plus their authoritative state at that instant.
## Playback never calls game rules and cannot consume or change combat dice.

const FRAMED := [
	GameEvent.ACTIVE_SIDE, GameEvent.PHASE_CHANGED, GameEvent.UNIT_MOVED,
	GameEvent.DAMAGE, GameEvent.PHYSICAL, GameEvent.FALL, GameEvent.STAND,
	GameEvent.BUILDING, GameEvent.UNIT_DESTROYED, GameEvent.UNIT_REVEALED,
	GameEvent.UNIT_EXITED, GameEvent.COMBAT_DROP, GameEvent.GAME_OVER,
]

var frames: Array = []


func begin(state: GameState) -> void:
	frames.append({"turn": state.turn, "phase": state.phase,
			"event": "deployment", "text": "Deployment",
			"state": BattleCodec.pack(state), "events": []})


func record(e: GameEvent, state: GameState, explanation: String) -> void:
	# Keep a compact, factual event ledger even when an event does not need a
	# full world snapshot. This supports Battle Forensics without replaying dice.
	var fact := {"turn": state.turn, "phase": state.phase,
			"event": String(e.type), "text": explanation,
			"data": BattleCodec.pack(e.data)}
	if FRAMED.has(e.type):
		frames.append({"turn": state.turn, "phase": state.phase,
				"event": String(e.type), "text": explanation,
				"state": BattleCodec.pack(state), "events": [fact]})
	elif not frames.is_empty():
		var last: Dictionary = frames[frames.size() - 1]
		var events: Array = last.get("events", [])
		events.append(fact)
		last["events"] = events


static func state_at(frame: Dictionary, db: UnitDb, terrain: TerrainDb) -> GameState:
	return BattleCodec.unpack(frame["state"], db, terrain)
