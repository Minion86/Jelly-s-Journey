class_name JellyIntroSequence
extends Control

signal finished

const CAPTIONS := [
	"That morning, Central Park felt like the whole world—because they were together.",
	"Then a playful squirrel stole the loose blue ribbon from Jelly's little travel pouch.",
	"Jelly chased it for only one heartbeat.",
	"A parade turned the path into a river of umbrellas, music, and wind.",
	"They heard one tiny bark. Jelly heard both voices. But the moving city stood between them.",
	"When the park finally grew quiet, Jelly was alone… and the ribbon still smelled like home.",
]
const FRAME_HOLDS := [1.65, 1.45, 1.45, 1.75, 2.1]
const FRAME_SCALE := Vector2(1.875, 1.055)

var elapsed := 0.0
var sequence_generation := 0
var completed := false
var active_sprite: Sprite2D
var standby_sprite: Sprite2D
var active_tween: Tween
var caption := Label.new()
var kicker := Label.new()
var continue_button := Button.new()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_sprites()
	_build_copy()
	queue_redraw()


func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()


func play() -> void:
	sequence_generation += 1
	var generation := sequence_generation
	completed = false
	active_sprite.frame = 0
	active_sprite.modulate.a = 0.0
	active_sprite.position = Vector2(480, 270)
	active_sprite.scale = FRAME_SCALE * 1.03
	standby_sprite.modulate.a = 0.0
	kicker.text = "CENTRAL PARK · THE MORNING EVERYTHING CHANGED"
	kicker.modulate.a = 0.0
	caption.text = CAPTIONS[0]
	caption.modulate.a = 0.0
	continue_button.hide()
	var opening := create_tween().set_parallel(true)
	opening.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	opening.tween_property(active_sprite, "modulate:a", 1.0, 1.0)
	opening.tween_property(active_sprite, "scale", FRAME_SCALE, 3.2)
	opening.tween_property(kicker, "modulate:a", 1.0, 0.7).set_delay(0.2)
	opening.tween_property(caption, "modulate:a", 1.0, 0.8).set_delay(0.45)
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
	await get_tree().create_timer(1.35).timeout
	if generation == sequence_generation:
		_finish_sequence()


func advance() -> void:
	if completed:
		finished.emit()
		return
	sequence_generation += 1
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	active_sprite.frame = 5
	active_sprite.position = Vector2(480, 270)
	active_sprite.scale = FRAME_SCALE
	active_sprite.modulate.a = 1.0
	standby_sprite.modulate.a = 0.0
	caption.text = CAPTIONS[5]
	caption.modulate.a = 1.0
	_finish_sequence()


func _transition_to(frame_index: int) -> void:
	standby_sprite.frame = frame_index
	standby_sprite.position = Vector2(480 + (-10.0 if frame_index % 2 else 10.0), 270)
	standby_sprite.scale = FRAME_SCALE * 1.035
	standby_sprite.modulate = Color(1, 1, 1, 0)
	caption.modulate.a = 0.0
	caption.text = CAPTIONS[frame_index]
	if frame_index == 2:
		AudioDirector.play_sfx("whoosh", 1.08, -4.0)
	if frame_index == 4:
		AudioDirector.play_sfx("bark", 0.92, -2.0)
	active_tween = create_tween().set_parallel(true)
	active_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	active_tween.tween_property(active_sprite, "modulate:a", 0.0, 0.68)
	active_tween.tween_property(active_sprite, "position:x", active_sprite.position.x + (18.0 if frame_index % 2 else -18.0), 0.68)
	active_tween.tween_property(standby_sprite, "modulate:a", 1.0, 0.68)
	active_tween.tween_property(standby_sprite, "scale", FRAME_SCALE, 2.6)
	active_tween.tween_property(standby_sprite, "position:x", 480.0, 2.6)
	active_tween.tween_property(caption, "modulate:a", 1.0, 0.52).set_delay(0.25)
	await active_tween.finished
	var old := active_sprite
	active_sprite = standby_sprite
	standby_sprite = old
	standby_sprite.modulate.a = 0.0


func _finish_sequence() -> void:
	completed = true
	kicker.text = "JELLY'S PROMISE"
	continue_button.show()
	continue_button.modulate.a = 0.0
	var reveal := create_tween().set_parallel(true)
	reveal.tween_property(continue_button, "modulate:a", 1.0, 0.65)
	reveal.tween_property(kicker, "modulate:a", 1.0, 0.45)


func _build_sprites() -> void:
	var sheet: Texture2D = load("res://assets/cinematics/central-park-intro-v1.webp")
	active_sprite = Sprite2D.new()
	standby_sprite = Sprite2D.new()
	for sprite in [active_sprite, standby_sprite]:
		sprite.texture = sheet
		sprite.hframes = 3
		sprite.vframes = 2
		sprite.position = Vector2(480, 270)
		sprite.scale = FRAME_SCALE
		sprite.centered = true
		add_child(sprite)
	standby_sprite.modulate.a = 0.0


func _build_copy() -> void:
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.03, 0.025, 0.08, 0.10)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	kicker.position = Vector2(115, 25)
	kicker.size = Vector2(730, 34)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(kicker, 15, Color("#ffe183"), 6)
	add_child(kicker)
	caption.position = Vector2(85, 432)
	caption.size = Vector2(790, 67)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(caption, 20, Color.WHITE, 7)
	add_child(caption)
	continue_button.text = "Follow the scent home  →"
	continue_button.position = Vector2(340, 497)
	continue_button.size = Vector2(280, 36)
	continue_button.add_theme_font_size_override("font_size", 15)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#ef4b8f")
	style.border_color = Color(1, 1, 1, 0.55)
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	continue_button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = Color("#ff70ad")
	continue_button.add_theme_stylebox_override("hover", hover)
	continue_button.pressed.connect(func(): finished.emit())
	add_child(continue_button)


func _style_label(label: Label, font_size: int, color: Color, outline: int) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", outline)
	label.add_theme_color_override("font_outline_color", Color(0.04, 0.02, 0.06, 0.88))


func _draw() -> void:
	# Wind, leaves, ribbon sparks, and crowd streaks keep the painted panels alive.
	for i in range(46):
		var x := fposmod(i * 137.0 + elapsed * (38.0 + i % 5 * 7.0), 1040.0) - 40.0
		var y := 70.0 + fposmod(i * 79.0 + elapsed * (24.0 + i % 4 * 5.0), 370.0)
		var leaf_color := Color("#f4a144") if i % 3 else Color("#df5e58")
		draw_set_transform(Vector2(x, y), elapsed * (1.2 + i % 3 * 0.3), Vector2.ONE)
		draw_colored_polygon(PackedVector2Array([Vector2(-5, 0), Vector2(0, -3), Vector2(6, 0), Vector2(0, 3)]), Color(leaf_color, 0.56))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	for i in range(10):
		var ribbon_x := fposmod(elapsed * 92.0 + i * 103.0, 1080.0) - 60.0
		var ribbon_y := 300.0 + sin(elapsed * 2.3 + i) * 24.0
		draw_line(Vector2(ribbon_x, ribbon_y), Vector2(ribbon_x + 22, ribbon_y - 7), Color(0.28, 0.7, 1.0, 0.32), 3.0)
