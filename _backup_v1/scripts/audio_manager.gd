extends Node

class_name AudioManager

# Gerador procedural de efeitos sonoros sem necessidade de arquivos externos
static func play_sound(parent: Node, sound_type: String) -> void:
	var stream = _generate_sound(sound_type)
	if not stream:
		return
		
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "Master"
	parent.add_child(player)
	player.play()
	player.finished.connect(func(): player.queue_free())

static func _generate_sound(type: String) -> AudioStreamWAV:
	var sample_rate = 22050
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	
	var data = PackedByteArray()
	var duration: float = 0.2
	
	match type:
		"sling_charge":
			duration = 0.15
			var samples = int(sample_rate * duration)
			data.resize(samples)
			for i in range(samples):
				var t = float(i) / samples
				var freq = lerp(300.0, 750.0, t)
				var val = sin(i * freq * TAU / sample_rate) * (1.0 - t * 0.3)
				data[i] = int(clamp((val * 0.4 + 0.5) * 255.0, 0, 255))
				
		"stone_launch":
			duration = 0.18
			var samples = int(sample_rate * duration)
			data.resize(samples)
			for i in range(samples):
				var t = float(i) / samples
				var freq = lerp(600.0, 150.0, t)
				var env = exp(-t * 12.0)
				var val = sin(i * freq * TAU / sample_rate) * env
				data[i] = int(clamp((val * 0.6 + 0.5) * 255.0, 0, 255))
				
		"hit_body":
			duration = 0.25
			var samples = int(sample_rate * duration)
			data.resize(samples)
			for i in range(samples):
				var t = float(i) / samples
				var env = exp(-t * 14.0)
				var noise = (randf() * 2.0 - 1.0) * 0.4
				var tone = sin(i * 120.0 * TAU / sample_rate) * 0.6
				var val = (tone + noise) * env
				data[i] = int(clamp((val * 0.7 + 0.5) * 255.0, 0, 255))
				
		"hit_critical":
			duration = 0.45
			var samples = int(sample_rate * duration)
			data.resize(samples)
			for i in range(samples):
				var t = float(i) / samples
				var env = exp(-t * 6.0)
				# Dois tons harmonicos estilo "sino de bronze"
				var tone1 = sin(i * 880.0 * TAU / sample_rate)
				var tone2 = sin(i * 1760.0 * TAU / sample_rate) * 0.5
				var tone3 = sin(i * 2640.0 * TAU / sample_rate) * 0.25
				var val = (tone1 + tone2 + tone3) * 0.4 * env
				data[i] = int(clamp((val * 0.8 + 0.5) * 255.0, 0, 255))
				
		"goliath_punch":
			duration = 0.38
			var samples = int(sample_rate * duration)
			data.resize(samples)
			for i in range(samples):
				var t = float(i) / samples
				var env = exp(-t * 8.0)
				var freq = lerp(90.0, 35.0, t)
				var noise = (randf() * 2.0 - 1.0) * 0.5
				var val = (sin(i * freq * TAU / sample_rate) * 0.7 + noise * 0.3) * env
				data[i] = int(clamp((val * 0.9 + 0.5) * 255.0, 0, 255))
				
		"dodge":
			duration = 0.16
			var samples = int(sample_rate * duration)
			data.resize(samples)
			for i in range(samples):
				var t = float(i) / samples
				var env = sin(t * PI)
				var noise = (randf() * 2.0 - 1.0) * env
				data[i] = int(clamp((noise * 0.35 + 0.5) * 255.0, 0, 255))
				
		"refill":
			duration = 0.22
			var samples = int(sample_rate * duration)
			data.resize(samples)
			for i in range(samples):
				var t = float(i) / samples
				var env = exp(-t * 9.0)
				var freq = lerp(400.0, 850.0, t)
				var val = sin(i * freq * TAU / sample_rate) * env
				data[i] = int(clamp((val * 0.5 + 0.5) * 255.0, 0, 255))
				
		_:
			return null
			
	wav.data = data
	return wav

# Trilha sonora procedural de tambores de guerra
static func start_war_drums(parent: Node) -> Timer:
	var timer = Timer.new()
	timer.wait_time = 1.6
	timer.autostart = true
	parent.add_child(timer)
	
	timer.timeout.connect(func():
		play_sound(parent, "dodge") # Som grave ritmico simulando tambor
	)
	return timer
