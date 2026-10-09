class_name OnlineConfig
extends RefCounted
## RELAY_URL points at the room relay (server/, hosted on Render). Empty keeps the IP connection.
## Updates come from the GitHub releases published by .github/workflows/android-online.yml.
const RELAY_URL := "wss://respeitavel-publico-relay.onrender.com/relay"
const RELEASES_URL := "https://github.com/rbtzinn/jogo-coop/releases"
const UPDATE_URL := RELEASES_URL + "/latest/download/version.json"
const ANDROID_PACKAGE := "com.rbtzinn.respeitavelpublico.beta"
const VERSION_CODE := 4
const VERSION_NAME := "0.4"

static func relay_url() -> String:
	# Environment override only exists in developer builds and integration tests.
	if OS.has_feature("debug") and OS.has_environment("GAME_RELAY_URL"):
		return OS.get_environment("GAME_RELAY_URL")
	return RELAY_URL
