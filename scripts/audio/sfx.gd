class_name Sfx
extends RefCounted
## Sonidos y música generados por código. No requiere archivos de audio.
## En modo headless no crea reproductores para no interferir con las pruebas.

const SAMPLE_RATE := 22050
const MUSIC_VOLUME_DB := -21.0
const MUSIC_SILENT_DB := -60.0

static var _cache: Dictionary = {}
static var _music_player: AudioStreamPlayer
static var _music_level: int = 0
static var _music_tween: Tween
static var _music_stopping: bool = false


static func play(sound_name: String, volume_db: float = -7.0) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return

	var player := AudioStreamPlayer.new()
	player.stream = _get_sound(sound_name)
	player.volume_db = volume_db
	player.bus = _bus_or_master(GameSettings.BUS_SFX)
	tree.root.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


static func start_music(level_index: int = 1, fade_in: float = 0.7) -> void:
	## Una pista procedural distinta por nivel (2026-11-12): cambia la raíz,
	## el tempo y el arpegio. El reproductor vive en la raíz y sobrevive a los
	## cambios de escena; solo se reconstruye el stream al cambiar de nivel.
	## La entrada siempre es con fundido para suavizar las transiciones.
	if DisplayServer.get_name() == "headless":
		return

	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return

	if _music_player != null and is_instance_valid(_music_player):
		if _music_level == level_index and _music_player.playing and not _music_stopping:
			return
		_music_stopping = false
		_music_level = level_index
		_music_player.stream = _build_music(level_index)
		_music_player.volume_db = MUSIC_SILENT_DB
		_music_player.play()
		_fade_music(MUSIC_VOLUME_DB, fade_in)
		return

	_music_stopping = false
	_music_level = level_index
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = _bus_or_master(GameSettings.BUS_MUSIC)
	_music_player.stream = _build_music(level_index)
	_music_player.volume_db = MUSIC_SILENT_DB
	# Diferido: start_music() se llama desde _ready(), cuando el árbol aún está
	# ocupado creando hijos y add_child() inmediato fallaría.
	_music_player.ready.connect(_on_music_ready)
	tree.root.add_child.call_deferred(_music_player)


static func _bus_or_master(bus_name: String) -> String:
	## Los buses se crean en GameSettings.apply_audio(); si aún no existen el
	## sonido sale por Master para no perderlo.
	GameSettings.ensure_audio_buses()
	return bus_name if AudioServer.get_bus_index(bus_name) >= 0 else "Master"


static func _on_music_ready() -> void:
	if _music_player == null or not is_instance_valid(_music_player):
		return
	_music_player.play()
	_fade_music(MUSIC_VOLUME_DB, 0.7)


static func stop_music(fade_out: float = 0.5) -> void:
	## Fundido de salida usado en las transiciones (2026-11-12). El reproductor
	## persiste en la raíz, así que el tween sobrevive al cambio de escena.
	if DisplayServer.get_name() == "headless":
		return
	if _music_player == null or not is_instance_valid(_music_player):
		return
	_music_stopping = true
	_fade_music(MUSIC_SILENT_DB, fade_out)
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.tween_callback(_music_player.stop)


static func _fade_music(target_db: float, duration: float) -> void:
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	if _music_player == null or not is_instance_valid(_music_player):
		return
	_music_tween = _music_player.create_tween()
	_music_tween.tween_property(
		_music_player,
		"volume_db",
		target_db,
		maxf(0.01, duration)
	)


static func _get_sound(sound_name: String) -> AudioStreamWAV:
	if _cache.has(sound_name):
		return _cache[sound_name]

	var stream: AudioStreamWAV
	match sound_name:
		"jump":
			stream = _sweep(420.0, 660.0, 0.12, 0.5)
		"attack":
			stream = _sweep(260.0, 120.0, 0.09, 0.55, true)
		"shoot":
			stream = _sweep(520.0, 180.0, 0.14, 0.35, true)
		"magic":
			stream = _sequence([660.0, 990.0, 1320.0], 0.06, 0.35)
		"arrow":
			stream = _sweep(1100.0, 260.0, 0.1, 0.28)
		"sentry":
			stream = _sweep(180.0, 55.0, 0.24, 0.6, true)
		"hit":
			stream = _sweep(150.0, 70.0, 0.12, 0.7, true)
		"death":
			stream = _sequence([392.0, 330.0, 262.0, 196.0], 0.12, 0.55)
		"heal":
			stream = _sequence([523.0, 659.0, 784.0], 0.08, 0.4)
		"enemy_death":
			stream = _sweep(220.0, 60.0, 0.18, 0.5, true)
		"bomb":
			stream = _sweep(95.0, 35.0, 0.35, 0.8, true)
		"portal":
			stream = _sequence([523.0, 659.0, 784.0, 1046.0], 0.1, 0.5)
		"ui":
			stream = _sweep(660.0, 660.0, 0.04, 0.9)
		"ui_confirm":
			stream = _sequence([660.0, 880.0], 0.05, 0.5)
		_:
			stream = _sweep(440.0, 440.0, 0.08, 0.8)

	_cache[sound_name] = stream
	return stream


static func _sweep(
	start_frequency: float,
	end_frequency: float,
	duration: float,
	volume: float,
	square: bool = false
) -> AudioStreamWAV:
	var frames := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var phase := 0.0

	for i in frames:
		var t := float(i) / SAMPLE_RATE
		var progress := t / duration
		var frequency := lerpf(start_frequency, end_frequency, progress)
		phase += TAU * frequency / SAMPLE_RATE
		var sample := sin(phase)
		if square:
			sample = signf(sample)
		var envelope := minf(t / 0.01, 1.0) * minf((duration - t) / 0.03, 1.0)
		var value := int(clampf(sample * envelope * volume, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, value)

	return _make_stream(data)


static func _sequence(frequencies: Array, note_duration: float, volume: float) -> AudioStreamWAV:
	var total_duration := note_duration * float(frequencies.size())
	var frames := int(SAMPLE_RATE * total_duration)
	var data := PackedByteArray()
	data.resize(frames * 2)

	for i in frames:
		var t := float(i) / SAMPLE_RATE
		var note_index := mini(int(t / note_duration), frequencies.size() - 1)
		var local_time := t - float(note_index) * note_duration
		var frequency: float = frequencies[note_index]
		var envelope := minf(local_time / 0.008, 1.0) * (1.0 - local_time / note_duration)
		var sample := sin(TAU * frequency * t) * envelope * volume
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, value)

	return _make_stream(data)


static func _build_music(level_index: int = 1) -> AudioStreamWAV:
	var duration := 8.0
	var frames := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(frames * 2)

	# Niveles 1-8 conservan sus temas (7 y 8 comparten el último); 9 y 10 tienen
	# uno propio (2026-11-17).
	var index := clampi(level_index - 1, 0, 5) if level_index <= 8 else mini(level_index - 3, 37)
	var roots := [110.0, 98.0, 82.41, 73.42, 65.41, 92.5, 87.31, 77.78, 103.83, 116.54, 69.3, 61.74, 82.41, 55.0, 51.91, 58.27, 49.0, 46.25, 73.42, 80.0, 69.3, 98.0, 87.31, 61.74, 110.0, 73.42, 55.0, 92.5, 65.41, 116.54, 82.41, 51.91, 103.83, 58.27, 77.78, 46.25, 94.0, 68.0]
	var beat_lengths := [1.0, 0.82, 1.12, 1.25, 0.95, 0.88, 1.05, 0.78, 0.7, 1.1, 0.9, 1.3, 0.65, 1.2, 1.0, 1.4, 0.85, 0.6, 1.15, 1.0, 0.9, 1.15, 0.75, 1.3, 0.8, 1.05, 1.2, 0.68, 0.95, 1.1, 0.85, 1.25, 0.72, 1.0, 0.88, 1.35, 0.78, 0.62]
	var arp_rates := [4.0, 4.5, 3.5, 3.0, 5.0, 4.2, 3.8, 5.0, 5.5, 3.6, 4.4, 3.2, 6.0, 3.4, 4.0, 3.0, 4.6, 6.5, 3.3, 4.2, 5.2, 3.4, 6.0, 3.2, 4.8, 3.9, 3.0, 5.6, 4.4, 3.6, 5.0, 3.1, 6.2, 4.1, 3.5, 5.4, 4.6, 6.4]
	var root: float = roots[index]
	var beat_length: float = beat_lengths[index]
	var arp_rate: float = arp_rates[index]

	var bass_ratios: Array = [1.0, 1.0, 1.3333, 1.1892, 1.0, 1.4983, 1.3333, 1.1892]
	var arp_ratios: Array = [2.0, 2.5198, 2.9966, 4.0, 2.9966, 2.5198, 2.2449, 2.9966]
	var bass_notes: Array = []
	var arp_notes: Array = []
	for ratio in bass_ratios:
		bass_notes.append(root * float(ratio))
	for ratio in arp_ratios:
		arp_notes.append(root * float(ratio))

	for i in frames:
		var t := float(i) / SAMPLE_RATE
		var beat := int(t / beat_length) % bass_notes.size()
		var bass: float = sin(TAU * bass_notes[beat] * t) * 0.16
		var arp_frequency: float = arp_notes[int(t * arp_rate) % arp_notes.size()]
		var arp := sin(TAU * arp_frequency * t) * exp(-4.0 * fmod(t, 0.25)) * 0.055
		var pad: float = sin(TAU * bass_notes[beat] * 1.5 * t) * 0.025
		var envelope := minf(t / 0.08, 1.0) * minf((duration - t) / 0.08, 1.0)
		var sample := (bass + arp + pad) * envelope
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, value)

	var stream := _make_stream(data)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frames
	return stream


static func _make_stream(data: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream
