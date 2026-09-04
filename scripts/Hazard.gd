class_name JellyHazard
extends Area2D

var hazard_kind := "steam"
var hazard_size := Vector2(70, 30)
var phase := 0.0
var active := true
var cooldown := 0.0
var player_inside: JellyPlayer


func configure(kind: String, rect: Rect2, start_phase: float) -> void:
	hazard_kind = kind
	position = rect.position
	hazard_size = rect.size
	phase = start_phase


func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(maxf(26.0, hazard_size.x), maxf(34.0, hazard_size.y))
	collision.shape = shape
	collision.position = Vector2(hazard_size.x * 0.5, -shape.size.y * 0.35)
	add_child(collision)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	queue_redraw()


func _physics_process(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	active = sin(Time.get_ticks_msec() * 0.00265 + phase) > -0.2
	if is_instance_valid(player_inside) and active:
		if hazard_kind in ["leaf-gust", "brass-gust", "moss-gust"]:
			player_inside.push_wind(-1.0 if phase < 0.0 else 1.0, 260.0 * delta)
	queue_redraw()


func _draw() -> void:
	var beat := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.00265 + phase)
	if hazard_kind == "slick":
		draw_colored_polygon(PackedVector2Array([Vector2(0, 3), Vector2(hazard_size.x, 3), Vector2(hazard_size.x - 14, -7), Vector2(14, -7)]), Color(0.58, 0.9, 0.95, 0.65))
		return
	if hazard_kind in ["leaf-gust", "brass-gust", "moss-gust"]:
		var color := Color("#ffe873") if hazard_kind == "brass-gust" else Color(1, 0.98, 0.78, 0.7)
		for i in range(4):
			var y := -25.0 - i * 28.0
			draw_arc(Vector2(i * 68 + 20, y), 18.0 + beat * 10.0, 0.2, 5.4, 22, color, 3.0)
		return
	if hazard_kind == "spotlight":
		draw_colored_polygon(PackedVector2Array([Vector2(hazard_size.x * 0.45, 0), Vector2(0, 250), Vector2(hazard_size.x, 250), Vector2(hazard_size.x * 0.55, 0)]), Color(1, 0.96, 0.55, 0.28 + beat * 0.2))
		return
	if hazard_kind == "orange-bounce":
		draw_circle(Vector2(hazard_size.x * 0.5, 0), 27.0 + beat * 5.0, Color("#f39a2d"))
		draw_line(Vector2(hazard_size.x * 0.5, -30), Vector2(hazard_size.x * 0.5 + 5, -42), Color("#529653"), 5)
		return
	if hazard_kind == "skate-ramp":
		draw_colored_polygon(PackedVector2Array([Vector2.ZERO, Vector2(hazard_size.x, 0), Vector2(hazard_size.x, -5), Vector2(hazard_size.x * 0.5, -38 - beat * 7)]), Color("#f4c55f"))
		return
	var water_color := Color(0.63, 0.94, 1.0, 0.82)
	for i in range(3):
		var x := hazard_size.x * 0.5 + (i - 1) * 14
		draw_arc(Vector2(x, 0), 18 + beat * 22, PI, TAU, 18, water_color, 4)


func _on_body_entered(body: Node2D) -> void:
	if not body is JellyPlayer:
		return
	player_inside = body
	if not active or cooldown > 0.0:
		return
	if hazard_kind in ["steam", "fountain", "skate-ramp", "wave", "bubble", "orange-bounce", "sprinkler"]:
		cooldown = 0.75
		body.spring(610.0 if hazard_kind == "wave" else 770.0)


func _on_body_exited(body: Node2D) -> void:
	if body == player_inside:
		player_inside = null

