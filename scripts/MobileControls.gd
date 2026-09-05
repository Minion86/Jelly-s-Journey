class_name JellyMobileControls
extends Control

const BUTTONS := [
	["◀", "move_left", Vector2(76, 466), 46.0, Color("#234d78")],
	["▶", "move_right", Vector2(178, 466), 46.0, Color("#234d78")],
	["WOOF", "bark", Vector2(782, 468), 40.0, Color("#7b3d75")],
	["JUMP", "jump", Vector2(893, 448), 55.0, Color("#d64b83")],
	["Ⅱ", "pause", Vector2(913, 102), 28.0, Color("#23324d")],
]
var buttons: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	for spec in BUTTONS: _add_touch_button(str(spec[0]), StringName(spec[1]), spec[2], float(spec[3]), spec[4])
	_layout_buttons()


func _process(_delta: float) -> void:
	_layout_buttons()


func release_all() -> void:
	for action in ["move_left", "move_right", "jump", "bark", "sprint", "pause"]: Input.action_release(action)


func _add_touch_button(text: String, action: StringName, at: Vector2, radius: float, color: Color) -> void:
	var button := TouchScreenButton.new()
	button.position = at
	button.action = action
	button.passby_press = true
	button.shape_centered = true
	var shape := CircleShape2D.new()
	shape.radius = radius
	button.shape = shape
	var disc := Polygon2D.new()
	var points := PackedVector2Array()
	for i in range(32): points.append(Vector2.from_angle(i * TAU / 32.0) * radius)
	disc.polygon = points
	disc.color = Color(color, 0.72)
	button.add_child(disc)
	var ring := Line2D.new()
	ring.width = 3.0
	ring.default_color = Color(1, 1, 1, 0.38)
	for i in range(33): ring.add_point(Vector2.from_angle(i * TAU / 32.0) * (radius - 3.0))
	button.add_child(ring)
	var label := Label.new()
	label.text = text
	label.position = Vector2(-radius, -16)
	label.size = Vector2(radius * 2.0, 32)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14 if text.length() > 1 else 25)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color(0.04, 0.06, 0.12, 0.78))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(label)
	button.pressed.connect(func(): disc.color = Color(color.lightened(0.18), 0.92))
	button.released.connect(func(): disc.color = Color(color, 0.72))
	add_child(button)
	buttons[str(action)] = button


func _layout_buttons() -> void:
	var viewport_size := get_viewport_rect().size
	if buttons.is_empty(): return
	buttons.move_left.position = Vector2(76, viewport_size.y - 74)
	buttons.move_right.position = Vector2(178, viewport_size.y - 74)
	buttons.bark.position = Vector2(viewport_size.x - 178, viewport_size.y - 72)
	buttons.jump.position = Vector2(viewport_size.x - 67, viewport_size.y - 92)
	buttons.pause.position = Vector2(viewport_size.x - 47, 102)
