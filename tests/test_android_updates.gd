extends Node
## Remote update manifests are untrusted; never open a different package or host.
var failures := 0
var offered := false
var message := ""
const SOURCE := "https://game.example.com/api/android/latest"

func _ready() -> void:
	AndroidUpdates.update_available.connect(func(_version: String) -> void: offered = true)
	AndroidUpdates.status_changed.connect(func(text: String) -> void: message = text)
	var valid := {"package": OnlineConfig.ANDROID_PACKAGE, "version_code": OnlineConfig.VERSION_CODE + 1,
		"version_name": "test", "download_url": "https://game.example.com/downloads/game-4.apk"}
	apply(valid)
	check(offered and AndroidUpdates.download_url == valid.download_url, "new signed-package release offered from configured host")
	for patch in [
		{"package": "other.app"}, {"version_code": "999"}, {"version_code": 3.5}, {"version_code": -1},
		{"version_code": 2100000000}, {"download_url": "http://game.example.com/downloads/game.apk"},
		{"download_url": "https://game.example.com.attacker.test/downloads/game.apk"},
		{"download_url": "https://game.example.com/downloads/../../game.apk"},
		{"download_url": "https://game.example.com/downloads/game.apk?redirect=other"},
	]:
		var invalid := valid.duplicate()
		invalid.merge(patch, true)
		apply(invalid)
		check(not offered and AndroidUpdates.download_url.is_empty() and "inválida" in message, "invalid remote manifest rejected: %s" % str(patch))
	var current := valid.duplicate()
	current.version_code = OnlineConfig.VERSION_CODE
	apply(current)
	check(not offered and "mais recente" in message, "installed version is not offered again")
	AndroidUpdates._apply_manifest("null".to_utf8_buffer(), SOURCE)
	check(not offered and "inválida" in message, "non-object JSON rejected")
	print("FAILURES: %d" % failures)
	get_tree().quit(failures)

func apply(data: Dictionary) -> void:
	offered = false
	message = ""
	AndroidUpdates.download_url = ""
	AndroidUpdates._apply_manifest(JSON.stringify(data).to_utf8_buffer(), SOURCE)

func check(ok: bool, label: String) -> void:
	print("%s %s" % ["OK" if ok else "FAIL", label])
	if not ok:
		failures += 1
