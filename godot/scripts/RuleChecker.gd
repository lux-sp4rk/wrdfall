extends RefCounted
class_name RuleChecker

# Validates a submitted word against a puzzle "slot" dictionary from puzzles.json.
# Returns a result Dictionary: { ok: bool, message: String }

func validate_word_for_slot(word: String, slot: Dictionary) -> Dictionary:
	var w := word.strip_edges().to_upper()
	if w.is_empty():
		return {"ok": false, "message": "Enter a word."}

	# Length constraint (current JSON uses exact length)
	var expected_len = slot.get("length", null)
	if expected_len != null:
		if w.length() != int(expected_len):
			return {"ok": false, "message": "Must be %d letters." % int(expected_len)}

	# Rules: starts_with, ends_with, contains
	for rule in slot.get("rules", []):
		if typeof(rule) != TYPE_DICTIONARY:
			continue
		var t := str(rule.get("type", ""))
		var v := str(rule.get("value", "")).to_upper()
		match t:
			"starts_with":
				if not w.begins_with(v):
					return {"ok": false, "message": "Must start with %s." % v}
			"ends_with":
				if not w.ends_with(v):
					return {"ok": false, "message": "Must end with %s." % v}
			"contains":
				if w.find(v) == -1:
					return {"ok": false, "message": "Must include %s." % v}
			_:
				# Unknown rule types are ignored for now (keeps offline validator forward-compatible)
				pass

	return {"ok": true, "message": "OK"}
