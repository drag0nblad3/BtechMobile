class_name BattleAtmosphere
extends Node
## Cosmetic battle music and short friendly radio calls from resolved events.
var _hud: BattleHud
var _audio: BattleAudio
var _state: GameState
var _bots: Array
var _music := BattleMusic.new()
var _last := -10000


func setup(hud: BattleHud, audio: BattleAudio, state: GameState, bots: Array) -> void:
	_hud = hud
	_audio = audio
	_state = state
	_bots = bots
	add_child(_music)


func set_paused(on: bool) -> void:
	_music.set_paused(on)


func on_event(e: GameEvent) -> void:
	_music.on_event(e)
	if not GameSettings.radio_chatter:
		return
	var now := Time.get_ticks_msec()
	var line := call_for(e, _state, _bots)
	if line.is_empty() or (now - _last < 2200 and e.type != GameEvent.GAME_OVER):
		return
	_last = now
	_hud.log_view.add_line("RADIO  /  " + line, true)
	_audio.play_sound("ui_click", 50, true)


static func call_for(e: GameEvent, state: GameState, bots: Array) -> String:
	if e.type == GameEvent.TURN_STARTED and int(e.data.get("turn", 0)) == 1:
		return "Command: lance, check in. Mission underway."
	if e.type == GameEvent.GAME_OVER:
		return "Command: cease fire. Stand by for debrief."
	var id := int(e.data.get("unit_id", e.data.get("attacker_id", -1)))
	var u := state.unit_by_id(id)
	if u == null or bots.has(u.side) or state.hidden.has(u):
		return ""
	var name := u.def.display_name()
	match e.type:
		GameEvent.UNIT_DESTROYED: return "Command: " + name + " is down!"
		GameEvent.SHUTDOWN: return name + ": reactor shutdown!" if e.data.get("shutdown", true) else name + ": reactor online."
		GameEvent.FALL: return name + ": lost my footing!"
		GameEvent.CRITICAL: return name + ": critical system damage."
		GameEvent.WEAPON_FIRED:
			if e.data.get("hit", false):
				return name + ": confirmed hit."
	return ""
