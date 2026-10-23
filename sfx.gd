extends Node
## Every sound is synthesised once at startup into a sample: Godot's web build cannot generate
## audio live, and playing baked samples costs nothing.

const RATE := 22050
const VOICES := 6

var _sounds := {}
var _voices := []
var _next_voice := 0
var _sea := AudioStreamPlayer.new()
var _rain := AudioStreamPlayer.new()


func bake() -> void:
	_sounds.flash = _wav(_notes([880.0, 1320.0], 0.05, 0.25, false))
	_sounds.buy = _wav(_notes([523.0, 659.0, 784.0, 1047.0], 0.07, 0.12, true))
	_sounds.horn = _wav(_horn())
	_sounds.bell = _wav(_bell())
	_sounds.thunder = _wav(_thunder())
	for i in VOICES:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		_voices.append(voice)
	_sea.stream = _wav(_surf(4.0, 350.0, 0.25, 0.35), true)
	_rain.stream = _wav(_surf(3.0, 3000.0, 0.0, 0.18), true)
	add_child(_sea)
	add_child(_rain)


func play(sound: String) -> void:
	var voice: AudioStreamPlayer = _voices[_next_voice]
	_next_voice = (_next_voice + 1) % VOICES
	voice.stream = _sounds[sound]
	voice.play()


func start_sea() -> void:
	_sea.play()


func start_rain() -> void:
	_rain.play()


func stop_rain() -> void:
	_rain.stop()


func _wav(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1, 1) * 32767))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.data = data
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = samples.size()
	return wav


## Notes one after another, each fading out: chimes and chiptune blips.
func _notes(frequencies: Array, note_seconds: float, volume: float, square: bool) -> PackedFloat32Array:
	var per_note := int(note_seconds * RATE)
	var samples := PackedFloat32Array()
	samples.resize(per_note * frequencies.size())
	for n in frequencies.size():
		for i in per_note:
			var t := float(i) / RATE
			var wave := sin(TAU * frequencies[n] * t)
			samples[n * per_note + i] = (signf(wave) if square else wave) * volume * exp(-t / (note_seconds * 0.4))
	return samples


## Two low square tones a fifth apart, softened: a ship's horn.
func _horn() -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(int(1.2 * RATE))
	for i in samples.size():
		var t := float(i) / RATE
		var envelope := minf(t / 0.1, 1.0) * exp(-maxf(0, t - 0.6) * 6)
		samples[i] = (signf(sin(TAU * 110 * t)) + signf(sin(TAU * 165 * t))) * 0.5 * envelope
	return _lowpass(samples, 500.0, 0.5)


## Inharmonic partials, each ringing out at its own rate: a struck bell.
func _bell() -> PackedFloat32Array:
	const PARTIALS := [[1.0, 1.6], [2.76, 0.9], [5.4, 0.5], [8.9, 0.3]] # frequency ratio, decay seconds
	var samples := PackedFloat32Array()
	samples.resize(int(2.0 * RATE))
	for i in samples.size():
		var t := float(i) / RATE
		var sum := 0.0
		for partial in PARTIALS:
			sum += sin(TAU * 440 * partial[0] * t) * exp(-t / partial[1])
		samples[i] = sum * 0.12
	return samples


func _thunder() -> PackedFloat32Array:
	var samples := _lowpass(_white(int(1.6 * RATE)), 180.0, 1.0)
	for i in samples.size():
		samples[i] *= exp(-float(i) / RATE / 0.5) * 0.9
	return samples


## Filtered noise that loops without a seam, swelling slowly like waves on a shore.
func _surf(seconds: float, cutoff: float, swell_hz: float, volume: float) -> PackedFloat32Array:
	var length := int(seconds * RATE)
	var overlap := int(0.3 * RATE)
	var samples := _lowpass(_white(length + overlap), cutoff, 1.0)
	# Fade the extra tail into the head, so the loop point is inaudible
	for i in overlap:
		var blend := float(i) / overlap
		samples[i] = samples[i] * blend + samples[length + i] * (1 - blend)
	samples.resize(length)
	for i in length:
		samples[i] *= volume * (0.65 + 0.35 * sin(TAU * swell_hz * i / RATE))
	return samples


func _white(length: int) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(length)
	for i in length:
		samples[i] = randf_range(-1, 1)
	return samples


## One-pole lowpass, scaled so the loudest sample reaches `peak`.
func _lowpass(samples: PackedFloat32Array, cutoff: float, peak: float) -> PackedFloat32Array:
	var smoothing := 1 - exp(-TAU * cutoff / RATE)
	var level := 0.0
	var loudest := 0.0
	for i in samples.size():
		level += smoothing * (samples[i] - level)
		samples[i] = level
		loudest = maxf(loudest, absf(level))
	for i in samples.size():
		samples[i] *= peak / loudest
	return samples
