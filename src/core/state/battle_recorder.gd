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
		var packed: Dictionary = BattleCodec.pack(state)
		if not frames.is_empty():
			packed = BattleFrameStorage.share(packed, frames[-1].get("state", {}))
		frames.append({"turn": state.turn, "phase": state.phase,
				"event": String(e.type), "text": explanation,
				"state": packed, "events": [fact]})
	elif not frames.is_empty():
		# Undo/save captures share the prior frame; use copy-on-write for its ledger.
		var last: Dictionary = frames[-1].duplicate()
		var events: Array = last.get("events", []).duplicate()
		events.append(fact)
		last["events"] = events
		frames[-1] = last


static func state_at(frame: Dictionary, db: UnitDb, terrain: TerrainDb) -> GameState:
	return BattleCodec.unpack(frame["state"], db, terrain)
