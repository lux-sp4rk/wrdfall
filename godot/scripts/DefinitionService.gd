extends Node

## Cache: word -> { definition: String, part_of_speech: String }
var _cache: Dictionary = {}
var _http_request: HTTPRequest
var _pending_word: String = ""
var _pending_callback: Callable

signal definition_ready(word: String, definition: String, part_of_speech: String)
signal definition_error(word: String, error: String)

func _ready() -> void:
    _http_request = HTTPRequest.new()
    add_child(_http_request)
    _http_request.request_completed.connect(_on_request_completed)

func lookup_definition(word: String) -> void:
    var w := word.to_upper().strip_edges()
    if w.is_empty():
        definition_error.emit(word, "Empty word")
        return

    # Cache hit
    if _cache.has(w):
        var data = _cache[w]
        definition_ready.emit(w, data.definition, data.part_of_speech)
        return

    # Fetch from API
    _pending_word = w
    var url := "https://api.dictionaryapi.dev/api/v2/entries/en/" + w.to_lower()
    var err = _http_request.request(url)
    if err != OK:
        definition_error.emit(w, "Request failed")

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
    if response_code != 200:
        definition_error.emit(_pending_word, "HTTP %d" % response_code)
        return

    var json = JSON.parse_string(body.get_string_from_utf8())
    if json == null or not json is Array or json.is_empty():
        definition_error.emit(_pending_word, "Parse error")
        return

    var entry = json[0] as Dictionary
    var meanings: Array = entry.get("meanings", []) as Array
    if meanings.is_empty():
        definition_error.emit(_pending_word, "No meanings found")
        return

    var first_meaning: Dictionary = meanings[0] as Dictionary
    var part_of_speech: String = first_meaning.get("partOfSpeech", "")
    var definitions: Array = first_meaning.get("definitions", []) as Array
    if definitions.is_empty():
        definition_error.emit(_pending_word, "No definitions found")
        return

    var definition: String = (definitions[0] as Dictionary).get("definition", "")

    # Cache
    _cache[_pending_word] = { "definition": definition, "part_of_speech": part_of_speech }

    definition_ready.emit(_pending_word, definition, part_of_speech)