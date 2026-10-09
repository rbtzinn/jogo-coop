extends Node
## The browser downloads the APK; Android asks the player to allow and confirm installation.
## Replacing the app requires the same permanent signing key on every release.
signal status_changed(message: String)
signal update_available(version: String)

var download_url := ""
var version_name := ""
var _request: HTTPRequest
var _checking := false


func _ready() -> void:
	_request = HTTPRequest.new()
	_request.timeout = 15.0
	_request.body_size_limit = 64 * 1024
	add_child(_request)
	_request.request_completed.connect(_completed)


func check_now() -> void:
	if _checking:
		return
	if OnlineConfig.UPDATE_URL.is_empty():
		status_changed.emit("As atualizações ainda não foram configuradas nesta versão.")
		return
	_checking = true
	status_changed.emit("Procurando atualizações...")
	var error := _request.request(OnlineConfig.UPDATE_URL)
	if error != OK:
		_checking = false
		status_changed.emit("Não consegui consultar atualizações. Tente novamente.")


func _completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_checking = false
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		status_changed.emit("Não consegui consultar atualizações. Tente novamente.")
		return
	_apply_manifest(body, OnlineConfig.UPDATE_URL)


func _apply_manifest(body: PackedByteArray, source_url: String) -> void:
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not parsed is Dictionary:
		status_changed.emit("O servidor respondeu com uma atualização inválida.")
		return
	var data: Dictionary = parsed
	var code: Variant = data.get("version_code", 0)
	if data.get("package", "") != OnlineConfig.ANDROID_PACKAGE or not (code is float or code is int):
		status_changed.emit("O servidor respondeu com uma atualização inválida.")
		return
	if float(code) != floorf(float(code)) or float(code) < 1 or float(code) >= 2100000000:
		status_changed.emit("O servidor respondeu com uma atualização inválida.")
		return
	if int(code) <= OnlineConfig.VERSION_CODE:
		status_changed.emit("Você já está na versão mais recente.")
		return
	var url := str(data.get("download_url", ""))
	# All release links stay on the configured HTTPS host, never arbitrary HTTP URLs.
	var path_start := source_url.find("/", 8)
	var host_prefix := source_url.substr(0, path_start) if path_start > 8 else ""
	var filename_pattern := RegEx.new()
	filename_pattern.compile("^[A-Za-z0-9_.-]+\\.apk$")
	var expected_prefix := host_prefix + "/downloads/"
	if not host_prefix.begins_with("https://") or not url.begins_with(expected_prefix) or filename_pattern.search(url.trim_prefix(expected_prefix)) == null:
		status_changed.emit("O servidor respondeu com uma atualização inválida.")
		return
	download_url = url
	version_name = str(data.get("version_name", "nova versão")).left(60)
	update_available.emit(version_name)
	status_changed.emit("Versão %s disponível. Toque em Baixar atualização." % version_name)


func open_download() -> void:
	if download_url.is_empty():
		check_now()
		return
	if OS.shell_open(download_url) != OK:
		status_changed.emit("Não consegui abrir o download. Tente novamente.")
