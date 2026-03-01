extends RefCounted
class_name DictionaryService

# Loads a word list and performs offline membership checks.
# - Case-insensitive
# - Rejects empty / non-alpha tokens
# - Supports extra codepoints (e.g. Ñ for Spanish)

var _loaded: bool = false
var _words := {} # Dictionary used as a Set: word -> true
var _path: String = "res://data/words_en.txt"
var _extra_alpha: Array = []  # extra allowed Unicode codepoints


func _init(path: String = "res://data/words_en.txt", extra_alpha: Array = []) -> void:
	_path = path
	_extra_alpha = extra_alpha


func reload(path: String, extra_alpha: Array = []) -> void:
	_path = path
	_extra_alpha = extra_alpha
	_loaded = false
	_words.clear()
	_ensure_loaded()


func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_words.clear()

	# WEB BUILD: Try external dictionary from JavaScript
	if OS.has_feature("web"):
		if _try_load_from_js():
			return  # Success, done

	# FALLBACK: Load from embedded file (desktop/editor)
	_load_from_file()


func _try_load_from_js() -> bool:
	# Access window.WORD_LOOM_DICTIONARY via JavaScriptBridge
	var js_interface = JavaScriptBridge.get_interface("window")
	if js_interface == null:
		return false

	if not js_interface.has("WORD_LOOM_DICTIONARY"):
		return false

	var dict_data = js_interface.WORD_LOOM_DICTIONARY
	if dict_data == null or not dict_data.has("words"):
		return false

	var words_array = dict_data.words
	if words_array == null:
		return false

	# Load words from JavaScript array
	print("Loading words from JS: ", words_array.size())
	for word in words_array:
		var w = String(word).to_upper()
		if _is_alpha_only(w):
			_words[w] = true

	print("Dictionary: Loaded %d words from external dictionary" % _words.size())
	return true


func _load_from_file() -> void:
	# Existing file loading logic (unchanged)
	if not FileAccess.file_exists(_path):
		print("Dictionary: File not found: %s" % _path)
		return

	var f := FileAccess.open(_path, FileAccess.READ)
	if f == null:
		print("Dictionary: Failed to open file: %s" % _path)
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
	print("Dictionary: Loaded %d words from file: %s" % [_words.size(), _path])


func is_valid_word(word: String) -> bool:
	_ensure_loaded()
	var w := word.strip_edges().to_upper()
	if w.is_empty():
		return false
	if not _is_alpha_only(w):
		return false
	return _words.has(w)


func _is_alpha_only(s: String) -> bool:
	for i in range(s.length()):
		var c := s.unicode_at(i)
		if c >= 65 and c <= 90:
			continue  # A-Z
		if _extra_alpha.has(c):
			continue  # e.g. Ñ (209)
		return false
	return true
