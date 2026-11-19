extends Node

# Gerador procedural de efeitos sonoros (16 bits), sem arquivos externos.
# Os sons são gerados uma única vez e guardados em cache.

const RATE := 22050
static var _cache: Dictionary = {}

static func play_sound(parent: Node, sound_type: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var stream := get_stream(sound_type)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	parent.add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

static func get_stream(sound_type: String) -> AudioStreamWAV:
	if _cache.has(sound_type):
		return _cache[sound_type]
	var s := _generate(sound_type)
	_cache[sound_type] = s
	return s

static func _build(samples: PackedFloat32Array) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 30000.0))
	wav.data = data
	return wav

static func _tone(freq: float, i: int) -> float:
	return sin(TAU * freq * float(i) / RATE)

static func _generate(sound_type: String) -> AudioStreamWAV:
	var out := PackedFloat32Array()
	var lp := 0.0
	var phase := 0.0
	match sound_type:
		"sling_spin":
			var n := int(RATE * 0.12)
			out.resize(n)
			for i in n:
				var t := float(i) / n
				var env := sin(t * PI)
				lp += 0.25 * ((randf() * 2.0 - 1.0) - lp)
				out[i] = lp * env * 0.5
		"stone_launch":
			var n := int(RATE * 0.22)
			out.resize(n)
			for i in n:
				var t := float(i) / n
				var env := exp(-t * 9.0)
				phase += TAU * lerpf(700.0, 160.0, t) / RATE
				lp += 0.35 * ((randf() * 2.0 - 1.0) - lp)
				out[i] = (sin(phase) * 0.45 + lp * 0.6) * env
		"hit_body":
			var n := int(RATE * 0.28)
			out.resize(n)
			for i in n:
				var t := float(i) / n
				var env := exp(-t * 13.0)
				phase += TAU * lerpf(160.0, 70.0, t) / RATE
				lp += 0.2 * ((randf() * 2.0 - 1.0) - lp)
				out[i] = (sin(phase) * 0.8 + lp * 0.5) * env
		"hit_critical":
			var n := int(RATE * 0.7)
			out.resize(n)
			for i in n:
				var t := float(i) / n
				var env := exp(-t * 5.0)
				var bell := _tone(880.0, i) + _tone(1320.0, i) * 0.5 + _tone(2200.0, i) * 0.25
				var thud := _tone(lerpf(140.0, 60.0, t), i) * exp(-t * 25.0)
				out[i] = (bell * 0.35 * env + thud * 0.7)
		"goliath_punch":
			var n := int(RATE * 0.45)
			out.resize(n)
			for i in n:
				var t := float(i) / n
				var env := exp(-t * 7.0)
				phase += TAU * lerpf(95.0, 32.0, t) / RATE
				lp += 0.15 * ((randf() * 2.0 - 1.0) - lp)
				out[i] = (sin(phase) * 0.9 + lp * 0.7) * env
		"stomp":
			var n := int(RATE * 0.6)
			out.resize(n)
			for i in n:
				var t := float(i) / n
				var env := exp(-t * 5.0)
				phase += TAU * lerpf(70.0, 28.0, t) / RATE
				lp += 0.1 * ((randf() * 2.0 - 1.0) - lp)
				out[i] = (sin(phase) + lp * 1.2) * env * 0.85
		"dodge":
			var n := int(RATE * 0.18)
			out.resize(n)
			for i in n:
				var t := float(i) / n
				var env := sin(t * PI)
				lp += lerpf(0.1, 0.5, t) * ((randf() * 2.0 - 1.0) - lp)
				out[i] = lp * env * 0.6
		"jump":
			var n := int(RATE * 0.1)
			out.resize(n)
			for i in n:
				var t := float(i) / n
				phase += TAU * lerpf(300.0, 620.0, t) / RATE
				out[i] = sin(phase) * (1.0 - t) * 0.25
		"pickup":
			var n := int(RATE * 0.16)
			out.resize(n)
			for i in n:
				var t := float(i) / n
				phase += TAU * lerpf(500.0, 1100.0, t) / RATE
				out[i] = sin(phase) * exp(-t * 6.0) * 0.4
		"refill":
			var n := int(RATE * 0.2)
			out.resize(n)
			for i in n:
				var t := float(i) / n
				phase += TAU * lerpf(380.0, 900.0, sqrt(t)) / RATE
				out[i] = sin(phase) * exp(-t * 9.0) * 0.45
		"heal":
			var notes := [523.25, 659.25, 783.99, 1046.5]
			var n := int(RATE * 0.5)
			out.resize(n)
			for i in n:
				var t := float(i) / n
				var idx := mini(int(t * 4.0), 3)
				var lt := fmod(t * 4.0, 1.0)
				out[i] = (_tone(notes[idx], i) + _tone(notes[idx] * 2.0, i) * 0.3) * exp(-lt * 3.0) * 0.3
		"hurt":
			var n := int(RATE * 0.3)
			out.resize(n)
			for i in n:
				var t := float(i) / n
				phase += TAU * lerpf(520.0, 180.0, t) / RATE
				var sq := 1.0 if sin(phase) > 0.0 else -1.0
				out[i] = sq * (1.0 - t) * 0.22
		"empty":
			var n := int(RATE * 0.06)
			out.resize(n)
			for i in n:
				var t := float(i) / n
				out[i] = _tone(180.0, i) * (1.0 - t) * 0.3
		"spear_throw":
			var n := int(RATE * 0.35)
			out.resize(n)
			for i in n:
				var t := float(i) / n
				var env := sin(t * PI) * exp(-t * 2.0)
				lp += lerpf(0.4, 0.08, t) * ((randf() * 2.0 - 1.0) - lp)
				out[i] = lp * env * 0.9
		"spear_land":
			var n := int(RATE * 0.25)
			out.resize(n)
			for i in n:
				var t := float(i) / n
				var env := exp(-t * 14.0)
				out[i] = (_tone(210.0, i) * 0.6 + (randf() * 2.0 - 1.0) * 0.4) * env
		"roar":
			var n := int(RATE * 1.1)
			out.resize(n)
			for i in n:
				var t := float(i) / n
				var env := sin(t * PI) * (1.0 - t * 0.4)
				phase += TAU * (75.0 + sin(t * 40.0) * 12.0) / RATE
				lp += 0.12 * ((randf() * 2.0 - 1.0) - lp)
				var saw := fmod(phase / TAU, 1.0) * 2.0 - 1.0
				out[i] = (saw * 0.45 + lp * 0.9) * env * 0.8
		"drum_low":
			var n := int(RATE * 0.35)
			out.resize(n)
			for i in n:
				var t := float(i) / n
				phase += TAU * lerpf(95.0, 45.0, t) / RATE
				out[i] = sin(phase) * exp(-t * 9.0) * 0.8
		"drum_high":
			var n := int(RATE * 0.16)
			out.resize(n)
			for i in n:
				var t := float(i) / n
				phase += TAU * lerpf(220.0, 140.0, t) / RATE
				lp += 0.5 * ((randf() * 2.0 - 1.0) - lp)
				out[i] = (sin(phase) * 0.5 + lp * 0.35) * exp(-t * 14.0)
		"victory":
			var seq := [523.25, 659.25, 783.99, 1046.5, 783.99, 1046.5]
			var lens := [0.15, 0.15, 0.15, 0.35, 0.15, 0.8]
			for k in seq.size():
				var n := int(RATE * lens[k])
				for i in n:
					var t := float(i) / n
					var f: float = seq[k]
					var v := _tone(f, i) * 0.5 + _tone(f * 2.0, i) * 0.2 + _tone(f * 1.5, i) * 0.12
					out.append(v * minf(1.0, t * 20.0) * (1.0 - t * 0.6) * 0.45)
		"defeat":
			var seq2 := [392.0, 349.23, 311.13, 261.63]
			for k in seq2.size():
				var n := int(RATE * (0.28 if k < 3 else 0.8))
				for i in n:
					var t := float(i) / n
					var f2: float = seq2[k]
					out.append((_tone(f2, i) * 0.5 + _tone(f2 * 0.5, i) * 0.3) * (1.0 - t) * 0.4)
		_:
			return null
	return _build(out)
