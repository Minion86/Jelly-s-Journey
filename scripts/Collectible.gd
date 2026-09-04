class_name JellyTreat
extends Area2D

signal collected

var base_y := 0.0
var phase := randf() * TAU
var taken := false


func _ready() -> void:
	add_to_group("treats")
	collision_layer = 8
	collision_mask = 2
	base_y = position.y
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 19.0
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _process(_delta: float) -> void:
	if taken:
		return
	position.y = base_y + sin(Time.get_ticks_msec() * 0.004 + phase) * 5.0
	rotation = sin(Time.get_ticks_msec() * 0.003 + phase) * 0.12
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(-16, -5), 8, Color("#ffd782"))
	draw_circle(Vector2(16, 5), 8, Color("#ffd782"))
	draw_style_box(_bone_box(), Rect2(-18, -10, 36, 20))
	draw_arc(Vector2.ZERO, 23, 0, TAU, 24, Color(1, 0.95, 0.6, 0.26), 3)


func _bone_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#ed9f39")
	box.corner_radius_top_left = 9
	box.corner_radius_top_right = 9
	box.corner_radius_bottom_left = 9
	box.corner_radius_bottom_right = 9
	return box


func _on_body_entered(body: Node2D) -> void:
	if taken or not body is JellyPlayer:
		return
	taken = true
	AudioDirector.play_sfx("treat", randf_range(0.96, 1.08), -2.0)
	collected.emit()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.18)
	tween.tween_property(self, "modulate:a", 0.0, 0.18)
	await tween.finished
	queue_free()

