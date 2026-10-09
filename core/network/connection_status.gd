extends Label
## Aviso no topo da tela sobre a conexão: esperando o parceiro (com os IPs deste PC)
## ou "o parceiro saiu". Some sozinho quando está tudo certo.

const MESSAGE_TIME := 5.0

var _message_timer := 0.0


func _ready() -> void:
	Network.partner_connected.connect(func(_id: int) -> void: _refresh())
	Network.partner_disconnected.connect(_on_partner_disconnected)
	_refresh()


func _process(delta: float) -> void:
	if _message_timer > 0.0:
		_message_timer -= delta
		if _message_timer <= 0.0:
			_refresh()


func _refresh() -> void:
	if not Network.is_online() or not Network.is_host() or not multiplayer.get_peers().is_empty():
		text = ""
		return
	if not Network.room_code.is_empty():
		text = "Sala: %s\nPasse este código para o parceiro entrar." % Network.room_code
		return
	var addresses := Network.local_addresses()
	text = "Esperando o parceiro entrar...\nPasse um destes IPs para ele (porta %d):  %s" % [
		Network.DEFAULT_PORT, "   ".join(addresses) if not addresses.is_empty() else "127.0.0.1"]


func _on_partner_disconnected(_id: int) -> void:
	_refresh()
	text = "O parceiro saiu da partida.\n" + text
	_message_timer = MESSAGE_TIME
