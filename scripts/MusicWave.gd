class_name JellyMusicWave
extends Area2D

var direction := 1.0
var lifetime := 1.6


func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 18.0
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position.x += direction * 255.0 * delta
	lifetime -= delta
	rotation += direction * delta * 2.0
	queue_redraw()
	if lifetime <= 0.0:
		queue_free()


func _draw() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(-12, 10), "♫", HORIZONTAL_ALIGNMENT_CENTER, 24, 28, Color("#ffd34f"))


func _on_body_entered(body: Node2D) -> void:
	if body is JellyPlayer:
		body.take_damage(global_position.x)
		queue_free()

