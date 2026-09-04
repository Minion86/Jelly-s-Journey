class_name JellyPlatform
extends AnimatableBody2D

var platform_size := Vector2(200, 40)
var surface_color := Color("#72b65d")
var body_color := Color("#5c7848")
var accent_color := Color("#ffffff")
var platform_label := ""
var movement_axis := ""
var movement_distance := 0.0
var movement_speed := 0.0
var movement_phase := 0.0
var origin := Vector2.ZERO


func configure(rect: Array, colors: Array[Color], label := "") -> void:
	position = Vector2(float(rect[0]), float(rect[1]))
	platform_size = Vector2(float(rect[2]), float(rect[3]))
	surface_color = colors[0]
	body_color = colors[1]
	accent_color = colors[2]
	platform_label = label
	origin = position


func configure_movement(axis: String, distance: float, speed: float, phase: float) -> void:
	movement_axis = axis
	movement_distance = distance
	movement_speed = speed
	movement_phase = phase
	sync_to_physics = true


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = platform_size
	collision.shape = shape
	collision.position = platform_size * 0.5
	add_child(collision)
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if movement_axis.is_empty():
		return
	var wave := sin(Time.get_ticks_msec() * 0.001 * movement_speed + movement_phase) * movement_distance
	position = origin + (Vector2(wave, 0) if movement_axis == "x" else Vector2(0, wave))


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, platform_size)
	draw_style_box(_box(body_color, 16.0), rect)
	draw_style_box(_box(surface_color, 12.0), Rect2(0, 0, platform_size.x, minf(18.0, platform_size.y)))
	for x in range(18, int(platform_size.x) - 10, 48):
		draw_rect(Rect2(x, 35, 23, 4), Color(1, 1, 1, 0.11))
	if not platform_label.is_empty():
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(platform_size.x * 0.5 - platform_label.length() * 3.5, 17), platform_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#173157"))


func _box(color: Color, radius: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.corner_radius_top_left = int(radius)
	box.corner_radius_top_right = int(radius)
	box.corner_radius_bottom_left = int(radius)
	box.corner_radius_bottom_right = int(radius)
	box.border_width_top = 2
	box.border_color = Color(color, 0.86).lightened(0.18)
	return box

