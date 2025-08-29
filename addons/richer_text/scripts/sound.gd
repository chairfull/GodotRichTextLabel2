class_name Sound extends Resource

@export_file("*.mp3", "*.wav", "*.ogg") var paths: PackedStringArray
@export var pitch_rand_min := 0.95
@export var pitch_rand_max := 1.05
@export var volume_rand_min := -0.05
@export var volume_rand_max := 0.05

func play(node: Node):
	var path := Array(paths).pick_random()
	if not path or not FileAccess.file_exists(path):
		return
	var snd := AudioStreamPlayer.new()
	node.add_child(snd)
	snd.stream = load(path)
	snd.pitch_scale = randf_range(pitch_rand_min, pitch_rand_max)
	snd.volume_linear = randf_range(volume_rand_min, volume_rand_max)
	snd.play()
	snd.finished.connect(snd.queue_free)
