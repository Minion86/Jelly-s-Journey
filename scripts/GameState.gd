extends Node

const SAVE_PATH := "user://jelly_journey_v4.save"

var unlocked_level := 0
var total_treats := 0
var rescued_squirrels: Dictionary = {}
var muted := false


func _ready() -> void:
	load_progress()


func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	unlocked_level = clampi(int(parsed.get("unlocked_level", 0)), 0, 11)
	total_treats = maxi(0, int(parsed.get("total_treats", 0)))
	rescued_squirrels = parsed.get("rescued_squirrels", {})
	muted = bool(parsed.get("muted", false))


func save_progress() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"unlocked_level": unlocked_level,
		"total_treats": total_treats,
		"rescued_squirrels": rescued_squirrels,
		"muted": muted,
	}))


func complete_level(level_index: int) -> void:
	unlocked_level = maxi(unlocked_level, mini(11, level_index + 1))
	save_progress()


func add_treat() -> void:
	total_treats += 1
	save_progress()


func befriend_squirrel(level_id: String) -> void:
	rescued_squirrels[level_id] = true
	total_treats += 3
	save_progress()


func set_muted(value: bool) -> void:
	muted = value
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), value)
	save_progress()


func reset_journey() -> void:
	unlocked_level = 0
	total_treats = 0
	rescued_squirrels.clear()
	save_progress()

