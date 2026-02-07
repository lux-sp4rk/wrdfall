class_name PuzzleLoader
extends RefCounted

const PUZZLES_PATH := "res://data/puzzles.json"

var puzzles: Array[Dictionary] = []


func _init() -> void:
	_load_puzzles()


func _load_puzzles() -> void:
	var file := FileAccess.open(PUZZLES_PATH, FileAccess.READ)
	if file == null:
		push_error("PuzzleLoader: cannot open %s (error %d)" % [PUZZLES_PATH, FileAccess.get_open_error()])
		return

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	if err != OK:
		push_error("PuzzleLoader: JSON parse error on line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return

	var data: Dictionary = json.data
	if not data.has("puzzles") or not data["puzzles"] is Array:
		push_error("PuzzleLoader: expected top-level 'puzzles' array")
		return

	puzzles.assign(data["puzzles"])


func get_puzzle(index: int) -> Dictionary:
	if index < 0 or index >= puzzles.size():
		push_error("PuzzleLoader: index %d out of range (0..%d)" % [index, puzzles.size() - 1])
		return {}
	return puzzles[index]


func get_puzzle_by_id(puzzle_id: int) -> Dictionary:
	for p in puzzles:
		if p.get("id", -1) == puzzle_id:
			return p
	push_error("PuzzleLoader: no puzzle with id %d" % puzzle_id)
	return {}


func puzzle_count() -> int:
	return puzzles.size()
