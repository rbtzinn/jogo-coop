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
	print("FAILURES: %d" % failures)
	get_tree().quit(failures)

func apply(data: Dictionary, target: String) -> void:
	offered = false
	message = ""
	GameUpdates.download_url = ""
	GameUpdates._apply_manifest(JSON.stringify(data).to_utf8_buffer(), target)

func check(ok: bool, label: String) -> void:
	print("%s %s" % ["OK" if ok else "FAIL", label])
	if not ok:
		failures += 1
