class_name JellyPlayer
extends CharacterBody2D

signal barked(origin: Vector2, direction: float)
signal damaged
signal landed(hard: bool)

const WALK_SPEED := 255.0
const RUN_SPEED := 360.0
const GROUND_ACCEL := 1900.0
const AIR_ACCEL := 1120.0
const FRICTION := 2300.0
const GRAVITY := 1880.0
const JUMP_SPEED := -690.0
const COYOTE_TIME := 0.13
const JUMP_BUFFER := 0.15

var sprite := AnimatedSprite2D.new()
var coyote_left := 0.0
var jump_buffer_left := 0.0
var bark_cooldown := 0.0
var invulnerability := 0.0
var idle_time := 0.0
var facing := 1.0
var control_enabled := true
var spawn_point := Vector2.ZERO
var was_grounded := false
var last_vertical_speed := 0.0
var dust_timer := 0.0
var move_hold_time := 0.0


func _ready() -> void:
	name = "Jelly"
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	_build_animations()
	add_child(sprite)
	var shape_node := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 20.0
	shape.height = 48.0
	shape_node.shape = shape
	shape_node.position = Vector2(0, 1)
	add_child(shape_node)
	spawn_point = global_position


func _physics_process(delta: float) -> void:
	bark_cooldown = maxf(0.0, bark_cooldown - delta)
	invulnerability = maxf(0.0, invulnerability - delta)
	jump_buffer_left = maxf(0.0, jump_buffer_left - delta)
	coyote_left = COYOTE_TIME if is_on_floor() else maxf(0.0, coyote_left - delta)
	last_vertical_speed = velocity.y
	var axis := Input.get_axis("move_left", "move_right") if control_enabled else 0.0
	move_hold_time = move_hold_time + delta if absf(axis) > 0.8 else 0.0
	var touch_run := DisplayServer.is_touchscreen_available() and move_hold_time > 0.48
	var target_speed := (RUN_SPEED if Input.is_action_pressed("sprint") or touch_run else WALK_SPEED) * axis
	var acceleration := GROUND_ACCEL if is_on_floor() else AIR_ACCEL
	if absf(axis) > 0.01:
		velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
		facing = signf(axis)
		idle_time = 0.0
	else:
		move_hold_time = 0.0
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta if is_on_floor() else AIR_ACCEL * 0.18 * delta)
		if is_on_floor():
			idle_time += delta

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if control_enabled and Input.is_action_just_pressed("jump"):
		jump_buffer_left = JUMP_BUFFER
	if jump_buffer_left > 0.0 and coyote_left > 0.0:
		velocity.y = JUMP_SPEED
		jump_buffer_left = 0.0
		coyote_left = 0.0
		AudioDirector.play_sfx("jump", randf_range(0.96, 1.04), -1.0)
		_squash(Vector2(0.84, 1.18))
	if control_enabled and Input.is_action_just_released("jump") and velocity.y < -240.0:
		velocity.y *= 0.48
	if control_enabled and Input.is_action_just_pressed("bark"):
		bark()

	was_grounded = is_on_floor()
	move_and_slide()
	if not was_grounded and is_on_floor():
		var hard := last_vertical_speed > 720.0
		AudioDirector.play_sfx("land", 0.92 if hard else 1.08, -4.0)
		_squash(Vector2(1.2 if hard else 1.1, 0.78 if hard else 0.88))
		landed.emit(hard)
	_update_animation()
	_update_motion_style(delta)


func bark() -> void:
	if bark_cooldown > 0.0:
		return
	bark_cooldown = 0.72
	idle_time = 0.0
	sprite.play(&"bark")
	AudioDirector.play_sfx("bark", randf_range(0.94, 1.07), -0.5)
	AudioDirector.duck_music(0.18)
	barked.emit(global_position + Vector2(facing * 35.0, -7.0), facing)
	_squash(Vector2(1.16, 0.9))


func take_damage(source_x: float) -> bool:
	if invulnerability > 0.0:
		return false
	invulnerability = 1.65
	velocity = Vector2(signf(global_position.x - source_x) * 360.0, -390.0)
	AudioDirector.play_sfx("hurt", 1.0, -1.0)
	sprite.play(&"hurt")
	damaged.emit()
	return true


func spring(strength := 760.0) -> void:
	velocity.y = -strength
	_squash(Vector2(0.78, 1.24))
	AudioDirector.play_sfx("whoosh", randf_range(0.94, 1.08), -4.0)


func push_wind(direction: float, amount: float) -> void:
	velocity.x += direction * amount


func respawn(at: Vector2) -> void:
	global_position = at
	velocity = Vector2.ZERO
	invulnerability = 1.25
	control_enabled = true


func celebrate() -> void:
	control_enabled = false
	velocity.x = 0.0
	sprite.play(&"happy")
	_squash(Vector2(1.14, 0.9))


func _update_animation() -> void:
	if bark_cooldown > 0.46:
		return
	if invulnerability > 1.25:
		sprite.play(&"hurt")
	elif not is_on_floor():
		sprite.play(&"jump" if velocity.y < 80.0 else &"fall")
	elif absf(velocity.x) > 45.0:
		sprite.speed_scale = clampf(absf(velocity.x) / WALK_SPEED, 0.85, 1.55)
		sprite.play(&"run")
	elif idle_time > 14.0:
		sprite.speed_scale = 1.0
		sprite.play(&"sleep")
	elif idle_time > 9.0:
		sprite.speed_scale = 1.0
		sprite.play(&"sit")
	elif idle_time > 5.0:
		sprite.speed_scale = 1.0
		sprite.play(&"sniff")
	else:
		sprite.speed_scale = 1.0
		sprite.play(&"idle_cycle")


func _update_motion_style(delta: float) -> void:
	sprite.flip_h = facing < 0.0
	var target_rotation := clampf(velocity.x / RUN_SPEED * 0.055, -0.055, 0.055)
	if not is_on_floor():
		target_rotation += clampf(velocity.y / 900.0, -0.08, 0.11)
	sprite.rotation = lerpf(sprite.rotation, target_rotation, delta * 9.0)
	if invulnerability > 0.0:
		sprite.modulate.a = 0.35 if int(invulnerability * 16.0) % 2 == 0 else 1.0
	else:
		sprite.modulate.a = 1.0


func _squash(target: Vector2) -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "scale", target * 0.21, 0.07)
	tween.tween_property(sprite, "scale", Vector2(0.21, 0.21), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _build_animations() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var main_sheet: Texture2D = load("res://assets/jelly-sprites.png")
	var idle_sheet: Texture2D = load("res://assets/jelly-idle-v4.png")
	_add_animation(frames, &"idle_cycle", idle_sheet, Vector2i(362, 724), [0, 1, 2, 3, 4, 5], 5.0, true)
	_add_animation(frames, &"run", main_sheet, Vector2i(362, 362), [1, 2, 1, 0], 10.0, true)
	_add_animation(frames, &"jump", main_sheet, Vector2i(362, 362), [3], 1.0, false)
	_add_animation(frames, &"fall", main_sheet, Vector2i(362, 362), [4], 1.0, false)
	_add_animation(frames, &"sniff", main_sheet, Vector2i(362, 362), [5, 0, 5, 0], 3.0, true)
	_add_animation(frames, &"bark", main_sheet, Vector2i(362, 362), [6, 6, 7], 12.0, false)
	_add_animation(frames, &"happy", main_sheet, Vector2i(362, 362), [7, 9, 7, 9], 5.0, true)
	_add_animation(frames, &"hurt", main_sheet, Vector2i(362, 362), [8], 1.0, false)
	_add_animation(frames, &"sit", main_sheet, Vector2i(362, 362), [9, 11, 9, 11], 3.0, true)
	_add_animation(frames, &"sleep", main_sheet, Vector2i(362, 362), [10], 1.0, true)
	sprite.sprite_frames = frames
	sprite.animation = &"idle_cycle"
	sprite.scale = Vector2(0.21, 0.21)
	sprite.position = Vector2(0, -6)


func _add_animation(frames: SpriteFrames, animation: StringName, texture: Texture2D, cell: Vector2i, indices: Array, fps: float, looped: bool) -> void:
	frames.add_animation(animation)
	frames.set_animation_speed(animation, fps)
	frames.set_animation_loop(animation, looped)
	var columns := maxi(1, texture.get_width() / cell.x)
	for raw_index in indices:
		var index := int(raw_index)
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2((index % columns) * cell.x, (index / columns) * cell.y, cell.x, cell.y)
		frames.add_frame(animation, atlas)
