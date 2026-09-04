class_name JellyGoal
extends Area2D

signal reached

var is_home := false
var accent := Color("#ef4b8f")
var used := false


func configure(home: bool, color: Color) -> void:
	is_home = home
	accent = color


func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(92, 108)
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.004) * 0.04
	draw_set_transform(Vector2.ZERO, 0, Vector2(pulse, pulse))
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#fffdf2")
	box.border_width_left = 6
	box.border_width_top = 6
	box.border_width_right = 6
	box.border_width_bottom = 6
	box.border_color = accent
	box.corner_radius_top_left = 18
	box.corner_radius_top_right = 18
	box.corner_radius_bottom_left = 18
	box.corner_radius_bottom_right = 18
	draw_style_box(box, Rect2(-46, -54, 92, 108))
	if is_home:
		draw_colored_polygon(PackedVector2Array([Vector2(-27, -5), Vector2(0, -31), Vector2(27, -5)]), accent)
		draw_rect(Rect2(-21, -5, 42, 34), accent.lightened(0.18))
		draw_rect(Rect2(-6, 11, 12, 18), Color("#fff6d8"))
	else:
		draw_colored_polygon(PackedVector2Array([Vector2(-27, -15), Vector2(27, -15), Vector2(27, 22), Vector2(-27, 22)]), Color("#fff6d8"))
		draw_polyline(PackedVector2Array([Vector2(-27, -15), Vector2(0, 5), Vector2(27, -15)]), accent, 4)
	var label := "HOME" if is_home else "CLUE"
	draw_string(ThemeDB.fallback_font, Vector2(-31, 44), label, HORIZONTAL_ALIGNMENT_CENTER, 62, 12, Color("#173157"))


func _on_body_entered(body: Node2D) -> void:
	if used or not body is JellyPlayer:
		return
	used = true
	reached.emit()

