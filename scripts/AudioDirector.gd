extends Node

var music := AudioStreamPlayer.new()
var ambience := AudioStreamPlayer.new()
var sfx_pool: Array[AudioStreamPlayer] = []
var current_track := ""
var rng := RandomNumberGenerator.new()

const SFX := {
	"jump": "res://audio/sfx/jump.ogg",
	"land": "res://audio/sfx/land.ogg",
	"bark_1": "res://audio/sfx/bark_1.ogg",
	"bark_2": "res://audio/sfx/bark_2.ogg",
	"bark_3": "res://audio/sfx/bark_3.ogg",
	"treat": "res://audio/sfx/treat.ogg",
	"checkpoint": "res://audio/sfx/checkpoint.ogg",
	"hurt": "res://audio/sfx/hurt.ogg",
	"squirrel": "res://audio/sfx/squirrel.ogg",
	"win": "res://audio/sfx/win.ogg",
	"whoosh": "res://audio/sfx/whoosh.ogg",
}


func _ready() -> void:
	rng.randomize()
	music.bus = &"Music"
	music.volume_db = -80.0
	add_child(music)
	ambience.bus = &"Music"
	ambience.volume_db = -22.0
	add_child(ambience)
	for i in range(10):
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		sfx_pool.append(player)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), GameState.muted)


func play_level(level_id: String) -> void:
	if current_track == level_id and music.playing:
		return
	current_track = level_id
	var path := "res://audio/music/%s.ogg" % level_id
	if not ResourceLoader.exists(path):
		return
	var next_stream = load(path)
	if next_stream is AudioStreamOggVorbis:
		next_stream.loop = true
	var tween := create_tween()
	tween.tween_property(music, "volume_db", -36.0, 0.22)
	tween.tween_callback(func():
		music.stream = next_stream
		music.play()
	)
	tween.tween_property(music, "volume_db", -8.0, 0.75)


func play_finale() -> void:
	current_track = "finale-home"
	var path := "res://audio/music/finale-home.ogg"
	if not ResourceLoader.exists(path):
		stop_music(0.5)
		return
	var finale_stream = load(path)
	if finale_stream is AudioStreamOggVorbis:
		finale_stream.loop = true
	var tween := create_tween()
	tween.tween_property(music, "volume_db", -38.0, 0.28)
	tween.tween_callback(func():
		music.stream = finale_stream
		music.play()
	)
	tween.tween_property(music, "volume_db", -7.0, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func play_intro() -> void:
	current_track = "intro-central-park"
	var path := "res://audio/music/intro-central-park.ogg"
	if not ResourceLoader.exists(path):
		stop_music(0.5)
		return
	var intro_stream = load(path)
	var tween := create_tween()
	tween.tween_property(music, "volume_db", -42.0, 0.2)
	tween.tween_callback(func():
		music.stream = intro_stream
		music.play()
	)
	tween.tween_property(music, "volume_db", -7.0, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func stop_music(fade := 0.6) -> void:
	var tween := create_tween()
	tween.tween_property(music, "volume_db", -80.0, fade)
	tween.tween_callback(music.stop)
	current_track = ""


func play_sfx(name: String, pitch := 1.0, volume_db := 0.0) -> void:
	var key := name
	if name == "bark":
		key = "bark_%d" % rng.randi_range(1, 3)
	var path: String = SFX.get(key, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var player := _available_player()
	player.stream = load(path)
	player.pitch_scale = pitch
	player.volume_db = volume_db
	player.play()


func duck_music(duration := 0.32) -> void:
	if not music.playing:
		return
	var tween := create_tween()
	tween.tween_property(music, "volume_db", -15.0, 0.06)
	tween.tween_interval(duration)
	tween.tween_property(music, "volume_db", -8.0, 0.2)


func _available_player() -> AudioStreamPlayer:
	for player in sfx_pool:
		if not player.playing:
			return player
	return sfx_pool[0]
