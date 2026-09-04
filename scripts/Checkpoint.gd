class_name JellyCheckpoint
extends Area2D

signal activated(location: Vector2, title: String)

var checkpoint_title := "Checkpoint"
var is_active := false
var accent := Color("#ef4b8f")


func configure(title: String, color: Color) -> void:
	checkpoint_title = title
	accent = color


func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(82, 110)
	collision.shape = shape
	collision.position = Vector2(0, -50)
	add_child(collision)
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-4, -82, 8, 82), Color("#6c4c3a"))
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#ffe66b") if is_active else Color("#fff9e6")
	box.border_width_left = 4
	box.border_width_top = 4
	box.border_width_right = 4
	box.border_width_bottom = 4
	box.border_color = Color("#f5a623") if is_active else accent
	for property in ["corner_radius_top_left", "corner_radius_top_right", "corner_radius_bottom_left", "corner_radius_bottom_right"]:
		box.set(property, 8)
	draw_style_box(box, Rect2(-55, -110, 110, 42))
	var label := "CHECKPOINT ✓" if is_active else "CHECKPOINT"
	draw_string(ThemeDB.fallback_font, Vector2(-45, -83), label, HORIZONTAL_ALIGNMENT_CENTER, 90, 11, Color("#173157"))
	if is_active:
		for i in range(5):
			var angle := Time.get_ticks_msec() * 0.0018 + i * TAU / 5.0
			draw_circle(Vector2(cos(angle) * 52, -88 + sin(angle) * 27), 3.0, Color("#ffe36a"))


func _on_body_entered(body: Node2D) -> void:
	if is_active or not body is JellyPlayer:
		return
	is_active = true
	AudioDirector.play_sfx("checkpoint", 1.0, -1.0)
	activated.emit(global_position + Vector2(0, -45), checkpoint_title)
	queue_redraw()

