class_name BattleAudio
extends Node
## Pooled, event-driven CC0 audio. Cosmetic: never uses controller Dice.
## One player for each voice, with per-cue throttle during massive volleys.

const MAX_VOICES := 9
const SAME_CUE_MS := 85
const BANK := {
	"laser_alert": "res://assets/audio/laser_alert.ogg",
	"heavy_impact": "res://assets/audio/heavy_impact.ogg",
	"step": "res://assets/audio/step.ogg",
	"ui_click": "res://assets/audio/ui_click.ogg"
}
var _state: GameState
var _streams: Dictionary = {}
var _voices: Array[AudioStreamPlayer] = []
var _last: Dictionary = {}
var _counter := 0


func setup(state: GameState) -> void:
	_state = state
	for key: String in BANK:
		_streams[key] = load(BANK[key])
	for i in MAX_VOICES:
		var player := AudioStreamPlayer.new()
		player.name = "Voice%d" % i
		player.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(player)
		_voices.append(player)


func on_event(e: GameEvent) -> void:
	var key := BattleAudioCues.of(e, _state)
	if key.is_empty():
		return
	var tons := 50
	var id := int(e.data.get("unit_id", e.data.get("attacker_id", -1)))
	var u: Unit = _state.unit_by_id(id) if _state != null and id >= 0 else null
	if u:
		tons = u.def.tonnage
	play_sound(key, tons)


func play_sound(key: String, tons: int = 50, ui := false) -> void:
	if GameSettings.sound_muted or get_tree().paused:
		return
	var now := Time.get_ticks_msec()
	if now - int(_last.get(key, -10000)) < SAME_CUE_MS:
		return
	var player: AudioStreamPlayer = null
	for voice in _voices:
		if not voice.playing:
			player = voice
			break
	if player == null:
		return
	_last[key] = now
	_counter += 1
	var clip := "ui_click" if ui else BattleAudioCues.clip(key)
	player.stream = _streams.get(clip)
	if player.stream == null:
		return
	var n := posmod(hash("%s:%d" % [key, _counter]), 9) - 4
	player.pitch_scale = (1.0 if ui else BattleAudioCues.pitch(key, tons)) * (1.0 + n * 0.009)
	var category := GameSettings.sound_ui if ui else GameSettings.sound_effects
	var volume := 0.0 if GameSettings.sound_muted else GameSettings.sound_master * category
	player.volume_db = linear_to_db(maxf(0.001, volume))
	player.play()


func attach_ui(root: Node) -> void:
	for node in root.get_children():
		if node is BaseButton and not (node as BaseButton).pressed.is_connected(_ui_click):
			(node as BaseButton).pressed.connect(_ui_click)
		attach_ui(node)


func _ui_click() -> void:
	play_sound("ui_click", 50, true)


func set_paused(on: bool) -> void:
	for player in _voices:
		player.stream_paused = on
