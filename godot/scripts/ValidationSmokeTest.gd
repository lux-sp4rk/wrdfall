extends Node
class_name ValidationSmokeTest

# Lightweight verification helper.
# Run in editor console (or attach to a temp scene) and call:
#   ValidationSmokeTest.run()

static func run() -> void:
	var dict := DictionaryService.new()
	assert(dict.is_valid_word("hello") == true)
	assert(dict.is_valid_word("HELLO") == true)
	assert(dict.is_valid_word("he11o") == false)
	assert(dict.is_valid_word("") == false)
	assert(dict.is_valid_word("zzzzzzz") == false)

	var rc := RuleChecker.new()
	var slot := {"length": 5, "rules": [{"type": "starts_with", "value": "S"}]}
	assert(rc.validate_word_for_slot("STARE", slot).ok == true)
	assert(rc.validate_word_for_slot("TRASH", slot).ok == false)
	assert(rc.validate_word_for_slot("STAR", slot).ok == false)

	print("ValidationSmokeTest: OK")
