class_name JellySpringPad
extends Area2D

var accent := Color("#ffdc62")
var cooldown := 0.0
var elapsed := 0.0


func configure(at: Vector2, color: Color) -> void:
	position = at
	accent = color


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(46, 18)
	collision.shape = shape
	collision.position = Vector2(0, -6)
	add_child(collision)
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _process(delta: float) -> void:
	elapsed += delta
	cooldown = maxf(0.0, cooldown - delta)
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body is JellyPlayer and cooldown <= 0.0 and body.velocity.y >= -80.0:
		cooldown = 0.45
		(body as JellyPlayer).spring(825.0)
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2(1.22, 0.66), 0.06)
		tween.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var pulse := 0.72 + sin(elapsed * 4.2) * 0.16
	draw_circle(Vector2.ZERO, 31.0, Color(accent, 0.10 * pulse))
	for i in range(3): draw_line(Vector2(-14 + i * 9, 3), Vector2(-7 + i * 9, -14), Color("#dbe9f2"), 3.0)
	draw_style_box(_box(accent.darkened(0.22)), Rect2(-25, -17, 50, 15))
	draw_style_box(_box(accent), Rect2(-29, -24, 58, 10))
	draw_string(ThemeDB.fallback_font, Vector2(-15, -27), "↑", HORIZONTAL_ALIGNMENT_CENTER, 30, 13, Color("#173157"))


func _box(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(6)
	box.set_border_width_all(2)
	box.border_color = color.lightened(0.25)
	return box
