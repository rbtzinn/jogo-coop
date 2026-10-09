extends Node
## Checks the latest GitHub release of the game and offers its download for this platform.
## The manifest only names a tag and a file; download links are always built on RELEASES_URL.
## Android asks the player to confirm the APK install (same signing key on every release);
## on Windows the browser downloads the new ZIP.
signal status_changed(message: String)
signal update_available(version: String)

const PLATFORM_FILES := {"android": ".apk", "windows": ".zip"}

var download_url := ""
var version_name := ""
var _request: HTTPRequest
var _checking := false
var _quiet := false


func _ready() -> void:
	_request = HTTPRequest.new()
	_request.timeout = 15.0
	_request.body_size_limit = 64 * 1024
	add_child(_request)
	_request.request_completed.connect(_completed)
	# Only exported games look for updates by themselves; the editor and tests never do.
	if OS.has_feature("template") and not platform().is_empty():
		check_now.call_deferred(true)


## "android", "windows" or "" when this platform has no release file.
func platform() -> String:
	if OS.has_feature("android"):
		return "android"
	if OS.has_feature("windows"):
		return "windows"
	return ""


func check_now(quiet := false) -> void:
	if _checking:
		return
	_quiet = quiet
	if OnlineConfig.UPDATE_URL.is_empty():
		_report("As atualizações ainda não foram configuradas nesta versão.")
		return
	_checking = true
	_report("Procurando atualizações...")
	var error := _request.request(OnlineConfig.UPDATE_URL)
	if error != OK:
		_checking = false
		_report("Não consegui consultar atualizações. Tente novamente.")


func _completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_checking = false
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		_report("Não consegui consultar atualizações. Tente novamente.")
		return
	_apply_manifest(body, platform())


func _apply_manifest(body: PackedByteArray, target: String) -> void:
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not parsed is Dictionary:
		_report("O servidor respondeu com uma atualização inválida.")
		return
	var data: Dictionary = parsed
	var code: Variant = data.get("version_code", 0)
	if data.get("package", "") != OnlineConfig.ANDROID_PACKAGE or not (code is float or code is int):
		_report("O servidor respondeu com uma atualização inválida.")
		return
	if float(code) != floorf(float(code)) or float(code) < 1 or float(code) >= 2100000000:
		_report("O servidor respondeu com uma atualização inválida.")
		return
	if int(code) <= OnlineConfig.VERSION_CODE:
		_report("Você já está na versão mais recente.")
		return
	var tag := str(data.get("tag", ""))
	var files: Variant = data.get("files", {})
	var file := str((files as Dictionary).get(target, "")) if files is Dictionary else ""
	var tag_pattern := RegEx.create_from_string("^v[A-Za-z0-9._-]{1,60}$")
	var file_pattern := RegEx.create_from_string("^[A-Za-z0-9_.-]{1,100}$")
	if tag_pattern.search(tag) == null or tag.contains("..") or not files is Dictionary:
		_report("O servidor respondeu com uma atualização inválida.")
		return
	if file.is_empty() or not PLATFORM_FILES.has(target):
		_report("A versão nova ainda não tem arquivo para este aparelho.")
		return
	if file_pattern.search(file) == null or file.contains("..") or not file.ends_with(PLATFORM_FILES[target]):
		_report("O servidor respondeu com uma atualização inválida.")
		return
	download_url = "%s/download/%s/%s" % [OnlineConfig.RELEASES_URL, tag, file]
	version_name = str(data.get("version_name", "nova versão")).left(60)
	update_available.emit(version_name)
	status_changed.emit("Versão %s disponível. Toque em Baixar atualização." % version_name)


func open_download() -> void:
	if download_url.is_empty():
		check_now()
		return
	if OS.shell_open(download_url) != OK:
		status_changed.emit("Não consegui abrir o download. Tente novamente.")


func _report(message: String) -> void:
	if not _quiet:
		status_changed.emit(message)
