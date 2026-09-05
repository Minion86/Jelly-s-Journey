class_name JellyPlatform
extends AnimatableBody2D

var platform_size := Vector2(200, 40)
var surface_color := Color("#72b65d")
var body_color := Color("#5c7848")
var accent_color := Color.WHITE
var platform_label := ""
var world_index := 0
var movement_axis := ""
var movement_distance := 0.0
var movement_speed := 0.0
var movement_phase := 0.0
var origin := Vector2.ZERO
var elapsed := 0.0
var detail_seed := 0


func configure(rect: Array, colors: Array[Color], label := "", world := 0) -> void:
	position = Vector2(float(rect[0]), float(rect[1]))
	platform_size = Vector2(float(rect[2]), float(rect[3]))
	surface_color = colors[0]
	body_color = colors[1]
	accent_color = colors[2]
	platform_label = label
	world_index = world
	detail_seed = int(position.x / 47.0) % 7
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


func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if movement_axis.is_empty():
		return
	var wave := sin(Time.get_ticks_msec() * 0.001 * movement_speed + movement_phase) * movement_distance
	position = origin + (Vector2(wave, 0) if movement_axis == "x" else Vector2(0, wave))


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, platform_size)
	draw_style_box(_box(body_color, 15.0), rect)
	draw_style_box(_box(surface_color, 11.0), Rect2(0, 0, platform_size.x, minf(19.0, platform_size.y)))
	for x in range(18, int(platform_size.x) - 10, 44):
		draw_rect(Rect2(x, 35, 22, 4), Color(1, 1, 1, 0.11))
	_draw_world_details()
	if not movement_axis.is_empty(): _draw_moving_mechanism()
	if not platform_label.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(platform_size.x * 0.5 - platform_label.length() * 3.5, 17), platform_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#173157"))


func _draw_world_details() -> void:
	match world_index:
		0:
			for x in range(22 + detail_seed * 3, int(platform_size.x) - 8, 58):
				draw_rect(Rect2(x, 25, 28, 13), Color("#294f6a"))
				draw_rect(Rect2(x + 5, 28, 5, 5), Color("#ffd86c") if int(elapsed * 2 + x) % 5 else Color("#ff7aa8"))
			draw_rect(Rect2(0, 0, platform_size.x, 5), Color("#ffe05b"))
		1:
			for x in range(24, int(platform_size.x), 54):
				draw_circle(Vector2(x, 10), 4.0, Color("#fff4bd"))
				draw_line(Vector2(x - 8, 31), Vector2(x + 12, 25), Color("#68dbea"), 3.0)
		2:
			for x in range(12, int(platform_size.x), 46):
				draw_line(Vector2(x, 17), Vector2(x + sin(elapsed * 1.7 + x) * 7, 43), Color("#4c8c55"), 3.0)
				if x % 2 == 0: draw_circle(Vector2(x + 6, 8), 3.5, Color("#f6cf58"))
		3:
			for x in range(24, int(platform_size.x), 52):
				draw_circle(Vector2(x, 10), 5.0, Color("#f49b31"))
				draw_line(Vector2(x, 5), Vector2(x + 3, 1), Color("#397b59"), 2.0)
				draw_circle(Vector2(x + 18, 29), 2.0 + sin(elapsed * 3 + x) * 0.5, Color("#ffb8d0"))
	for x in range(10, int(platform_size.x) - 4, 34):
		var sway := sin(elapsed * 2.1 + x * 0.08) * 3.0
		draw_line(Vector2(x, 1), Vector2(x + sway, -7 - (x + detail_seed) % 5), surface_color.lightened(0.24), 2.0)


func _draw_moving_mechanism() -> void:
	var glow := 0.45 + 0.25 * sin(elapsed * 5.0 + movement_phase)
	for x in [14.0, platform_size.x - 14.0]:
		draw_circle(Vector2(x, platform_size.y * 0.55), 6.0, Color(accent_color, glow))
		draw_arc(Vector2(x, platform_size.y * 0.55), 10.0, elapsed * 2.0, elapsed * 2.0 + PI * 1.45, 12, Color(accent_color, 0.45), 2.0)
	for x in range(36, int(platform_size.x) - 22, 38):
		draw_colored_polygon(PackedVector2Array([Vector2(x, platform_size.y - 8), Vector2(x + 8, platform_size.y - 16), Vector2(x + 16, platform_size.y - 8)]), Color(accent_color, 0.22))


func _box(color: Color, radius: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(int(radius))
	box.border_width_top = 2
	box.border_color = Color(color, 0.86).lightened(0.18)
	return box
