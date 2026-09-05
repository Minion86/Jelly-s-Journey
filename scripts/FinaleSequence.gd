class_name JellyFinaleSequence
extends Control

signal replay_requested

const CAPTIONS := [
	"Every night, two porch lights waited for one little dog.",
	"Then came the sound they had dreamed about—a tiny bark at the gate.",
	"Jelly!",
	"No more cities. No more storms. No more miles apart.",
	"Just three hearts finding their way back into one home.",
	"Home is wherever we are together.",
]
const FRAME_HOLDS := [1.9, 1.65, 1.55, 1.8, 1.9]
const BASE_SCALE := Vector2(0.78, 0.78)

var elapsed := 0.0
var sequence_generation := 0
var completed := false
var epilogue_text := ""
var active_sprite: Sprite2D
var standby_sprite: Sprite2D
var active_tween: Tween
var caption := Label.new()
var finale_title := Label.new()
var finale_body := Label.new()
var hint := Label.new()
var replay_button := Button.new()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_sprites()
	_build_copy()
	queue_redraw()


func configure(epilogue: String) -> void:
	epilogue_text = epilogue


func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()


func play() -> void:
	sequence_generation += 1
	var generation := sequence_generation
	completed = false
	active_sprite.frame = 0
	active_sprite.modulate.a = 0.0
	standby_sprite.modulate.a = 0.0
	caption.text = CAPTIONS[0]
	caption.modulate.a = 0.0
	finale_title.modulate.a = 0.0
	finale_body.modulate.a = 0.0
	hint.modulate.a = 0.0
	replay_button.modulate.a = 0.0
	replay_button.hide()
	var opening := create_tween().set_parallel(true)
	opening.tween_property(active_sprite, "modulate:a", 1.0, 1.15)
	opening.tween_property(caption, "modulate:a", 1.0, 0.8).set_delay(0.35)
	await opening.finished
	if generation != sequence_generation:
		return
	for frame_index in range(1, 6):
		await get_tree().create_timer(FRAME_HOLDS[frame_index - 1]).timeout
		if generation != sequence_generation:
			return
		await _transition_to(frame_index)
		if generation != sequence_generation:
			return
	await get_tree().create_timer(1.0).timeout
	if generation == sequence_generation:
		_finish_sequence(false)


func advance() -> void:
	if completed:
		replay_requested.emit()
		return
	sequence_generation += 1
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	active_sprite.frame = 5
	active_sprite.modulate.a = 1.0
	active_sprite.scale = BASE_SCALE
	active_sprite.position = Vector2(480, 250)
	standby_sprite.modulate.a = 0.0
	caption.text = CAPTIONS[5]
	caption.modulate.a = 1.0
	_finish_sequence(true)


func _transition_to(frame_index: int) -> void:
	standby_sprite.frame = frame_index
	standby_sprite.position = Vector2(480, 256)
	standby_sprite.scale = BASE_SCALE * 0.96
	standby_sprite.modulate = Color(1, 1, 1, 0)
	var old_caption := caption.modulate
	caption.modulate.a = 0.0
	caption.text = CAPTIONS[frame_index]
	active_tween = create_tween().set_parallel(true)
	active_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	active_tween.tween_property(active_sprite, "modulate:a", 0.0, 0.72)
	active_tween.tween_property(active_sprite, "scale", BASE_SCALE * 1.025, 0.72)
	active_tween.tween_property(standby_sprite, "modulate:a", 1.0, 0.72)
	active_tween.tween_property(standby_sprite, "scale", BASE_SCALE, 0.72)
	active_tween.tween_property(standby_sprite, "position:y", 250.0, 0.72)
	active_tween.tween_property(caption, "modulate:a", old_caption.a, 0.5).set_delay(0.28)
	await active_tween.finished
	var old := active_sprite
	active_sprite = standby_sprite
	standby_sprite = old
	standby_sprite.modulate.a = 0.0


func _finish_sequence(immediate: bool) -> void:
	completed = true
	finale_title.text = "JELLY IS HOME"
	finale_body.text = epilogue_text
	hint.text = "Their adventure ended where every good journey should—together."
	replay_button.show()
	var reveal := create_tween().set_parallel(true)
	reveal.tween_property(finale_title, "modulate:a", 1.0, 0.35 if immediate else 0.8)
	reveal.tween_property(finale_body, "modulate:a", 1.0, 0.45 if immediate else 1.0).set_delay(0.08)
	reveal.tween_property(hint, "modulate:a", 1.0, 0.45 if immediate else 0.9).set_delay(0.18)
	reveal.tween_property(replay_button, "modulate:a", 1.0, 0.4).set_delay(0.24)


func _build_sprites() -> void:
	var sheet: Texture2D = load("res://assets/parents-reunion-sprites-v1.webp")
	active_sprite = Sprite2D.new()
	standby_sprite = Sprite2D.new()
	for sprite in [active_sprite, standby_sprite]:
		sprite.texture = sheet
		sprite.hframes = 3
		sprite.vframes = 2
		sprite.position = Vector2(480, 250)
		sprite.scale = BASE_SCALE
		sprite.centered = true
		add_child(sprite)
	standby_sprite.modulate.a = 0.0


func _build_copy() -> void:
	caption.position = Vector2(120, 28)
	caption.size = Vector2(720, 48)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(caption, 19, Color("#fff5d7"), 5)
	add_child(caption)

	finale_title.position = Vector2(130, 70)
	finale_title.size = Vector2(700, 58)
	finale_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(finale_title, 43, Color("#ffe978"), 8)
	add_child(finale_title)

	finale_body.position = Vector2(105, 392)
	finale_body.size = Vector2(750, 72)
	finale_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	finale_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	finale_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(finale_body, 16, Color.WHITE, 5)
	add_child(finale_body)

	hint.position = Vector2(150, 462)
	hint.size = Vector2(660, 26)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(hint, 14, Color("#ffd3df"), 4)
	add_child(hint)

	replay_button.text = "Carry the love into a new journey  ↻"
	replay_button.position = Vector2(310, 496)
	replay_button.size = Vector2(340, 38)
	replay_button.add_theme_font_size_override("font_size", 15)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#ef4b8f")
	style.border_color = Color(1, 1, 1, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	replay_button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = Color("#ff6da9")
	replay_button.add_theme_stylebox_override("hover", hover)
	replay_button.pressed.connect(func(): replay_requested.emit())
	add_child(replay_button)


func _style_label(label: Label, font_size: int, color: Color, outline: int) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", outline)
	label.add_theme_color_override("font_outline_color", Color(0.08, 0.035, 0.08, 0.72))


func _draw() -> void:
	# A warm sunset deepens toward the yard, echoing every chapter's palette.
	for band in range(24):
		var t := float(band) / 23.0
		var color := Color("#49264f").lerp(Color("#f39867"), t)
		draw_rect(Rect2(0, band * 15.0, 960, 16), color)
	draw_circle(Vector2(780, 122), 68, Color(1, 0.87, 0.5, 0.5))
	draw_rect(Rect2(0, 350, 960, 190), Color("#173f3c"))
	draw_rect(Rect2(0, 415, 960, 125), Color("#245145"))
	# The home and the two porch lights that never went dark.
	draw_rect(Rect2(52, 205, 236, 178), Color("#f3c6a8"))
	draw_colored_polygon(PackedVector2Array([Vector2(34, 215), Vector2(170, 128), Vector2(308, 215)]), Color("#8c4560"))
	draw_rect(Rect2(130, 276, 80, 107), Color("#593b4e"))
	for light_x in [102.0, 236.0]:
		var glow := 0.72 + sin(elapsed * 2.2 + light_x) * 0.08
		draw_circle(Vector2(light_x, 257), 28, Color(1, 0.78, 0.35, 0.14 * glow))
		draw_circle(Vector2(light_x, 257), 8, Color(1, 0.92, 0.57, glow))
	# A path home, flowers, fireflies, and slowly rising hearts.
	draw_colored_polygon(PackedVector2Array([Vector2(122, 540), Vector2(355, 350), Vector2(550, 350), Vector2(720, 540)]), Color("#c99b76"))
	for i in range(34):
		var x := fposmod(i * 113.0 + sin(elapsed * 0.45 + i) * 24.0, 960.0)
		var y := 330.0 + fposmod(i * 67.0 - elapsed * (9.0 + i % 3), 205.0)
		var pulse := 0.38 + 0.3 * (0.5 + 0.5 * sin(elapsed * 3.0 + i))
		draw_circle(Vector2(x, y), 2.0 + pulse, Color(1, 0.88, 0.38, pulse))
	for i in range(18):
		var blossom_x := fposmod(i * 149.0 + elapsed * (13.0 + i % 4), 1020.0) - 30.0
		var blossom_y := fposmod(i * 83.0 + elapsed * (18.0 + i % 3), 540.0)
		draw_circle(Vector2(blossom_x, blossom_y), 3.0, Color(1, 0.7, 0.78, 0.48))
	if completed:
		for i in range(7):
			var heart_x := 345.0 + i * 45.0 + sin(elapsed * 1.6 + i) * 12.0
			var heart_y := 350.0 - fposmod(elapsed * (18.0 + i) + i * 31.0, 165.0)
			draw_string(ThemeDB.fallback_font, Vector2(heart_x, heart_y), "♥", HORIZONTAL_ALIGNMENT_CENTER, 24, 24, Color(1, 0.45, 0.63, 0.55))
