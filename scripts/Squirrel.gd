class_name JellySquirrel
extends Area2D

signal befriended

var route: Array[Vector2] = []
var route_index := 0
var direction_step := 1
var chase_progress := 0.0
var state := "idle"
var state_time := 0.0
var caught := false
var player: JellyPlayer
var sprite := AnimatedSprite2D.new()


func configure(points: Array, target: JellyPlayer) -> void:
	player = target
	for point in points:
		route.append(Vector2(float(point[0]), float(point[1]) - 34.0))
	if not route.is_empty():
		global_position = route[0]


func _ready() -> void:
	add_to_group("squirrels")
	collision_layer = 8
	collision_mask = 2
	_build_animation()
	add_child(sprite)
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 25.0
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	state_time += delta
	if caught or route.size() < 2 or not is_instance_valid(player):
		return
	match state:
		"idle":
			sprite.animation = &"idle"
			position.y += sin(Time.get_ticks_msec() * 0.004) * 0.08
			if global_position.distance_to(player.global_position) < 275.0:
				state = "taunt"
				state_time = 0.0
				sprite.animation = &"taunt"
				AudioDirector.play_sfx("squirrel", 1.0, -2.0)
				get_tree().call_group("game", "show_toast", "Squirrel chase! Follow the golden leaves.")
		"taunt":
			if state_time > 0.68:
				state = "chase"
				state_time = 0.0
				chase_progress = 0.0
		"chase":
			sprite.animation = &"run"
			_move_along_route(delta)


func _move_along_route(delta: float) -> void:
	var next_index := route_index + direction_step
	if next_index < 0 or next_index >= route.size():
		direction_step *= -1
		next_index = route_index + direction_step
	var from := route[route_index]
	var to := route[next_index]
	var duration := maxf(0.42, from.distance_to(to) / 285.0)
	chase_progress = minf(1.0, chase_progress + delta / duration)
	var eased := ease(chase_progress, -1.8)
	global_position = from.lerp(to, eased)
	global_position.y -= sin(chase_progress * PI) * 72.0
	sprite.flip_h = to.x < from.x
	if chase_progress >= 1.0:
		route_index = next_index
		chase_progress = 0.0
		if route_index == 0 or route_index == route.size() - 1:
			state = "taunt"
			state_time = -0.15


func react_to_bark(origin: Vector2) -> void:
	if caught:
		return
	if global_position.distance_to(origin) < 245.0 and state == "idle":
		state = "taunt"
		state_time = 0.0


func _on_body_entered(body: Node2D) -> void:
	if caught or not body is JellyPlayer:
		return
	caught = true
	sprite.animation = &"friend"
	AudioDirector.play_sfx("squirrel", 1.18, -1.0)
	AudioDirector.play_sfx("checkpoint", 1.2, -4.0)
	befriended.emit()
	var tween := create_tween().set_loops()
	tween.tween_property(sprite, "position:y", -5.0, 0.35).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "position:y", 0.0, 0.35).set_trans(Tween.TRANS_SINE)


func _build_animation() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var sheet: Texture2D = load("res://assets/squirrel-sprites.png")
	_add_animation(frames, &"idle", sheet, [0, 1], 3.0, true)
	_add_animation(frames, &"taunt", sheet, [1, 4, 1], 7.0, true)
	_add_animation(frames, &"run", sheet, [2, 3, 5, 6], 11.0, true)
	_add_animation(frames, &"friend", sheet, [7, 0, 7], 4.0, true)
	sprite.sprite_frames = frames
	sprite.animation = &"idle"
	sprite.scale = Vector2(0.16, 0.16)


func _add_animation(frames: SpriteFrames, animation: StringName, sheet: Texture2D, indices: Array, fps: float, looped: bool) -> void:
	frames.add_animation(animation)
	frames.set_animation_speed(animation, fps)
	frames.set_animation_loop(animation, looped)
	for raw_index in indices:
		var index := int(raw_index)
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2((index % 4) * 444, (index / 4) * 444, 444, 444)
		frames.add_frame(animation, atlas)

