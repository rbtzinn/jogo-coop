extends Node
## Remote update manifests are untrusted; never open a different package, host or file type.
var failures := 0
var offered := false
var message := ""
const BASE := OnlineConfig.RELEASES_URL + "/download/"

func _ready() -> void:
	GameUpdates.update_available.connect(func(_version: String) -> void: offered = true)
	GameUpdates.status_changed.connect(func(text: String) -> void: message = text)
	var valid := {"package": OnlineConfig.ANDROID_PACKAGE, "version_code": OnlineConfig.VERSION_CODE + 1,
		"version_name": "test", "tag": "v0.9-test",
		"files": {"android": "RespeitavelPublico-Android.apk", "windows": "RespeitavelPublico-Windows.zip"}}
	apply(valid, "android")
	check(offered and GameUpdates.download_url == BASE + "v0.9-test/RespeitavelPublico-Android.apk", "android release offered from GitHub")
	apply(valid, "windows")
	check(offered and GameUpdates.download_url == BASE + "v0.9-test/RespeitavelPublico-Windows.zip", "windows release offered from GitHub")
	for patch in [
		{"package": "other.app"}, {"version_code": "999"}, {"version_code": 3.5}, {"version_code": -1},
		{"version_code": 2100000000}, {"tag": "0.9"}, {"tag": "v../../evil"}, {"tag": "v1/2"}, {"tag": ""},
		{"files": {"android": "../game.apk", "windows": "game.zip"}},
		{"files": {"android": "https://evil.test/game.apk", "windows": "game.zip"}},
		{"files": {"android": "game.apk?x=1", "windows": "game.zip"}},
		{"files": {"android": "game.zip", "windows": "game.apk"}},
		{"files": "game.apk"},
	]:
		var invalid := valid.duplicate(true)
		invalid.merge(patch, true)
		apply(invalid, "android")
		check(not offered and GameUpdates.download_url.is_empty() and "inválida" in message, "invalid remote manifest rejected: %s" % str(patch))
	var android_only := valid.duplicate(true)
	android_only.files = {"android": "RespeitavelPublico-Android.apk"}
	apply(android_only, "windows")
	check(not offered and "não tem arquivo" in message, "release without this platform's file is not offered")
	apply(valid, "")
	check(not offered and "não tem arquivo" in message, "platform without releases is not offered")
	var current := valid.duplicate(true)
	current.version_code = OnlineConfig.VERSION_CODE
	apply(current, "android")
	check(not offered and "mais recente" in message, "installed version is not offered again")
	offered = false
	GameUpdates._apply_manifest("null".to_utf8_buffer(), "android")
	check(not offered and "inválida" in message, "non-object JSON rejected")
	_test_checksums(valid)
	_test_windows_swap()
	print("FAILURES: %d" % failures)
	get_tree().quit(failures)


## O manifesto traz o SHA-256 de cada arquivo; só um hex de 64 dígitos vale.
func _test_checksums(valid: Dictionary) -> void:
	var good := "ab".repeat(32)
	var with_hash := valid.duplicate(true)
	with_hash.sha256 = {"android": good.to_upper(), "windows": "nope"}
	apply(with_hash, "android")
	check(offered and GameUpdates.sha256 == good, "release checksum read from the manifest")
	apply(with_hash, "windows")
	check(offered and GameUpdates.sha256.is_empty(), "malformed checksum ignored (falls back to the browser)")
	var path := "user://test_update_hash.bin"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("respeitavel")
	file.close()
	var expected := "respeitavel".sha256_text()
	check(GameUpdates.verify_file(path, expected), "downloaded file accepted when the checksum matches")
	check(not GameUpdates.verify_file(path, "00".repeat(32)), "downloaded file rejected when the checksum differs")
	check(not GameUpdates.verify_file(path, ""), "no checksum, no install")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## Windows: o .exe novo sai do ZIP e troca de lugar com o que está rodando (que vira .old).
func _test_windows_swap() -> void:
	var folder := ProjectSettings.globalize_path("user://test_swap")
	DirAccess.make_dir_recursive_absolute(folder)
	var exe := folder.path_join("RespeitavelPublico.exe")
	var zip_path := "user://test_swap/update.zip"
	_write(exe, "velho")
	var packer := ZIPPacker.new()
	packer.open(ProjectSettings.globalize_path(zip_path))
	packer.start_file("RespeitavelPublico/RespeitavelPublico.exe")
	packer.write_file("novo".to_utf8_buffer())
	packer.close_file()
	packer.close()
	var error := GameUpdates.install_windows(zip_path, exe)
	check(error == "", "windows update installed (%s)" % error)
	check(FileAccess.get_file_as_string(exe) == "novo", "new .exe takes the place of the old one")
	check(FileAccess.get_file_as_string(exe + GameUpdates.OLD_SUFFIX) == "velho", "running .exe kept as .old until the next start")
	check(not FileAccess.file_exists(zip_path), "downloaded ZIP removed after installing")
	_write(exe, "velho")
	packer = ZIPPacker.new()
	packer.open(ProjectSettings.globalize_path(zip_path))
	packer.start_file("RespeitavelPublico/outro.txt")
	packer.write_file("x".to_utf8_buffer())
	packer.close_file()
	packer.close()
	error = GameUpdates.install_windows(zip_path, exe)
	check(error != "" and FileAccess.get_file_as_string(exe) == "velho", "ZIP without the game leaves the installed .exe untouched")
	for name in ["RespeitavelPublico.exe", "RespeitavelPublico.exe.old", "RespeitavelPublico.exe.new", "update.zip"]:
		DirAccess.remove_absolute(folder.path_join(name))
	DirAccess.remove_absolute(folder)


func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()

func apply(data: Dictionary, target: String) -> void:
	offered = false
	message = ""
	GameUpdates.download_url = ""
	GameUpdates._apply_manifest(JSON.stringify(data).to_utf8_buffer(), target)

func check(ok: bool, label: String) -> void:
	print("%s %s" % ["OK" if ok else "FAIL", label])
	if not ok:
		failures += 1
