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
## Install flow (auto-download + self-replace + relaunch).
signal install_started()
signal install_failed(reason: String)
## Install can't run here (e.g. in the editor, or no build attached).
signal install_unavailable(reason: String)

const REQUEST_TIMEOUT_SECONDS := 12.0
const DOWNLOAD_TIMEOUT_SECONDS := 120.0

var _http: HTTPRequest
var _download_http: HTTPRequest
var _busy := false
var _installing := false
var _download_zip_path := ""


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = REQUEST_TIMEOUT_SECONDS
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)

	# A separate request for the (large, streamed-to-disk) build download.
	_download_http = HTTPRequest.new()
	_download_http.timeout = DOWNLOAD_TIMEOUT_SECONDS
	add_child(_download_http)
	_download_http.request_completed.connect(_on_download_completed)


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
		"User-Agent: ReincarnationRoguelite/%s" % GameVersion.current(),
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
			"download_url": _find_build_asset(parsed),
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


# ---------------------------------------------------------------------------
# Install (auto-download the build, self-replace, relaunch)
# ---------------------------------------------------------------------------

## Downloads the update's build and, when done, swaps it in and relaunches. Only
## works from a packaged Windows build — in the editor (or with no build asset)
## it emits install_unavailable and does nothing destructive.
func install_update(info: Dictionary) -> void:
	if _installing:
		return
	if OS.has_feature("editor"):
		_install_unavailable("Self-update only runs in the packaged game, not the editor. Use the download page instead.")
		return
	if OS.get_name() != "Windows":
		_install_unavailable("Automatic install is currently Windows-only.")
		return
	var url := str(info.get("download_url", ""))
	if url.is_empty():
		_install_unavailable("This release has no downloadable build attached. Try the download page.")
		return

	_installing = true
	_download_zip_path = _temp_zip_path()
	_download_http.download_file = _download_zip_path
	Log.info(Log.Cat.UPDATE, "Downloading update from %s" % url)
	emit_signal("install_started")
	var headers := PackedStringArray([
		"Accept: application/octet-stream",
		"User-Agent: ReincarnationRoguelite/%s" % GameVersion.current(),
	])
	var err := _download_http.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		_install_failed("Could not start the download (error %d)." % err)


func _on_download_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if not _installing:
		return
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		_install_failed("Download failed (result %d, HTTP %d)." % [result, response_code])
		return

	var dest_dir := OS.get_executable_path().get_base_dir()
	var new_exe := SelfUpdater.extract_exe(_download_zip_path, dest_dir)
	if new_exe.is_empty():
		_install_failed("The downloaded update could not be unpacked.")
		return

	Log.info(Log.Cat.UPDATE, "Update unpacked to %s; launching swap helper" % new_exe)
	if not SelfUpdater.begin_swap(new_exe):
		_install_failed("Could not start the updater helper.")
		return

	# The helper waits for us to exit, swaps the build, and relaunches it.
	Log.info(Log.Cat.UPDATE, "Quitting for update swap")
	get_tree().quit()


func _install_failed(reason: String) -> void:
	_installing = false
	Log.error(Log.Cat.UPDATE, "Install failed: %s" % reason)
	emit_signal("install_failed", reason)


func _install_unavailable(reason: String) -> void:
	Log.warn(Log.Cat.UPDATE, "Install unavailable: %s" % reason)
	emit_signal("install_unavailable", reason)


## Picks a release asset to download: the first .zip (the packaged Windows build).
func _find_build_asset(release: Dictionary) -> String:
	var assets = release.get("assets", [])
	if assets is Array:
		for asset in assets:
			if asset is Dictionary and str(asset.get("name", "")).to_lower().ends_with(".zip"):
				return str(asset.get("browser_download_url", ""))
	return ""


func _temp_zip_path() -> String:
	# Alongside the game so extraction is a same-drive move later.
	return OS.get_executable_path().get_base_dir().path_join("update_download.zip")
