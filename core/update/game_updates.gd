extends Node
## Checks the latest GitHub release of the game and offers its download for this platform.
## The manifest only names a tag and a file; download links are always built on RELEASES_URL.
## The update is installed from inside the game (since 0.8): it downloads the release file, checks its SHA-256
## from the manifest and then, on Android, opens the system "Install" screen for the APK (same signing key on every
## release, saves kept); on Windows it takes the new .exe out of the ZIP, swaps it for the running one and restarts.
## Without a checksum, or when that fails (folder without write access, no installer), it falls back to the browser.
signal status_changed(message: String)
signal update_available(version: String)
## Download progress, 0..1 (only while installing from inside the game).
signal progress_changed(fraction: float)

const PLATFORM_FILES := {"android": ".apk", "windows": ".zip"}
## Where the release file is downloaded before it is checked and installed.
const DOWNLOAD_PATHS := {"android": "user://update.apk", "windows": "user://update.zip"}
## The running .exe is renamed to this before the new one takes its place; deleted on the next start.
const OLD_SUFFIX := ".old"

var download_url := ""
var version_name := ""
## Expected SHA-256 (hex) of the release file; empty for releases made before 0.8.
var sha256 := ""
var installing := false
var _request: HTTPRequest
var _download: HTTPRequest
var _checking := false
var _quiet := false


func _ready() -> void:
	_request = HTTPRequest.new()
	_request.timeout = 15.0
	_request.body_size_limit = 64 * 1024
	add_child(_request)
	_request.request_completed.connect(_completed)
	_download = HTTPRequest.new()
	_download.timeout = 0.0
	_download.download_chunk_size = 256 * 1024
	add_child(_download)
	_download.request_completed.connect(_downloaded)
	_clean_leftovers()
	# Only exported games look for updates by themselves; the editor and tests never do.
	if OS.has_feature("template") and not platform().is_empty():
		check_now.call_deferred(true)


## "android", "windows" or "" when this platform has no release file.
## The Microsoft Store build (custom feature "store") is updated by the Store itself.
func platform() -> String:
	if OS.has_feature("store"):
		return ""
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
	sha256 = ""
	var hashes: Variant = data.get("sha256", {})
	if hashes is Dictionary:
		var expected := str((hashes as Dictionary).get(target, "")).to_lower()
		if RegEx.create_from_string("^[0-9a-f]{64}$").search(expected) != null:
			sha256 = expected
	update_available.emit(version_name)
	status_changed.emit("Versão %s disponível. Toque em Baixar atualização." % version_name)


## Botão do menu: procura atualização ou instala a que foi achada.
func open_download() -> void:
	if download_url.is_empty():
		check_now()
		return
	if installing:
		return
	if sha256.is_empty() or not OS.has_feature("template"):
		_open_in_browser()
		return
	installing = true
	var path: String = DOWNLOAD_PATHS[platform()]
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_download.download_file = path
	if _download.request(download_url) != OK:
		_fail("Não consegui começar o download.")
		return
	status_changed.emit("Baixando a versão %s..." % version_name)
	progress_changed.emit(0.0)


func _process(_delta: float) -> void:
	if installing and _download.get_body_size() > 0:
		progress_changed.emit(float(_download.get_downloaded_bytes()) / _download.get_body_size())


func _downloaded(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		_fail("O download falhou. Confira a internet e tente de novo.")
		return
	var path: String = DOWNLOAD_PATHS[platform()]
	if not verify_file(path, sha256):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		_fail("O arquivo baixado veio diferente do esperado. Tente de novo.")
		return
	progress_changed.emit(1.0)
	if platform() == "android":
		status_changed.emit("Confirme a instalação na tela do Android.")
		installing = false
		if OS.shell_open(ProjectSettings.globalize_path(path)) != OK:
			_open_in_browser()
		return
	var error := install_windows(path, OS.get_executable_path())
	if error != "":
		_fail(error)
		return
	status_changed.emit("Atualizado! Reabrindo o jogo...")
	OS.create_process(OS.get_executable_path(), [])
	get_tree().quit()


## SHA-256 do arquivo confere com o esperado (lido em pedaços: o arquivo tem centenas de MB).
static func verify_file(path: String, expected: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or expected.is_empty():
		return false
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	while file.get_position() < file.get_length():
		context.update(file.get_buffer(1024 * 1024))
	return context.finish().hex_encode() == expected


## Windows: tira o .exe de dentro do ZIP e troca pelo que está rodando (que vira .old: o Windows deixa
## renomear um .exe aberto, só não deixa apagar). Volta "" se deu certo, ou a mensagem de erro.
static func install_windows(zip_path: String, exe_path: String) -> String:
	var zip := ZIPReader.new()
	if zip.open(zip_path) != OK:
		return "O arquivo baixado não abriu. Tente de novo."
	var inside := ""
	for entry in zip.get_files():
		if entry.get_file().to_lower() == exe_path.get_file().to_lower():
			inside = entry
	if inside.is_empty():
		zip.close()
		return "A versão nova não tem o jogo para Windows."
	var bytes := zip.read_file(inside)
	zip.close()
	var fresh := exe_path + ".new"
	var file := FileAccess.open(fresh, FileAccess.WRITE)
	if file == null:
		return "Não dá para gravar na pasta do jogo. Baixe pelo site e extraia por cima."
	file.store_buffer(bytes)
	file.close()
	var old := exe_path + OLD_SUFFIX
	DirAccess.remove_absolute(old)
	if DirAccess.rename_absolute(exe_path, old) != OK:
		DirAccess.remove_absolute(fresh)
		return "Não consegui trocar o jogo. Feche outras cópias abertas e tente de novo."
	if DirAccess.rename_absolute(fresh, exe_path) != OK:
		DirAccess.rename_absolute(old, exe_path)
		return "Não consegui trocar o jogo. Tente de novo."
	DirAccess.remove_absolute(ProjectSettings.globalize_path(zip_path))
	return ""


## Sobras da última atualização: o .exe antigo e os arquivos baixados.
func _clean_leftovers() -> void:
	if OS.has_feature("template") and OS.has_feature("windows"):
		DirAccess.remove_absolute(OS.get_executable_path() + OLD_SUFFIX)
	for path: String in DOWNLOAD_PATHS.values():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _fail(message: String) -> void:
	installing = false
	progress_changed.emit(-1.0)
	status_changed.emit(message)


func _open_in_browser() -> void:
	if OS.shell_open(download_url) != OK:
		status_changed.emit("Não consegui abrir o download. Tente novamente.")


func _report(message: String) -> void:
	if not _quiet:
		status_changed.emit(message)
