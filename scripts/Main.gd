extends Node2D

enum Mode { TITLE, PROLOGUE, CHAPTER, PLAYING, PAUSED, MAP, LEVEL_END, FINALE }

const WORLD_NAMES := ["NEW YORK", "LOS ANGELES", "LOUISIANA", "ORLANDO"]
const WORLD_COLORS := [
	[Color("#79d7ee"), Color("#ffcf79"), Color("#ef4b8f"), Color("#5e7894"), Color("#7dbb60")],
	[Color("#7ae0ee"), Color("#f8a66f"), Color("#8c5ac8"), Color("#ba7555"), Color("#f3cb62")],
	[Color("#315a72"), Color("#8a5c84"), Color("#e5bd48"), Color("#475b50"), Color("#72a552")],
	[Color("#75d7e5"), Color("#ffd08c"), Color("#f38e37"), Color("#6f8a52"), Color("#68b965")],
]
const MOVING_LABELS := [
	["TAXI", "LEAF", "BRIDGE"],
	["BOARD", "TAKE!", "SURF"],
	["JAZZ", "LOG", "DECK"],
	["ORANGE", "SWAN", "LOVE"],
]

var mode := Mode.TITLE
var levels: Array = []
var story: Dictionary = {}
var current_level: Dictionary = {}
var level_index := 0
var prologue_index := 0
var player: JellyPlayer
var world_root: Node2D
var spawn_point := Vector2(70, 390)
var hearts := 3
var treats := 0
var squirrel_friends := 0
var level_width := 3300.0
var completing := false
var elapsed := 0.0
var particles: Array[Dictionary] = []
var bark_rings: Array[Dictionary] = []

var ui_layer := CanvasLayer.new()
var overlay := ColorRect.new()
var card := PanelContainer.new()
var card_box := VBoxContainer.new()
var art := TextureRect.new()
var kicker := Label.new()
var title := Label.new()
var body := Label.new()
var prompt := Label.new()
var primary_button := Button.new()
var secondary_button := Button.new()
var map_buttons := HBoxContainer.new()
var hud := Control.new()
var hearts_label := Label.new()
var location_label := Label.new()
var collect_label := Label.new()
var toast_label := Label.new()
var touch_controls := Control.new()
var toast_tween: Tween


func _ready() -> void:
	add_to_group("game")
	_configure_input()
	_load_content()
	_build_ui()
	show_title()
	if OS.get_cmdline_user_args().has("--smoke-level"):
		call_deferred("load_level", 0)
	queue_redraw()


func _process(delta: float) -> void:
	elapsed += delta
	_update_fx(delta)
	if mode == Mode.PLAYING and is_instance_valid(player):
		if player.global_position.y > 680.0:
			_damage_player(true)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if mode == Mode.PLAYING:
			pause_game()
		elif mode == Mode.PAUSED:
			resume_game()
		elif mode == Mode.MAP:
			_show_pause_card()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		if mode in [Mode.TITLE, Mode.PROLOGUE, Mode.CHAPTER, Mode.LEVEL_END, Mode.FINALE]:
			_primary_action()


func _load_content() -> void:
	var parsed_levels = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels.json"))
	var parsed_story = JSON.parse_string(FileAccess.get_file_as_string("res://data/story.json"))
	levels = parsed_levels if typeof(parsed_levels) == TYPE_ARRAY else []
	story = parsed_story if typeof(parsed_story) == TYPE_DICTIONARY else {}


func show_title() -> void:
	mode = Mode.TITLE
	get_tree().paused = false
	_clear_world()
	AudioDirector.stop_music(0.35)
	hud.hide()
	touch_controls.hide()
	overlay.show()
	art.show()
	art.texture = load("res://assets/jelly-icon.png")
	kicker.text = "A LITTLE DOG · A VERY BIG ADVENTURE"
	title.text = "JELLY'S\nJOURNEY HOME"
	body.text = "A story-rich platform adventure across America.\nFollow Jelly's super-powered nose, help animal friends, and find the two humans who never stopped searching for her."
	prompt.text = "Move: A/D or ←/→  ·  Jump: Space  ·  Run: Shift  ·  Bark: X  ·  Sniff: C"
	primary_button.text = "Start the adventure  →"
	secondary_button.text = "Continue from level %d" % (GameState.unlocked_level + 1)
	secondary_button.visible = GameState.unlocked_level > 0
	map_buttons.hide()
	_set_overlay_color(Color("#17213d"))


func _primary_action() -> void:
	match mode:
		Mode.TITLE:
			prologue_index = 0
			show_prologue_panel()
		Mode.PROLOGUE:
			prologue_index += 1
			var panels: Array = story.get("prologue", [])
			if prologue_index >= panels.size():
				show_chapter_intro(0)
			else:
				show_prologue_panel()
		Mode.CHAPTER:
			load_level(level_index)
		Mode.PAUSED:
			resume_game()
		Mode.LEVEL_END:
			_advance_after_level()
		Mode.FINALE:
			GameState.reset_journey()
			show_title()


func _secondary_action() -> void:
	match mode:
		Mode.TITLE:
			level_index = GameState.unlocked_level
			show_chapter_intro(level_index / 3)
		Mode.PAUSED:
			show_map()
		Mode.MAP:
			_show_pause_card()


func show_prologue_panel() -> void:
	mode = Mode.PROLOGUE
	var panels: Array = story.get("prologue", [])
	if panels.is_empty():
		show_chapter_intro(0)
		return
	var panel: Dictionary = panels[clampi(prologue_index, 0, panels.size() - 1)]
	overlay.show()
	hud.hide()
	touch_controls.hide()
	map_buttons.hide()
	art.show()
	art.texture = load("res://assets/family.jpeg") if prologue_index in [0, 1, panels.size() - 1] else load("res://assets/jelly-icon.png")
	kicker.text = str(panel.get("kicker", "BEFORE THE JOURNEY"))
	title.text = str(panel.get("title", "A windy morning"))
	body.text = str(panel.get("text", ""))
	prompt.text = "%d / %d" % [prologue_index + 1, panels.size()]
	primary_button.text = "Begin the journey  →" if prologue_index == panels.size() - 1 else "Continue  →"
	secondary_button.hide()
	_set_overlay_color(Color(panel.get("color", "#17213d")))


func show_chapter_intro(world_index: int) -> void:
	mode = Mode.CHAPTER
	var chapters: Array = story.get("chapters", [])
	var index := clampi(world_index, 0, 3)
	var chapter: Dictionary = chapters[index] if index < chapters.size() else {}
	overlay.show()
	hud.hide()
	touch_controls.hide()
	map_buttons.hide()
	art.show()
	art.texture = load("res://assets/jelly-icon.png")
	kicker.text = "CHAPTER %s · %s" % [_roman(index + 1), WORLD_NAMES[index]]
	title.text = str(chapter.get("title", WORLD_NAMES[index]))
	body.text = str(chapter.get("text", "Jelly follows the next familiar scent."))
	prompt.text = str(chapter.get("objective", "Follow the trail."))
	primary_button.text = "Let's go!  →"
	secondary_button.hide()
	_set_overlay_color(WORLD_COLORS[index][3].darkened(0.38))


func load_level(index: int) -> void:
	if levels.is_empty():
		show_toast("Level data could not be loaded.")
		return
	_clear_world()
	level_index = clampi(index, 0, levels.size() - 1)
	current_level = levels[level_index]
	level_width = float(current_level.get("width", 3300))
	hearts = 3
	treats = 0
	squirrel_friends = 1 if GameState.rescued_squirrels.has(str(current_level.get("id", ""))) else 0
	completing = false
	world_root = Node2D.new()
	world_root.name = "Level_%s" % current_level.get("id", level_index)
	add_child(world_root)
	player = JellyPlayer.new()
	world_root.add_child(player)
	player.global_position = Vector2(72, 385)
	player.spawn_point = player.global_position
	player.barked.connect(_on_player_barked)
	player.damaged.connect(func(): _damage_player(false))
	player.landed.connect(_on_player_landed)
	_build_level_geometry()
	_build_level_entities()
	var camera := Camera2D.new()
	camera.position = Vector2(135, -22)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.5
	camera.drag_horizontal_enabled = true
	camera.drag_left_margin = 0.16
	camera.drag_right_margin = 0.28
	camera.limit_left = 0
	camera.limit_right = int(level_width)
	camera.limit_top = 0
	camera.limit_bottom = 540
	player.add_child(camera)
	camera.make_current()
	mode = Mode.PLAYING
	get_tree().paused = false
	overlay.hide()
	hud.show()
	touch_controls.show()
	_update_hud()
	AudioDirector.play_level(str(current_level.get("id", "")))
	show_toast(str(current_level.get("tip", "Follow the trail.")))
	queue_redraw()


func _build_level_geometry() -> void:
	var world_index := int(current_level.get("world", 0))
	var colors := _platform_colors(world_index)
	for raw_rect in current_level.get("platforms", []):
		var platform := JellyPlatform.new()
		platform.configure(raw_rect, colors)
		world_root.add_child(platform)
	var moving_index := 0
	for raw_moving in current_level.get("moving", []):
		var moving := JellyPlatform.new()
		var rect := [raw_moving[0], raw_moving[1], raw_moving[2], raw_moving[3]]
		moving.configure(rect, [WORLD_COLORS[world_index][2], Color("#fff4c9"), Color.WHITE], MOVING_LABELS[world_index][level_index % 3])
		moving.configure_movement(str(raw_moving[4]), float(raw_moving[5]), float(raw_moving[6]) / 55.0, float(raw_moving[7]))
		world_root.add_child(moving)
		moving_index += 1


func _build_level_entities() -> void:
	for point in current_level.get("treats", []):
		var treat := JellyTreat.new()
		treat.position = Vector2(float(point[0]), float(point[1]))
		treat.collected.connect(_on_treat_collected)
		world_root.add_child(treat)
	var checkpoint_data: Array = current_level.get("checkpoint", [level_width * 0.5, "Halfway Home"])
	var checkpoint := JellyCheckpoint.new()
	checkpoint.position = Vector2(float(checkpoint_data[0]), _floor_y(float(checkpoint_data[0])) - 2.0)
	checkpoint.configure(str(checkpoint_data[1]), WORLD_COLORS[int(current_level.get("world", 0))][2])
	checkpoint.activated.connect(_on_checkpoint)
	world_root.add_child(checkpoint)
	for raw_enemy in current_level.get("enemies", []):
		var enemy := JellyEnemy.new()
		var x := float(raw_enemy[0])
		var kind := str(raw_enemy[2])
		var y := 190.0 if kind == "dive" else _floor_y(x) - 31.0
		enemy.configure(kind, int(current_level.get("world", 0)), Vector2(x, y), player)
		enemy.player_hit.connect(_on_enemy_hit)
		world_root.add_child(enemy)
	var paths: Array = current_level.get("squirrelPath", [])
	if not paths.is_empty():
		var squirrel := JellySquirrel.new()
		squirrel.configure(paths, player)
		squirrel.befriended.connect(_on_squirrel_befriended)
		world_root.add_child(squirrel)
	for raw_hazard in current_level.get("hazards", []):
		var hazard := JellyHazard.new()
		var width := float(raw_hazard[3])
		var height := float(raw_hazard[4]) if raw_hazard.size() >= 6 else 90.0
		var hazard_phase := float(raw_hazard[5]) if raw_hazard.size() >= 6 else float(raw_hazard[4])
		hazard.configure(str(raw_hazard[0]), Rect2(float(raw_hazard[1]), float(raw_hazard[2]), width, height), hazard_phase)
		world_root.add_child(hazard)
	var goal_data: Array = current_level.get("goal", [level_width - 160, 340])
	var goal := JellyGoal.new()
	goal.position = Vector2(float(goal_data[0]) + 46.0, float(goal_data[1]) + 54.0)
	goal.configure(level_index == levels.size() - 1, WORLD_COLORS[int(current_level.get("world", 0))][2])
	goal.reached.connect(_on_goal_reached)
	world_root.add_child(goal)


func _on_player_barked(origin: Vector2, direction: float) -> void:
	bark_rings.append({"position": origin, "radius": 8.0, "life": 0.55, "direction": direction})
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.global_position.distance_to(origin) < 190.0:
			enemy.stun(1.7)
	for squirrel in get_tree().get_nodes_in_group("squirrels"):
		if is_instance_valid(squirrel):
			squirrel.react_to_bark(origin)
	_burst(origin, WORLD_COLORS[int(current_level.get("world", 0))][2], 12)


func _on_player_landed(hard: bool) -> void:
	_burst(player.global_position + Vector2(0, 26), Color(1, 1, 1, 0.72), 12 if hard else 6, 95.0)


func _on_enemy_hit(source_x: float) -> void:
	if is_instance_valid(player):
		player.take_damage(source_x)


func _damage_player(fell: bool) -> void:
	hearts -= 1
	_update_hud()
	_burst(player.global_position, Color("#ff789f"), 18, 230.0)
	if hearts <= 0:
		player.control_enabled = false
		show_toast("Jelly catches her breath — you can do it!")
		await get_tree().create_timer(0.85).timeout
		load_level(level_index)
	else:
		player.respawn(spawn_point)
		show_toast("A friendly breeze carried Jelly to the checkpoint!" if fell else "One courage heart used. Keep going!")


func _on_treat_collected() -> void:
	treats += 1
	GameState.add_treat()
	_update_hud()
	if treats == 5:
		show_toast("All five treats! Jelly's nose is unstoppable.")


func _on_squirrel_befriended() -> void:
	if squirrel_friends > 0:
		return
	squirrel_friends = 1
	GameState.befriend_squirrel(str(current_level.get("id", "unknown")))
	_update_hud()
	_burst(player.global_position, Color("#ffd84d"), 28, 275.0)
	show_toast("Best chase ever — a golden acorn and a new friend!")


func _on_checkpoint(location: Vector2, checkpoint_title: String) -> void:
	spawn_point = location
	player.spawn_point = location
	_burst(location, Color("#ffe66b"), 25, 230.0)
	show_toast("Checkpoint: %s" % checkpoint_title)


func _on_goal_reached() -> void:
	if completing:
		return
	completing = true
	player.celebrate()
	AudioDirector.play_sfx("win", 1.0, -1.0)
	_burst(player.global_position, Color("#ffe36a"), 40, 330.0)
	await get_tree().create_timer(0.8).timeout
	if level_index >= levels.size() - 1:
		show_finale()
	else:
		show_level_end()


func show_level_end() -> void:
	mode = Mode.LEVEL_END
	get_tree().paused = true
	hud.hide()
	touch_controls.hide()
	overlay.show()
	map_buttons.hide()
	art.show()
	art.texture = load("res://assets/jelly-icon.png")
	var endings: Dictionary = story.get("level_endings", {})
	var ending: Dictionary = endings.get(str(current_level.get("id", "")), {})
	kicker.text = str(ending.get("kicker", "A NEW CLUE"))
	title.text = str(ending.get("title", "The trail continues"))
	body.text = str(ending.get("text", "Jelly's family scent is stronger. She keeps going."))
	prompt.text = "Treats %d/5  ·  Squirrel friend %s" % [treats, "found" if squirrel_friends else "still hiding"]
	primary_button.text = "Next level  →"
	secondary_button.hide()
	_set_overlay_color(WORLD_COLORS[int(current_level.get("world", 0))][3].darkened(0.32))
	GameState.complete_level(level_index)


func _advance_after_level() -> void:
	get_tree().paused = false
	var next := level_index + 1
	if next >= levels.size():
		show_finale()
		return
	level_index = next
	if next % 3 == 0:
		show_chapter_intro(next / 3)
	else:
		load_level(next)


func show_finale() -> void:
	mode = Mode.FINALE
	get_tree().paused = true
	AudioDirector.stop_music(0.7)
	AudioDirector.play_sfx("win", 0.92, 0.0)
	hud.hide()
	touch_controls.hide()
	overlay.show()
	map_buttons.hide()
	art.show()
	art.texture = load("res://assets/family.jpeg")
	kicker.text = "SHE FOLLOWED LOVE ALL THE WAY HOME"
	title.text = "Jelly found her family!"
	body.text = str(story.get("epilogue", "Every friend, every clue, and every brave little step led Jelly back to the two people who never stopped looking for her."))
	prompt.text = "The journey ends at home — but the squirrel chases never do."
	primary_button.text = "Play again  ↻"
	secondary_button.hide()
	_set_overlay_color(Color("#54234d"))


func pause_game() -> void:
	if mode != Mode.PLAYING:
		return
	mode = Mode.PAUSED
	get_tree().paused = true
	_show_pause_card()


func _show_pause_card() -> void:
	mode = Mode.PAUSED
	overlay.show()
	map_buttons.hide()
	art.hide()
	kicker.text = "PAWS FOR A MOMENT"
	title.text = "Game paused"
	body.text = "Jelly will wait right here."
	prompt.text = "Esc also resumes the journey."
	primary_button.text = "Keep going"
	secondary_button.text = "Journey map"
	secondary_button.show()
	_set_overlay_color(Color(0.05, 0.08, 0.16, 0.92))


func resume_game() -> void:
	mode = Mode.PLAYING
	get_tree().paused = false
	overlay.hide()
	hud.show()
	touch_controls.show()


func show_map() -> void:
	mode = Mode.MAP
	kicker.text = "JELLY'S COAST-TO-COAST TRAIL"
	title.text = "Choose a chapter"
	body.text = "Return to any chapter Jelly has reached."
	prompt.text = "NY  →  LA  →  LOUISIANA  →  FL"
	primary_button.hide()
	secondary_button.text = "Back"
	secondary_button.show()
	map_buttons.show()
	for child in map_buttons.get_children():
		child.queue_free()
	for i in range(4):
		var button := Button.new()
		button.text = "%s\n%s" % [WORLD_NAMES[i], "OPEN" if GameState.unlocked_level >= i * 3 else "LOCKED"]
		button.disabled = GameState.unlocked_level < i * 3
		button.custom_minimum_size = Vector2(130, 72)
		button.pressed.connect(func(index := i): _select_chapter(index))
		map_buttons.add_child(button)
	_set_overlay_color(Color("#173157"))


func _select_chapter(index: int) -> void:
	get_tree().paused = false
	level_index = index * 3
	show_chapter_intro(index)


func spawn_music_wave(origin: Vector2, direction: float) -> void:
	if mode != Mode.PLAYING:
		return
	var wave := JellyMusicWave.new()
	wave.position = origin + Vector2(direction * 32.0, -8.0)
	wave.direction = direction
	world_root.add_child(wave)


func show_toast(message: String) -> void:
	toast_label.text = message
	toast_label.modulate.a = 0.0
	toast_label.show()
	if toast_tween and toast_tween.is_valid():
		toast_tween.kill()
	toast_tween = create_tween()
	toast_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	toast_tween.tween_property(toast_label, "modulate:a", 1.0, 0.18)
	toast_tween.tween_interval(2.3)
	toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.32)


func _update_hud() -> void:
	hearts_label.text = "♥".repeat(hearts) + "♡".repeat(3 - hearts)
	location_label.text = "%s\n%d · %s" % [WORLD_NAMES[int(current_level.get("world", 0))], level_index % 3 + 1, current_level.get("name", "Trail")]
	collect_label.text = "🐿 %d/1    ● %d/5" % [squirrel_friends, treats]


func _floor_y(x: float) -> float:
	var best := 468.0
	var found := false
	for raw_rect in current_level.get("platforms", []):
		var left := float(raw_rect[0])
		var right := left + float(raw_rect[2])
		if x >= left and x <= right:
			var y := float(raw_rect[1])
			if not found or y < best:
				best = y
				found = true
	return best


func _platform_colors(world_index: int) -> Array[Color]:
	var palette: Array = WORLD_COLORS[world_index]
	return [palette[4], palette[3], palette[2]]


func _clear_world() -> void:
	if is_instance_valid(world_root):
		world_root.queue_free()
	world_root = null
	current_level = {}


func _update_fx(delta: float) -> void:
	for particle in particles:
		particle.position += particle.velocity * delta
		particle.velocity.y += 260.0 * delta
		particle.life -= delta
	particles = particles.filter(func(item): return item.life > 0.0)
	for ring in bark_rings:
		ring.radius += 330.0 * delta
		ring.life -= delta
	bark_rings = bark_rings.filter(func(item): return item.life > 0.0)


func _burst(at: Vector2, color: Color, amount: int, spread := 180.0) -> void:
	for i in range(amount):
		particles.append({
			"position": at,
			"velocity": Vector2(randf_range(-spread, spread), randf_range(-spread, -35.0)),
			"life": randf_range(0.35, 0.8),
			"color": color,
			"size": randf_range(2.0, 5.0),
		})


func _draw() -> void:
	var world_index := int(current_level.get("world", 0)) if not current_level.is_empty() else 0
	var width := level_width if not current_level.is_empty() else 1300.0
	_draw_sky(world_index, width)
	if not current_level.is_empty():
		_draw_landmarks(world_index, width, str(current_level.get("scene", "")))
		_draw_atmosphere(str(current_level.get("weather", "")), width)
		_draw_props(current_level.get("props", []))
		_draw_secrets(current_level.get("secrets", []), WORLD_COLORS[world_index][2])
	for ring in bark_rings:
		var alpha := clampf(ring.life * 1.8, 0.0, 1.0)
		draw_arc(ring.position, ring.radius, 0, TAU, 42, Color(1.0, 0.28, 0.57, alpha), 7.0)
		draw_string(ThemeDB.fallback_font, ring.position + Vector2(ring.direction * ring.radius, 0), "♥", HORIZONTAL_ALIGNMENT_CENTER, 20, 22, Color(1.0, 0.3, 0.6, alpha))
	for particle in particles:
		var color: Color = particle.color
		color.a *= clampf(particle.life * 2.0, 0.0, 1.0)
		draw_circle(particle.position, particle.size, color)


func _draw_sky(world_index: int, width: float) -> void:
	var palette: Array = WORLD_COLORS[world_index]
	draw_rect(Rect2(-200, -200, width + 500, 760), palette[0])
	draw_rect(Rect2(-200, 180, width + 500, 380), palette[1].darkened(0.12))
	draw_circle(Vector2(790 if world_index < 2 else 150, 92), 52, Color(1, 0.94, 0.62, 0.62))
	for i in range(int(width / 245.0) + 3):
		var x := i * 245.0 - 100.0
		var y := 66.0 + (i % 4) * 31.0
		var cloud := Color(1, 1, 1, 0.72)
		draw_circle(Vector2(x, y), 21, cloud)
		draw_circle(Vector2(x + 27, y - 9), 30, cloud)
		draw_circle(Vector2(x + 58, y), 20, cloud)


func _draw_landmarks(world_index: int, width: float, scene: String) -> void:
	match world_index:
		0:
			for i in range(int(width / 112.0) + 2):
				var x := i * 112.0
				var height := 105.0 + (i % 6) * 27.0
				draw_rect(Rect2(x, 310 - height, 82, height + 125), Color("#3e6a83"))
				for wx in range(3):
					for wy in range(4):
						draw_rect(Rect2(x + 12 + wx * 23, 325 - height + wy * 25, 8, 11), Color(1, 0.88, 0.47, 0.82))
			if scene == "centralpark":
				for i in range(int(width / 150.0) + 1): _draw_tree(Vector2(i * 150.0, 355), 46 + i % 4 * 7, false)
			if scene == "brooklyn":
				for base in range(480, int(width), 1500):
					draw_line(Vector2(base - 420, 410), Vector2(base, 150), Color("#d7b98b"), 10)
					draw_line(Vector2(base, 150), Vector2(base + 420, 410), Color("#d7b98b"), 10)
		1:
			draw_rect(Rect2(0, 380, width, 160), Color("#4fc1d8"))
			draw_rect(Rect2(0, 425, width, 115), Color("#f4da91"))
			for i in range(int(width / 225.0) + 2):
				var x := i * 225.0 + 55
				draw_rect(Rect2(x - 6, 245, 12, 150), Color("#6b7650"))
				for angle in range(0, 360, 45):
					var radians := deg_to_rad(angle)
					draw_line(Vector2(x, 245), Vector2(x + cos(radians) * 58, 235 + sin(radians) * 30), Color("#4c9e6f"), 13)
			if scene == "pier":
				draw_arc(Vector2(900, 320), 105, 0, TAU, 48, Color("#714f5b"), 8)
				for angle in range(0, 360, 45):
					var end := Vector2(900, 320) + Vector2.from_angle(deg_to_rad(angle)) * 105
					draw_line(Vector2(900, 320), end, Color("#714f5b"), 4)
		2:
			draw_rect(Rect2(0, 390, width, 150), Color("#294f5b"))
			for i in range(int(width / 165.0) + 2):
				var x := i * 165.0
				draw_rect(Rect2(x - 8, 220, 16, 195), Color("#483e35"))
				draw_circle(Vector2(x, 215), 70, Color("#315c42"))
				for moss in range(5):
					draw_line(Vector2(x - 48 + moss * 21, 220), Vector2(x - 52 + moss * 21, 300), Color("#6e8d64"), 3)
			if scene == "frenchquarter":
				for i in range(int(width / 275.0) + 1):
					draw_rect(Rect2(i * 275, 210, 220, 170), Color("#665276"))
					draw_rect(Rect2(i * 275 + 18, 255, 184, 45), Color(0.9, 0.78, 0.66, 0.35), false, 5)
		3:
			for i in range(int(width / 165.0) + 2): _draw_tree(Vector2(i * 165.0, 370), 44 + i % 4 * 7, true)
			if scene == "eola":
				draw_rect(Rect2(0, 390, width, 150), Color("#6fcbe2"))
				for i in range(int(width / 460.0) + 1):
					draw_arc(Vector2(i * 460 + 230, 395), 54, PI, TAU, 25, Color("#dffaff"), 6)
			if scene == "home":
				for i in range(int(width / 305.0) + 1):
					var x := i * 305.0
					draw_rect(Rect2(x, 300, 230, 110), Color("#f7d3b0"))
					draw_colored_polygon(PackedVector2Array([Vector2(x - 12, 300), Vector2(x + 115, 225), Vector2(x + 242, 300)]), Color("#ef7774") if i % 2 else Color("#76a5cf"))


func _draw_atmosphere(weather: String, width: float) -> void:
	if weather in ["city-breeze", "river-gusts"]:
		for i in range(42):
			var x := fposmod(i * 173.0 + elapsed * 58.0, width + 160.0) - 80.0
			var y := 95.0 + fposmod(i * 67.0, 310.0)
			draw_line(Vector2(x, y), Vector2(x + 19, y + 3), Color(1, 1, 1, 0.34), 2)
	elif weather == "warm-rain":
		for i in range(54):
			var x := fposmod(i * 151.0 - elapsed * 88.0, width + 120.0) - 60.0
			var y := fposmod(i * 73.0 + elapsed * 164.0, 480.0)
			draw_line(Vector2(x, y), Vector2(x - 8, y + 22), Color(0.78, 0.95, 1, 0.48), 2)
	elif weather in ["leaf-fall", "blossom-drift", "celebration"]:
		for i in range(36):
			var x := fposmod(i * 211.0 + elapsed * (28.0 + i % 5 * 4.0), width + 100.0) - 50.0
			var y := fposmod(i * 97.0 + elapsed * (42.0 + i % 3 * 8.0), 470.0)
			var color := Color("#ffb9cc") if weather == "blossom-drift" else Color("#ffd85b") if weather == "celebration" else Color("#e28f45")
			draw_set_transform(Vector2(x, y), elapsed + i, Vector2.ONE)
			draw_colored_polygon(PackedVector2Array([Vector2(-5, 0), Vector2(0, -3), Vector2(5, 0), Vector2(0, 3)]), Color(color, 0.7))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	elif weather in ["fireflies", "river-lights", "studio-glitter", "ocean-sparkle", "sunset-sparkle"]:
		for i in range(48):
			var x := fposmod(i * 137.0, width)
			var y := 90.0 + fposmod(i * 83.0, 330.0)
			var glow := 0.22 + 0.55 * (0.5 + 0.5 * sin(elapsed * 3.2 + i))
			var color := Color("#ffe469") if weather in ["fireflies", "river-lights"] else Color("#fff4bc")
			draw_circle(Vector2(x, y), 2.0 + glow * 2.0, Color(color, glow))
	elif weather == "music-notes":
		for i in range(24):
			var x := fposmod(i * 249.0 + elapsed * 24.0, width)
			var y := 120.0 + fposmod(i * 91.0 - elapsed * 19.0, 290.0)
			draw_string(ThemeDB.fallback_font, Vector2(x, y), "♪" if i % 2 else "♫", HORIZONTAL_ALIGNMENT_CENTER, 18, 18, Color(1, 0.88, 0.33, 0.48))


func _draw_tree(at: Vector2, radius: float, oranges: bool) -> void:
	draw_rect(Rect2(at.x - 8, at.y, 16, 540 - at.y), Color("#6c5540"))
	draw_circle(at, radius, Color("#397b59"))
	if oranges:
		for i in range(6):
			var p := at + Vector2.from_angle(i * TAU / 6.0) * radius * Vector2(0.64, 0.48)
			draw_circle(p, 6, Color("#f39b34"))


func _draw_props(props: Array) -> void:
	for raw_prop in props:
		var kind := str(raw_prop[0])
		var at := Vector2(float(raw_prop[1]), float(raw_prop[2]))
		var scale_value := float(raw_prop[3]) if raw_prop.size() > 3 else 1.0
		draw_set_transform(at, 0, Vector2.ONE * scale_value)
		if "lamp" in kind:
			draw_line(Vector2.ZERO, Vector2(0, -78), Color("#30485b"), 7)
			draw_circle(Vector2(0, -84), 13, Color("#fff0a4"))
		elif kind in ["hydrant", "mailbox"]:
			draw_rect(Rect2(-15, -38, 30, 38), Color("#e94e55") if kind == "hydrant" else Color("#5c8fc3"))
		elif kind in ["bench", "picnic", "director-chair"]:
			draw_rect(Rect2(-38, -29, 76, 11), Color("#85563f"))
			draw_rect(Rect2(-34, -47, 68, 10), Color("#85563f"))
		elif kind in ["orange-crate", "snack-cart", "bead-stand", "surf-rack"]:
			draw_rect(Rect2(-37, -42, 74, 42), Color("#bb7441"))
			for i in range(4): draw_circle(Vector2(-24 + i * 16, -24 - i % 2 * 7), 7, Color("#f39a2d"))
		else:
			draw_rect(Rect2(-47, -102, 94, 40), Color("#fff4c9"))
			draw_line(Vector2(0, -62), Vector2.ZERO, Color("#6a4938"), 7)
			draw_string(ThemeDB.fallback_font, Vector2(-40, -78), kind.replace("-", " ").to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 80, 9, Color("#173157"))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _draw_secrets(secrets: Array, accent: Color) -> void:
	for secret in secrets:
		var at := Vector2(float(secret[0]), float(secret[1]))
		draw_arc(at, 34 + sin(elapsed * 2.0) * 4, 0, TAU, 28, Color(accent, 0.45), 3)
		for i in range(5):
			var p := at + Vector2.from_angle(elapsed + i * TAU / 5.0) * 44
			draw_circle(p, 3, Color("#fff2a6"))


func _build_ui() -> void:
	ui_layer.layer = 20
	add_child(ui_layer)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_layer.add_child(overlay)
	card.custom_minimum_size = Vector2(760, 445)
	card.position = Vector2(100, 48)
	card.size = Vector2(760, 445)
	card.process_mode = Node.PROCESS_MODE_ALWAYS
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.04, 0.07, 0.13, 0.82)
	card_style.border_color = Color(1, 1, 1, 0.17)
	card_style.border_width_left = 2
	card_style.border_width_top = 2
	card_style.border_width_right = 2
	card_style.border_width_bottom = 2
	card_style.corner_radius_top_left = 24
	card_style.corner_radius_top_right = 24
	card_style.corner_radius_bottom_left = 24
	card_style.corner_radius_bottom_right = 24
	card_style.content_margin_left = 34
	card_style.content_margin_right = 34
	card_style.content_margin_top = 26
	card_style.content_margin_bottom = 24
	card.add_theme_stylebox_override("panel", card_style)
	overlay.add_child(card)
	card.add_child(card_box)
	card_box.add_theme_constant_override("separation", 10)
	art.custom_minimum_size = Vector2(150, 128)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card_box.add_child(art)
	_style_label(kicker, 14, Color("#ffd765"), true)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_box.add_child(kicker)
	_style_label(title, 42, Color.WHITE, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_box.add_child(title)
	_style_label(body, 18, Color("#edf4ff"), false)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.y = 62
	card_box.add_child(body)
	_style_label(prompt, 13, Color("#c7d5ef"), false)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_box.add_child(prompt)
	map_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	map_buttons.add_theme_constant_override("separation", 10)
	card_box.add_child(map_buttons)
	_style_button(primary_button, true)
	primary_button.pressed.connect(_primary_action)
	card_box.add_child(primary_button)
	_style_button(secondary_button, false)
	secondary_button.pressed.connect(_secondary_action)
	card_box.add_child(secondary_button)
	_build_hud()
	_build_touch_controls()


func _build_hud() -> void:
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(hud)
	var top := ColorRect.new()
	top.color = Color(0.04, 0.07, 0.13, 0.78)
	top.position = Vector2(15, 14)
	top.size = Vector2(930, 58)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(top)
	hearts_label.position = Vector2(34, 26)
	_style_label(hearts_label, 25, Color("#ff639c"), true)
	hud.add_child(hearts_label)
	location_label.position = Vector2(300, 20)
	location_label.size = Vector2(360, 50)
	location_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(location_label, 15, Color.WHITE, true)
	hud.add_child(location_label)
	collect_label.position = Vector2(740, 27)
	collect_label.size = Vector2(180, 30)
	collect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_style_label(collect_label, 17, Color("#ffe36a"), true)
	hud.add_child(collect_label)
	toast_label.position = Vector2(225, 450)
	toast_label.size = Vector2(510, 46)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_label.add_theme_color_override("font_color", Color.WHITE)
	toast_label.add_theme_font_size_override("font_size", 16)
	var toast_style := StyleBoxFlat.new()
	toast_style.bg_color = Color(0.04, 0.07, 0.13, 0.88)
	toast_style.corner_radius_top_left = 18
	toast_style.corner_radius_top_right = 18
	toast_style.corner_radius_bottom_left = 18
	toast_style.corner_radius_bottom_right = 18
	toast_label.add_theme_stylebox_override("normal", toast_style)
	toast_label.process_mode = Node.PROCESS_MODE_ALWAYS
	hud.add_child(toast_label)
	hud.hide()


func _build_touch_controls() -> void:
	touch_controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	touch_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(touch_controls)
	var controls := [
		["◀", "move_left", Vector2(28, 452), Vector2(70, 62)],
		["▶", "move_right", Vector2(106, 452), Vector2(70, 62)],
		["WOOF", "bark", Vector2(778, 462), Vector2(72, 50)],
		["JUMP", "jump", Vector2(858, 442), Vector2(78, 72)],
	]
	for item in controls:
		var button := Button.new()
		button.text = item[0]
		button.position = item[2]
		button.size = item[3]
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.modulate.a = 0.72
		button.button_down.connect(func(action := str(item[1])): Input.action_press(action))
		button.button_up.connect(func(action := str(item[1])): Input.action_release(action))
		touch_controls.add_child(button)
	touch_controls.hide()


func _style_label(label: Label, size: int, color: Color, bold: bool) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_constant_override("outline_size", 4)
		label.add_theme_color_override("font_outline_color", Color(0.03, 0.05, 0.1, 0.58))


func _style_button(button: Button, primary: bool) -> void:
	button.custom_minimum_size = Vector2(0, 46)
	button.add_theme_font_size_override("font_size", 17)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#ef4b8f") if primary else Color(1, 1, 1, 0.12)
	normal.corner_radius_top_left = 15
	normal.corner_radius_top_right = 15
	normal.corner_radius_bottom_left = 15
	normal.corner_radius_bottom_right = 15
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(1, 1, 1, 0.24)
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = normal.bg_color.lightened(0.12)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", normal)


func _set_overlay_color(color: Color) -> void:
	overlay.color = color
	primary_button.show()


func _configure_input() -> void:
	_register_key_action("move_left", [KEY_A, KEY_LEFT])
	_register_key_action("move_right", [KEY_D, KEY_RIGHT])
	_register_key_action("jump", [KEY_SPACE, KEY_W, KEY_UP])
	_register_key_action("bark", [KEY_X])
	_register_key_action("sniff", [KEY_C])
	_register_key_action("sprint", [KEY_SHIFT])
	_register_key_action("pause", [KEY_ESCAPE, KEY_P])


func _register_key_action(action: StringName, keycodes: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for keycode in keycodes:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)


func _roman(value: int) -> String:
	return ["I", "II", "III", "IV"][clampi(value - 1, 0, 3)]
