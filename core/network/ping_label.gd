extends Label
## Mostra o ping até o parceiro (liga/desliga em Configurações > Rede). Só aparece online.

const UPDATE_INTERVAL := 0.5

var _timer := 0.0


func _process(delta: float) -> void:
	visible = Settings.show_ping and Network.is_online()
	if not visible:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = UPDATE_INTERVAL
	var ping := Network.get_ping_ms()
	if ping < 0:
		text = "Ping: —"
		return
	text = "Ping: %d ms" % ping
	if Network.simulated_ping_ms() > 0:
		text += "  (+%d simulado)" % Network.simulated_ping_ms()
