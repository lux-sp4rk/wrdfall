extends RefCounted
class_name DictionaryService

# Loads a local word list from res://data/words.txt and performs offline membership checks.
# - Case-insensitive
# - Rejects empty / non-alpha tokens

const WORDLIST_PATH := "res://data/words.txt"

var _loaded: bool = false
var _words := {} # Dictionary used as a Set: word -> true

func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_words.clear()

	if not FileAccess.file_exists(WORDLIST_PATH):
		# No dictionary shipped (shouldn\x27t happen once Issue #5 is implemented)
		return

	var f := FileAccess.open(WORDLIST_PATH, FileAccess.READ)
	if f == null:
		return

	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line.is_empty():
			continue
		if line.begins_with("#"):
			continue
		var w := line.to_upper()
		if _is_alpha_only(w):
			_words[w] = true

	f.close()

func is_valid_word(word: String) -> bool:
	_ensure_loaded()
	var w := word.strip_edges().to_upper()
	if w.is_empty():
		return false
	if not _is_alpha_only(w):
		return false
	return _words.has(w)

func _is_alpha_only(s: String) -> bool:
	# Godot 4: String.length(), String.unicode_at(i)
	for i in range(s.length()):
		var c := s.unicode_at(i)
		if c < 65 or c > 90:
			return false
	return true
