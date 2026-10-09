class_name OnlineConfig
extends RefCounted
## Set these to the same HTTPS host before building the public Android release.
## Empty endpoints keep the beta honest: it never connects to an invented server.
const RELAY_URL := ""
const UPDATE_URL := ""
const ANDROID_PACKAGE := "com.rbtzinn.respeitavelpublico.beta"
const VERSION_CODE := 3
const VERSION_NAME := "0.3-android-online"

static func relay_url() -> String:
	# Environment override only exists in developer builds and integration tests.
	if OS.has_feature("debug") and OS.has_environment("GAME_RELAY_URL"):
		return OS.get_environment("GAME_RELAY_URL")
	return RELAY_URL
