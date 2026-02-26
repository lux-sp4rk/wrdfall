extends Node
## Singleton for managing player statistics and progress tracking
## Data persists via ConfigFile (maps to IndexedDB on web builds)

const STATS_FILE: String = "user://stats.cfg"
const TELEMETRY_URL: String = "https://hook.us1.make.com/6n3h27p3t5v5y5v5v5v5v5v5v5v5v5v5" # Placeholder - Uli can update

# Supabase Config
# Credentials are loaded from godot/addons/supabase/.env
# The .env file is gitignored - copy from .env.example and add your publishable key
# Get key from: Supabase Dashboard → Settings → API → Project API keys → "publishable"

# Current session tracking
var session_start_time: float = 0.0
var session_words_found: int = 0
var session_tiles_cleared: int = 0
var powerups_used: Dictionary = {"shake": 0, "hammer": 0, "swap": 0, "draw": 0}

# Stats data (loaded from file)
var total_tiles_cleared: int = 0
var total_words_found: int = 0
var total_time_played: float = 0.0  # seconds

var high_score: int = 0
var longest_word: String = ""
var max_wpm: float = 0.0

var session_history: Array[Dictionary] = []  # [{timestamp, score, words_found, duration}]

var _http_request: HTTPRequest
var _is_syncing: bool = false
var _last_sync_time: int = 0
var _current_user: SupabaseUser = null  # Stores the authenticated user

signal sync_completed(success: bool)
signal auth_completed(success: bool)

func _ready() -> void:
	load_stats()
	_setup_telemetry()
	# Defer Supabase setup to ensure the autoload is fully initialized
	call_deferred("_setup_supabase")
	start_session()

func _setup_telemetry() -> void:
	_http_request = HTTPRequest.new()
	add_child(_http_request)
	_http_request.request_completed.connect(_on_telemetry_completed)

func _setup_supabase() -> void:
	# Supabase is an autoload from the plugin
	# Credentials are loaded from godot/addons/supabase/.env
	if not has_node("/root/Supabase"):
		print("Supabase autoload not found")
		return

	if Supabase.auth == null:
		print("Supabase.auth not initialized yet")
		return

	# Connect to auth signals
	Supabase.auth.signed_in.connect(_on_supabase_signed_in)
	Supabase.auth.signed_out.connect(_on_supabase_signed_out)
	Supabase.auth.error.connect(_on_supabase_auth_failed)
	
	# Automatic anonymous login removed to avoid Captcha issues and friction.
	# We rely on local IndexedDB (user://stats.cfg) for "Guest" play.
	# Real auth is triggered when the user wants to view/submit to leaderboards.


func start_session() -> void:
	"""Begin tracking a new game session"""
	session_start_time = Time.get_unix_time_from_system()
	session_words_found = 0
	session_tiles_cleared = 0
	powerups_used = {"shake": 0, "hammer": 0, "swap": 0, "draw": 0}

func end_session(final_score: int, metadata: Dictionary = {}) -> void:
	"""Save session data and update records"""
	var duration: float = Time.get_unix_time_from_system() - session_start_time
	var session_wpm: float = _calculate_wpm(session_words_found, duration)

	# Update totals
	total_tiles_cleared += session_tiles_cleared
	total_words_found += session_words_found
	total_time_played += duration

	# Update records
	if final_score > high_score:
		high_score = final_score

	if session_wpm > max_wpm:
		max_wpm = session_wpm

	# Build session record
	var session_record: Dictionary = {
		"timestamp": session_start_time,
		"score": final_score,
		"words_found": session_words_found,
		"duration": duration,
		"wpm": session_wpm,
		"powerups": powerups_used.duplicate(),
		"difficulty": GameSettings.difficulty,
		"language": GameSettings.current_language
	}

	# Add any extra metadata (like loss reason)
	for key in metadata:
		session_record[key] = metadata[key]

	# Save session to history
	session_history.append(session_record)

	# Keep only last 50 sessions to prevent file bloat
	if session_history.size() > 50:
		session_history = session_history.slice(-50)

	save_stats()
	send_telemetry(session_record)

	# Push to Supabase if authenticated
	if is_authenticated():
		push_stats_to_supabase()
		submit_to_leaderboard(final_score)
		push_session_to_supabase(session_record)

func record_word(word: String, tiles_cleared: int) -> void:
	"""Track a word being found during gameplay"""
	session_words_found += 1
	session_tiles_cleared += tiles_cleared

	# Update longest word if applicable
	if word.length() > longest_word.length():
		longest_word = word

func record_powerup(type: String) -> void:
	"""Track power-up usage"""
	if powerups_used.has(type):
		powerups_used[type] += 1

func send_telemetry(data: Dictionary) -> void:
	"""Send session data to remote endpoint"""
	if TELEMETRY_URL.contains("placeholder") or TELEMETRY_URL.is_empty():
		return

	var json_data = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	_http_request.request(TELEMETRY_URL, headers, HTTPClient.METHOD_POST, json_data)

func _on_telemetry_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		print("Telemetry failed: ", response_code)

func save_stats() -> void:
	"""Persist stats to disk/IndexedDB"""
	var config := ConfigFile.new()

	# [totals]
	config.set_value("totals", "total_tiles_cleared", total_tiles_cleared)
	config.set_value("totals", "total_words_found", total_words_found)
	config.set_value("totals", "total_time_played", total_time_played)

	# [records]
	config.set_value("records", "high_score", high_score)
	config.set_value("records", "longest_word", longest_word)
	config.set_value("records", "max_wpm", max_wpm)

	# [history] - serialize as JSON since ConfigFile doesn't handle arrays directly
	config.set_value("history", "sessions", JSON.stringify(session_history))

	config.set_value("sync", "last_sync_time", _last_sync_time)

	var err := config.save(STATS_FILE)
	if err != OK:
		push_error("Failed to save stats: " + str(err))

	# Write guest-accessible JSON blob for React Stats page
	if OS.has_feature("web"):
		var js = JavaScriptBridge.get_interface("localStorage")
		if js:
			var blob = {
				"high_score": high_score,
				"longest_word": longest_word,
				"max_wpm": max_wpm,
				"total_words": total_words_found,
				"total_tiles": total_tiles_cleared,
				"total_time": total_time_played,
				"session_history": session_history
			}
			js.setItem("word-loom-stats", JSON.stringify(blob))

func load_stats() -> void:
	"""Load stats from disk/IndexedDB"""
	var config := ConfigFile.new()
	var err := config.load(STATS_FILE)

	if err != OK:
		# First time - no stats file exists yet
		return

	# [totals]
	total_tiles_cleared = config.get_value("totals", "total_tiles_cleared", 0)
	total_words_found = config.get_value("totals", "total_words_found", 0)
	total_time_played = config.get_value("totals", "total_time_played", 0.0)

	# [records]
	high_score = config.get_value("records", "high_score", 0)
	longest_word = config.get_value("records", "longest_word", "")
	max_wpm = config.get_value("records", "max_wpm", 0.0)

	# [history]
	var history_json: String = config.get_value("history", "sessions", "[]")
	var parsed = JSON.parse_string(history_json)
	if parsed is Array:
		session_history.clear()
		for item in parsed:
			if item is Dictionary:
				session_history.append(item)

	_last_sync_time = config.get_value("sync", "last_sync_time", 0)

func get_average_wpm() -> float:
	"""Calculate average WPM across all sessions"""
	if session_history.is_empty():
		return 0.0

	var total_wpm: float = 0.0
	for session in session_history:
		total_wpm += session.get("wpm", 0.0)

	return total_wpm / session_history.size()

func get_average_score() -> float:
	"""Calculate average score across all sessions"""
	if session_history.is_empty():
		return 0.0

	var total_score: int = 0
	for session in session_history:
		total_score += session.get("score", 0)

	return float(total_score) / session_history.size()

func _calculate_wpm(words: int, seconds: float) -> float:
	"""Calculate words per minute"""
	if seconds <= 0:
		return 0.0
	return (words / seconds) * 60.0

# --- Supabase Integration ---

func is_authenticated() -> bool:
	return _current_user != null

func get_user_email() -> String:
	return _current_user.email if _current_user else ""

func login_anonymous() -> void:
	Supabase.auth.sign_in_anonymous()

func login_with_email(email: String, password: String) -> void:
	Supabase.auth.sign_in(email, password)

func login_with_google() -> void:
	# OAuth sign-in with Google
	# Opens browser for OAuth flow
	Supabase.auth.sign_in_with_provider(SupabaseAuth.Providers.GOOGLE)

func login_with_apple() -> void:
	# OAuth sign-in with Apple
	# Opens browser for OAuth flow
	Supabase.auth.sign_in_with_provider(SupabaseAuth.Providers.APPLE)

func _on_supabase_signed_in(user: SupabaseUser) -> void:
	_current_user = user  # Store the authenticated user
	print("Signed in as: ", user.email)
	auth_completed.emit(true)
	pull_stats_from_supabase()

func _on_supabase_signed_out() -> void:
	_current_user = null  # Clear user on sign out
	print("Signed out")
	auth_completed.emit(false)  # Notify UI of sign out

func _on_supabase_auth_failed(error: SupabaseAuthError) -> void:
	print("Auth failed: ", error.message)
	auth_completed.emit(false)

func push_stats_to_supabase() -> void:
	if not is_authenticated() or _is_syncing:
		return

	_is_syncing = true
	var user_id = _current_user.id
	var data = {
		"id": user_id,
		"high_score": high_score,
		"total_words": total_words_found,
		"longest_word": longest_word,
		"max_wpm": max_wpm,
		"total_tiles": total_tiles_cleared,
		"total_time": total_time_played,
		"last_sync": Time.get_datetime_string_from_system(true)
	}

	var task = Supabase.database.query(SupabaseQuery.new().from("profiles").upsert([data]))
	task.completed.connect(func(result):
		_is_syncing = false
		if result:
			_last_sync_time = Time.get_unix_time_from_system()
			save_stats()
			sync_completed.emit(true)
		else:
			sync_completed.emit(false)
	)

func push_session_to_supabase(session_record: Dictionary) -> void:
	if not is_authenticated():
		return
	var data = {
		"user_id": _current_user.id,
		"score": session_record.get("score", 0),
		"wpm": session_record.get("wpm", 0.0),
		"words_found": session_record.get("words_found", 0),
		"duration": session_record.get("duration", 0.0),
		"timestamp": Time.get_datetime_string_from_system(true),
		"difficulty": session_record.get("difficulty", "normal"),
		"language": session_record.get("language", "en")
	}
	var task = Supabase.database.query(SupabaseQuery.new().from("sessions").insert([data]))
	task.completed.connect(func(result):
		if not result:
			push_error("StatsManager: failed to insert session into Supabase")
	)

func pull_stats_from_supabase() -> void:
	if not is_authenticated() or _is_syncing:
		return

	_is_syncing = true
	var user_id = _current_user.id
	var query = SupabaseQuery.new().from("profiles").select().eq("id", user_id).single()
	var task = Supabase.database.query(query)

	task.completed.connect(func(result):
		_is_syncing = false
		if result and result.size() > 0:
			var remote_data = result[0]
			_resolve_conflicts(remote_data)
			sync_completed.emit(true)
		else:
			# If no profile exists, push local stats
			push_stats_to_supabase()
	)

func _resolve_conflicts(remote_data: Dictionary) -> void:
	# Conflict resolution: keep the better value across all tracked fields
	var changed = false

	var remote_high_score = remote_data.get("high_score", 0)
	if remote_high_score > high_score:
		high_score = remote_high_score
		changed = true

	var remote_total_words = remote_data.get("total_words", 0)
	if remote_total_words > total_words_found:
		total_words_found = remote_total_words
		changed = true

	var remote_max_wpm = remote_data.get("max_wpm", 0.0)
	if remote_max_wpm > max_wpm:
		max_wpm = remote_max_wpm
		changed = true

	var remote_longest = remote_data.get("longest_word", "")
	if remote_longest.length() > longest_word.length():
		longest_word = remote_longest
		changed = true

	var remote_total_tiles = remote_data.get("total_tiles", 0)
	if remote_total_tiles > total_tiles_cleared:
		total_tiles_cleared = remote_total_tiles
		changed = true

	var remote_total_time = remote_data.get("total_time", 0.0)
	if remote_total_time > total_time_played:
		total_time_played = remote_total_time
		changed = true

	if changed:
		save_stats()

func submit_to_leaderboard(score: int) -> void:
	if not is_authenticated():
		return

	var user_id = _current_user.id
	var data = {
		"user_id": user_id,
		"score": score
	}

	Supabase.database.query(SupabaseQuery.new().from("leaderboards").insert([data]))

func get_leaderboard(limit: int = 10) -> void:
	var query = SupabaseQuery.new().from("leaderboards").select(PackedStringArray(["score", "profiles(display_name)"])).order("score", false).limit(limit)
	var task = Supabase.database.query(query)
	task.completed.connect(func(result):
		if result:
			print("Leaderboard: ", result)
	)
