class_name JellyEnemy
extends CharacterBody2D

signal player_hit(source_x: float)

enum State { PATROL, ANTICIPATE, ATTACK, RECOVER, STUNNED }

var enemy_kind := "patrol"
var world_index := 0
var home := Vector2.ZERO
var direction := -1.0
var state := State.PATROL
var state_time := 0.0
var attack_cooldown := 0.7
var stun_time := 0.0
var patrol_radius := 125.0
var player: JellyPlayer
var sprite := AnimatedSprite2D.new()
var hurt_area := Area2D.new()
var phase := randf() * TAU
var home_y := 0.0


func configure(kind: String, world: int, start: Vector2, target: JellyPlayer) -> void:
	enemy_kind = kind
	world_index = world
	home = start
	home_y = start.y
	player = target
	global_position = start


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	_build_animation()
	add_child(sprite)
	var body_shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 17.0
	capsule.height = 38.0
	body_shape.shape = capsule
	add_child(body_shape)
	hurt_area.collision_layer = 0
	hurt_area.collision_mask = 2
	var hurt_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 27.0
	hurt_shape.shape = circle
	hurt_area.add_child(hurt_shape)
	add_child(hurt_area)
	hurt_area.body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	state_time += delta
	attack_cooldown -= delta
	if stun_time > 0.0:
		stun_time -= delta
		state = State.STUNNED
		velocity.x = move_toward(velocity.x, 0.0, 850.0 * delta)
		sprite.animation = &"stun"
		sprite.rotation = sin(Time.get_ticks_msec() * 0.018) * 0.1
		move_and_slide()
		return
	elif state == State.STUNNED:
		state = State.RECOVER
		state_time = 0.0
		sprite.rotation = 0.0

	var distance := player.global_position - global_position if is_instance_valid(player) else Vector2(9999, 0)
	match state:
		State.PATROL:
			_patrol(delta, distance)
		State.ANTICIPATE:
			velocity.x = move_toward(velocity.x, 0.0, 1100.0 * delta)
			if state_time > _anticipation_time():
				state = State.ATTACK
				state_time = 0.0
				AudioDirector.play_sfx("whoosh", randf_range(0.86, 1.08), -7.0)
		State.ATTACK:
			_attack(delta, distance)
		State.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, 950.0 * delta)
			if state_time > 0.55:
				state = State.PATROL
				state_time = 0.0
				attack_cooldown = 1.0
	if enemy_kind != "dive" and not is_on_floor():
		velocity.y += 1500.0 * delta
	move_and_slide()
	_animate(distance)


func stun(duration := 1.65) -> void:
	stun_time = maxf(stun_time, duration)
	velocity = Vector2(-direction * 145.0, -180.0)
	AudioDirector.play_sfx("checkpoint", 1.45, -8.0)


func _patrol(delta: float, distance: Vector2) -> void:
	var speed := 72.0
	if enemy_kind == "dash": speed = 112.0
	if enemy_kind == "hop": speed = 56.0
	if enemy_kind == "climb": speed = 82.0
	if enemy_kind == "dive":
		global_position.y = home_y + sin(Time.get_ticks_msec() * 0.0025 + phase) * 18.0
		velocity.y = 0.0
	velocity.x = direction * speed
	if absf(global_position.x - home.x) > patrol_radius:
		direction = -signf(global_position.x - home.x)
	if is_on_wall():
		direction *= -1.0
	if absf(distance.x) < _notice_distance() and absf(distance.y) < 185.0 and attack_cooldown <= 0.0:
		direction = signf(distance.x)
		state = State.ANTICIPATE
		state_time = 0.0


func _attack(_delta: float, distance: Vector2) -> void:
	match enemy_kind:
		"dive":
			velocity = Vector2(direction * 285.0, clampf(distance.y * 2.2, -210.0, 285.0))
		"dash":
			velocity.x = direction * 395.0
		"music":
			velocity.x = direction * 125.0
			if state_time > 0.35 and state_time < 0.42:
				get_tree().call_group("game", "spawn_music_wave", global_position, direction)
		"hop":
			velocity.x = direction * 190.0
			if is_on_floor() and state_time < 0.16:
				velocity.y = -430.0
		"climb":
			velocity.x = direction * 230.0
			if is_on_wall(): velocity.y = -330.0
	if state_time > _attack_time():
		state = State.RECOVER
		state_time = 0.0


func _animate(distance: Vector2) -> void:
	sprite.flip_h = direction < 0.0
	match state:
		State.PATROL:
			sprite.animation = &"move"
		State.ANTICIPATE:
			sprite.animation = &"warn"
			sprite.scale = Vector2(0.162, 0.162) * Vector2(0.9, 1.1)
		State.ATTACK:
			sprite.animation = &"attack"
			sprite.scale = Vector2(0.162, 0.162) * Vector2(1.14, 0.9)
		State.RECOVER:
			sprite.animation = &"recover"
	if state not in [State.ANTICIPATE, State.ATTACK]:
		sprite.scale = sprite.scale.lerp(Vector2(0.162, 0.162), 0.22)
	if absf(distance.x) < 300.0:
		sprite.modulate = Color.WHITE


func _on_body_entered(body: Node2D) -> void:
	if body is JellyPlayer and stun_time <= 0.0:
		player_hit.emit(global_position.x)


func _notice_distance() -> float:
	return 360.0 if enemy_kind in ["dive", "dash"] else 280.0


func _anticipation_time() -> float:
	return 0.55 if enemy_kind == "dash" else 0.7


func _attack_time() -> float:
	return 0.72 if enemy_kind == "dash" else 0.9


func _build_animation() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var sheet: Texture2D = load("res://assets/city-enemies.png")
	var row := clampi(world_index, 0, 3)
	_add_row_animation(frames, &"move", sheet, row, [0, 1], 6.0, true)
	_add_row_animation(frames, &"warn", sheet, row, [0, 1, 0], 10.0, true)
	_add_row_animation(frames, &"attack", sheet, row, [2, 1, 2], 11.0, true)
	_add_row_animation(frames, &"recover", sheet, row, [1, 0], 5.0, false)
	_add_row_animation(frames, &"stun", sheet, row, [3], 1.0, true)
	sprite.sprite_frames = frames
	sprite.animation = &"move"
	sprite.scale = Vector2(0.162, 0.162)


func _add_row_animation(frames: SpriteFrames, animation: StringName, sheet: Texture2D, row: int, columns: Array, fps: float, looped: bool) -> void:
	frames.add_animation(animation)
	frames.set_animation_speed(animation, fps)
	frames.set_animation_loop(animation, looped)
	for raw_column in columns:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(int(raw_column) * 384, row * 256, 384, 256)
		frames.add_frame(animation, atlas)

