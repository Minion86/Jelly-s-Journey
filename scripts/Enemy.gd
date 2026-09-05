class_name JellyEnemy
extends CharacterBody2D

signal player_hit(source_x: float)
signal defeated(at: Vector2, color: Color)

enum State { IDLE, PATROL, ANTICIPATE, ATTACK, RECOVER, STUNNED, DEFEATED }

const BASE_SCALE := Vector2(0.25, 0.25)
const VARIANT_TINTS := [Color.WHITE, Color("#ffe8a8"), Color("#d8ddff")]

var enemy_kind := "patrol"
var world_index := 0
var variant := 0
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
var ground_probe := RayCast2D.new()
var phase := randf() * TAU
var home_y := 0.0
var dust: Array[Dictionary] = []
var defeated_once := false


func configure(kind: String, world: int, start: Vector2, target: JellyPlayer, enemy_variant := -1) -> void:
	enemy_kind = kind
	world_index = world
	variant = enemy_variant if enemy_variant >= 0 else int(absf(start.x / 97.0)) % 3
	home = start
	home_y = start.y
	player = target
	global_position = start
	patrol_radius = [112.0, 156.0, 198.0][variant]
	direction = -1.0 if int(start.x / 150.0) % 2 == 0 else 1.0


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	_build_animation()
	add_child(sprite)
	var body_shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 16.0 + variant * 1.5
	capsule.height = 37.0 + variant * 2.0
	body_shape.shape = capsule
	add_child(body_shape)
	hurt_area.collision_layer = 0
	hurt_area.collision_mask = 2
	var hurt_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 25.0 + variant * 2.0
	hurt_shape.shape = circle
	hurt_area.add_child(hurt_shape)
	add_child(hurt_area)
	hurt_area.body_entered.connect(_on_body_entered)
	ground_probe.collision_mask = 1
	ground_probe.enabled = true
	ground_probe.position = Vector2(0, 4)
	add_child(ground_probe)
	queue_redraw()


func _physics_process(delta: float) -> void:
	state_time += delta
	attack_cooldown -= delta
	_update_dust(delta)
	if state == State.DEFEATED:
		velocity.y += 1180.0 * delta
		move_and_slide()
		queue_redraw()
		return
	if stun_time > 0.0:
		stun_time -= delta
		state = State.STUNNED
		velocity.x = move_toward(velocity.x, 0.0, 850.0 * delta)
		move_and_slide()
		_animate(Vector2.ZERO, delta)
		queue_redraw()
		return
	elif state == State.STUNNED:
		_set_state(State.RECOVER)

	var distance := player.global_position - global_position if is_instance_valid(player) else Vector2(9999, 0)
	match state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta)
			if state_time > 0.38 + variant * 0.16:
				if variant == 1: direction *= -1.0
				_set_state(State.PATROL)
		State.PATROL:
			_patrol(delta, distance)
		State.ANTICIPATE:
			velocity.x = move_toward(velocity.x, 0.0, 1300.0 * delta)
			if enemy_kind == "hop" and is_on_floor():
				velocity.y = sin(state_time * 18.0) * -20.0
			if state_time > _anticipation_time():
				_set_state(State.ATTACK)
				AudioDirector.play_sfx("whoosh", randf_range(0.88, 1.12), -7.0)
		State.ATTACK:
			_attack(distance)
		State.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, 980.0 * delta)
			if enemy_kind == "dive":
				global_position.y = lerpf(global_position.y, home_y, minf(1.0, delta * 3.4))
			if state_time > 0.46 + variant * 0.08:
				attack_cooldown = 0.7 + variant * 0.3
				_set_state(State.IDLE if variant == 1 else State.PATROL)
	if enemy_kind != "dive" and not is_on_floor():
		velocity.y += 1500.0 * delta
	move_and_slide()
	_animate(distance, delta)
	queue_redraw()


func stun(duration := 1.65) -> void:
	if state == State.DEFEATED:
		return
	stun_time = maxf(stun_time, duration + variant * 0.12)
	velocity = Vector2(-direction * 145.0, -180.0)
	AudioDirector.play_sfx("checkpoint", 1.45, -8.0)
	_spawn_dust(Color("#ffe978"), 7)


func _patrol(_delta: float, distance: Vector2) -> void:
	var speeds := [68.0, 91.0, 116.0]
	var speed: float = speeds[variant]
	if enemy_kind == "dash": speed *= 1.28
	if enemy_kind == "hop": speed *= 0.82
	if enemy_kind == "climb": speed *= 1.08
	if enemy_kind == "dive":
		global_position.y = home_y + sin(Time.get_ticks_msec() * 0.0028 + phase) * (18.0 + variant * 5.0)
		velocity.y = 0.0
	velocity.x = direction * speed
	ground_probe.target_position = Vector2(direction * 31.0, 42.0)
	ground_probe.force_raycast_update()
	if enemy_kind != "dive" and is_on_floor() and not ground_probe.is_colliding():
		direction *= -1.0
		_set_state(State.IDLE)
	elif absf(global_position.x - home.x) > patrol_radius or is_on_wall():
		direction = -signf(global_position.x - home.x)
		_set_state(State.IDLE)
	elif state_time > 2.4 + fmod(phase, 1.1) and variant == 1:
		_set_state(State.IDLE)
	if absf(distance.x) < _notice_distance() and absf(distance.y) < 185.0 and attack_cooldown <= 0.0:
		direction = signf(distance.x) if absf(distance.x) > 4.0 else direction
		_set_state(State.ANTICIPATE)


func _attack(distance: Vector2) -> void:
	match enemy_kind:
		"dive":
			velocity = Vector2(direction * (270.0 + variant * 42.0), clampf(distance.y * 2.25, -220.0, 300.0))
		"dash":
			velocity.x = direction * (365.0 + variant * 52.0)
			if int(state_time * 18.0) % 3 == 0: _spawn_dust(Color("#d9efff"), 1)
		"music":
			velocity.x = direction * (110.0 + variant * 28.0)
			if state_time > 0.28 and state_time < 0.36:
				get_tree().call_group("game", "spawn_music_wave", global_position, direction)
		"hop":
			velocity.x = direction * (175.0 + variant * 32.0)
			if is_on_floor() and state_time < 0.16:
				velocity.y = -430.0 - variant * 45.0
		"climb":
			velocity.x = direction * (210.0 + variant * 35.0)
			if is_on_wall(): velocity.y = -350.0
		_:
			velocity.x = direction * (210.0 + variant * 35.0)
	if state_time > _attack_time():
		_set_state(State.RECOVER)


func _animate(_distance: Vector2, delta: float) -> void:
	sprite.flip_h = direction < 0.0
	var target_scale := BASE_SCALE * (0.92 + variant * 0.08)
	var target_rotation := 0.0
	match state:
		State.IDLE:
			sprite.play(&"idle")
			sprite.position.y = sin(state_time * 4.5 + phase) * 1.8 - 5.0
		State.PATROL:
			sprite.play(&"move")
			sprite.position.y = sin(state_time * 12.0 + phase) * 2.4 - 5.0
		State.ANTICIPATE:
			sprite.play(&"warn")
			target_scale *= Vector2(0.86, 1.16)
			target_rotation = -direction * 0.08
		State.ATTACK:
			sprite.play(&"attack")
			target_scale *= Vector2(1.18, 0.86)
			target_rotation = direction * 0.12
		State.RECOVER:
			sprite.play(&"recover")
			target_scale *= Vector2(1.08, 0.94)
		State.STUNNED:
			sprite.play(&"stun")
			target_rotation = sin(Time.get_ticks_msec() * 0.019) * 0.13
	sprite.scale = sprite.scale.lerp(target_scale, minf(1.0, delta * 13.0))
	sprite.rotation = lerpf(sprite.rotation, target_rotation, minf(1.0, delta * 11.0))
	sprite.modulate = VARIANT_TINTS[variant]


func _on_body_entered(body: Node2D) -> void:
	if not body is JellyPlayer or state == State.DEFEATED or stun_time > 0.0:
		return
	var jelly := body as JellyPlayer
	if jelly.velocity.y > 115.0 and jelly.global_position.y < global_position.y - 9.0:
		_defeat(jelly)
	else:
		player_hit.emit(global_position.x)


func _defeat(jelly: JellyPlayer) -> void:
	if defeated_once:
		return
	defeated_once = true
	state = State.DEFEATED
	hurt_area.set_deferred("monitoring", false)
	collision_layer = 0
	velocity = Vector2(direction * -85.0, -285.0)
	sprite.play(&"stun")
	jelly.spring(520.0)
	AudioDirector.play_sfx("squirrel", 1.3, -5.0)
	_spawn_dust(Color("#ffe978"), 12)
	defeated.emit(global_position, VARIANT_TINTS[variant])
	var tween := create_tween()
	tween.tween_property(sprite, "rotation", direction * TAU, 0.62)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.62).set_delay(0.24)
	tween.tween_callback(queue_free)


func _set_state(next: State) -> void:
	state = next
	state_time = 0.0


func _notice_distance() -> float:
	return (365.0 if enemy_kind in ["dive", "dash"] else 285.0) + variant * 34.0


func _anticipation_time() -> float:
	return maxf(0.32, (0.54 if enemy_kind == "dash" else 0.68) - variant * 0.08)


func _attack_time() -> float:
	return 0.68 if enemy_kind == "dash" else 0.88 + variant * 0.06


func _build_animation() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var sheet: Texture2D = load("res://assets/enemy-performances-v2.webp")
	var row := clampi(world_index, 0, 3)
	_add_row_animation(frames, &"idle", sheet, row, [0, 0, 1], 3.4, true)
	_add_row_animation(frames, &"move", sheet, row, [1, 2, 1, 0], 8.5 + variant, true)
	_add_row_animation(frames, &"warn", sheet, row, [3, 0, 3], 8.0, true)
	_add_row_animation(frames, &"attack", sheet, row, [4, 2, 4], 12.0, true)
	_add_row_animation(frames, &"recover", sheet, row, [2, 1, 0], 7.0, false)
	_add_row_animation(frames, &"stun", sheet, row, [5], 1.0, true)
	sprite.sprite_frames = frames
	sprite.animation = &"idle"
	sprite.scale = BASE_SCALE * (0.92 + variant * 0.08)
	sprite.position = Vector2(0, -5)


func _add_row_animation(frames: SpriteFrames, animation: StringName, sheet: Texture2D, row: int, columns: Array, fps: float, looped: bool) -> void:
	frames.add_animation(animation)
	frames.set_animation_speed(animation, fps)
	frames.set_animation_loop(animation, looped)
	for raw_column in columns:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(int(raw_column) * 256, row * 256, 256, 256)
		frames.add_frame(animation, atlas)


func _spawn_dust(color: Color, count: int) -> void:
	for i in range(count):
		dust.append({"p": Vector2(randf_range(-18, 18), randf_range(12, 25)), "v": Vector2(randf_range(-48, 48), randf_range(-80, -20)), "life": randf_range(0.25, 0.55), "c": color})


func _update_dust(delta: float) -> void:
	for bit in dust:
		bit.p += bit.v * delta
		bit.v.y += 180.0 * delta
		bit.life -= delta
	dust = dust.filter(func(bit): return bit.life > 0.0)


func _draw() -> void:
	if state == State.ANTICIPATE:
		var pulse := 24.0 + sin(state_time * 18.0) * 4.0
		draw_arc(Vector2(0, -8), pulse, 0, TAU, 28, Color(1, 0.85, 0.25, 0.72), 3.0)
	if state == State.ATTACK:
		for i in range(3):
			draw_line(Vector2(-direction * (24 + i * 13), -10 + i * 8), Vector2(-direction * (48 + i * 17), -10 + i * 8), Color(1, 1, 1, 0.24), 3.0)
	for bit in dust:
		var color: Color = bit.c
		color.a = clampf(bit.life * 2.0, 0.0, 0.7)
		draw_circle(bit.p, 2.0 + bit.life * 4.0, color)
