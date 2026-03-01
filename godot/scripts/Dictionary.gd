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
	# Use JavaScriptBridge.eval() for all checks (more reliable than get_interface)
	var has_dict = JavaScriptBridge.eval("typeof window.WORD_LOOM_DICTIONARY !== 'undefined'")
	if not has_dict:
		print("Dictionary: window.WORD_LOOM_DICTIONARY not found (fallback to file)")
		return false

	var word_count = int(JavaScriptBridge.eval("window.WORD_LOOM_DICTIONARY.words.length"))
	if word_count <= 0:
		print("Dictionary: JavaScript words array empty (fallback to file)")
		return false

	print("Dictionary: Loading %d words from JavaScript" % word_count)
	
	# Load words using eval() for reliable array access
	var loaded_count = 0
	for i in range(word_count):
		var word = JavaScriptBridge.eval("window.WORD_LOOM_DICTIONARY.words[%d]" % i)
		if word != null:
			var w = String(word).to_upper()
			if _is_alpha_only(w):
				_words[w] = true
				loaded_count += 1

	print("Dictionary: Loaded %d words from external dictionary (filtered from %d)" % [loaded_count, word_count])
	return loaded_count > 0


func _load_from_file() -> void:
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
