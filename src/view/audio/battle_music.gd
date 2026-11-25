class_name BattleMusic
extends Node
## Original synthesized ambient layers; no external recordings or gameplay RNG.
## Synchronized loops crossfade according to current combat intensity.
const RATE := 22050
const LOOP := 8.0
var _players: Array[AudioStreamPlayer] = []
var _energy := 0.0
var _finished := false


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	for layer in 2:
		var p := AudioStreamPlayer.new()
		p.stream = _make_loop(layer)
		p.volume_db = -80.0
		add_child(p)
		_players.append(p)
	for p in _players:
		p.play()


func on_event(e: GameEvent) -> void:
	match e.type:
		GameEvent.WEAPON_FIRED, GameEvent.PHYSICAL:
			_energy = minf(1.0, _energy + 0.22)
		GameEvent.AMMO_EXPLOSION, GameEvent.UNIT_DESTROYED:
			_energy = 1.0
		GameEvent.GAME_OVER:
			_finished = true


func _process(delta: float) -> void:
	_energy = maxf(0.0, _energy - delta * 0.055)
	var master := 0.0 if GameSettings.sound_muted else GameSettings.sound_master * GameSettings.sound_music
	for i in _players.size():
		var mix := (1.0 - 0.45 * _energy) if i == 0 else _energy
		var goal := master * mix * (0.3 if _finished else 1.0)
		_players[i].volume_db = lerpf(_players[i].volume_db, linear_to_db(maxf(0.0001, goal)), minf(1.0, delta * 2.0))


func set_paused(on: bool) -> void:
	for p in _players:
		p.stream_paused = on


static func _make_loop(layer: int) -> AudioStreamWAV:
	var count := int(RATE * LOOP)
	var data := PackedByteArray()
	data.resize(count * 2)
	var notes := [55.0, 65.5, 49.0, 73.5]
	for i in count:
		var t := float(i) / RATE
		var beat := fmod(t, 0.5)
		var bar := int(t / 2.0) % notes.size()
		var f: float = notes[bar]
		var envelope := minf(1.0, fmod(t, 2.0) * 5.0) * minf(1.0, (2.0 - fmod(t, 2.0)) * 5.0)
		var sample := (sin(TAU * f * t) * 0.10 + sin(TAU * f * 1.5 * t) * 0.055) * envelope
		if layer == 1:
			sample = sin(TAU * 80.0 * beat) * exp(-beat * 18.0) * 0.2
			sample += sin(TAU * f * 2.0 * t) * exp(-beat * 5.0) * 0.07
		data.encode_s16(i * 2, roundi(clampf(sample, -1.0, 1.0) * 32767))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = count
	return wav
