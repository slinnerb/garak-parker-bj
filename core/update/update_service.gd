extends Node
## Update checker (autoload singleton: `Updater`).
##
## Asks the GitHub Releases API whether a newer build exists and reports back
## via signals. It never downloads or executes anything itself — when an update
## is found the UI offers to open the releases page in the browser. That keeps
## the flow safe and avoids the Windows headache of overwriting a running .exe.
##
## Flow:
##   Updater.check_for_updates()
##     -> check_started
##     -> update_available({version, current, notes, url, published_at})
##        | up_to_date(current)
##        | check_failed(reason)
##
## Also mirrored on EventBus.update_check_completed(status, info) for anything
## that would rather listen globally.

signal check_started()
signal update_available(info: Dictionary)
signal up_to_date(current_version: String)
signal check_failed(reason: String)

const REQUEST_TIMEOUT_SECONDS := 12.0

var _http: HTTPRequest
var _busy := false


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = REQUEST_TIMEOUT_SECONDS
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)


func is_busy() -> bool:
	return _busy


## Starts an update check. No-op if one is already running.
func check_for_updates() -> void:
	if _busy:
		Log.info(Log.Cat.UPDATE, "Check already in progress; ignoring")
		return

	if not UpdateConfig.is_configured():
		var reason := "Updates are not set up yet (no release source configured)."
		Log.warn(Log.Cat.UPDATE, reason)
		emit_signal("check_failed", reason)
		EventBus.emit_signal("update_check_completed", "failed", {"reason": reason})
		return

	_busy = true
	emit_signal("check_started")
	var url := UpdateConfig.latest_release_url()
	Log.info(Log.Cat.UPDATE, "Checking for updates: %s" % url)
	var headers := PackedStringArray([
		"Accept: application/vnd.github+json",
		"User-Agent: ReincarnationRoguelike/%s" % GameVersion.current(),
		"X-GitHub-Api-Version: 2022-11-28",
	])
	var err := _http.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		_busy = false
		var reason := "Could not start the update request (error %d)." % err
		Log.error(Log.Cat.UPDATE, reason)
		emit_signal("check_failed", reason)
		EventBus.emit_signal("update_check_completed", "failed", {"reason": reason})


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_busy = false

	if result != HTTPRequest.RESULT_SUCCESS:
		_fail("Could not reach the update server. Check your internet connection. (result %d)" % result)
		return

	match response_code:
		200:
			_handle_release(body)
		404:
			# Repo exists but has no releases yet (or is unreachable) — from the
			# player's view there is simply nothing newer to get.
			Log.info(Log.Cat.UPDATE, "No releases published (404). Treating as up to date.")
			_up_to_date()
		403, 429:
			_fail("GitHub is rate-limiting update checks right now. Please try again later.")
		_:
			_fail("Update check failed (HTTP %d)." % response_code)


func _handle_release(body: PackedByteArray) -> void:
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		_fail("The update server returned something unexpected.")
		return

	var latest_tag := str(parsed.get("tag_name", ""))
	if latest_tag.is_empty():
		_fail("The latest release has no version tag.")
		return

	# Prereleases/drafts should not nag players. latest-release already excludes
	# drafts; also skip anything explicitly flagged prerelease.
	if bool(parsed.get("prerelease", false)):
		Log.info(Log.Cat.UPDATE, "Latest is a prerelease; ignoring")
		_up_to_date()
		return

	var current := GameVersion.current()
	if SemVer.is_newer(latest_tag, current):
		var info := {
			"version": latest_tag,
			"current": current,
			"notes": str(parsed.get("body", "")).strip_edges(),
			"url": UpdateConfig.releases_page_url(),
			"published_at": str(parsed.get("published_at", "")),
		}
		Log.info(Log.Cat.UPDATE, "Update available: %s (current %s)" % [latest_tag, current])
		emit_signal("update_available", info)
		EventBus.emit_signal("update_check_completed", "available", info)
	else:
		Log.info(Log.Cat.UPDATE, "Up to date (latest %s, current %s)" % [latest_tag, current])
		_up_to_date()


func _up_to_date() -> void:
	var current := GameVersion.current()
	emit_signal("up_to_date", current)
	EventBus.emit_signal("update_check_completed", "up_to_date", {"current": current})


func _fail(reason: String) -> void:
	Log.error(Log.Cat.UPDATE, reason)
	emit_signal("check_failed", reason)
	EventBus.emit_signal("update_check_completed", "failed", {"reason": reason})
