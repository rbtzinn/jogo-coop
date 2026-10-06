extends Node
## Compras, doações de ingressos e equipamento (autoload "Shop"). Quem decide é quem guarda o
## save (o host, ou o jogo sozinho): confere se pode, muda o save, salva e manda a cópia para
## o cliente. O cliente só pede e espera a resposta (sinal `done`).
## Jogadores são guardados pelo personagem: "clown" (jogador 1, host) e "acrobat" (jogador 2).

## Uma operação terminou. `ok` falso traz o motivo em `message` (sem_ingressos, ja_tem...).
signal done(operation: String, ok: bool, message: String)


## Personagem de cada lugar de jogador (0 = jogador 1, 1 = jogador 2).
const PLAYER_KEYS_BY_SLOT := ["clown", "acrobat"]


## Personagem de um jogador da cena (Player_1 = palhaço, o outro = acrobata).
static func key_for(player: Node) -> String:
	return "clown" if String(player.name) == "Player_1" else "acrobat"


static func partner_key(key: String) -> String:
	return "acrobat" if key == "clown" else "clown"


## Personagens que este PC controla (sozinho, o escolhido; offline dos testes, os dois).
func local_keys() -> Array[String]:
	if not Network.is_online():
		if PlayerSpawner.solo_slot >= 0:
			return [PLAYER_KEYS_BY_SLOT[PlayerSpawner.solo_slot]]
		return ["clown", "acrobat"]
	return ["clown"] if Network.is_host() else ["acrobat"]


func tickets(key: String) -> int:
	return int(SaveGame.data.players[key].tickets)


func owns(key: String, item_id: String) -> bool:
	return item_id in SaveGame.data.players[key].items


func equipped(key: String, slot: String) -> String:
	return SaveGame.data.players[key].equipped.get(slot, "")


func buy(key: String, item_id: String) -> void:
	_request(&"buy", [key, item_id])


func gift(from_key: String, amount: int) -> void:
	_request(&"gift", [from_key, amount])


func equip(key: String, slot: String, item_id: String) -> void:
	_request(&"equip", [key, slot, item_id])


func _request(operation: StringName, values: Array) -> void:
	if SaveGame.is_keeper():
		var error := _apply(operation, values)
		done.emit(String(operation), error.is_empty(), error)
	else:
		_receive_request.rpc_id(1, operation, values)


@rpc("any_peer", "call_remote", "reliable")
func _receive_request(operation: StringName, values: Array) -> void:
	var sender := multiplayer.get_remote_sender_id()
	Network.deliver(_answer.bind(sender, operation, values), false)


func _answer(sender: int, operation: StringName, values: Array) -> void:
	# O cliente só mexe na própria carteira e no próprio equipamento.
	var error := "nao_pode" if values.is_empty() or values[0] != "acrobat" else _apply(operation, values)
	_receive_answer.rpc_id(sender, String(operation), error)


@rpc("authority", "call_remote", "reliable")
func _receive_answer(operation: String, error: String) -> void:
	Network.deliver(func() -> void: done.emit(operation, error.is_empty(), error), false)


## Faz a operação no save (só no host ou sozinho). Retorna "" se deu certo, ou o motivo.
func _apply(operation: StringName, values: Array) -> String:
	var key: String = values[0]
	if not SaveGame.data.players.has(key):
		return "nao_pode"
	var player: Dictionary = SaveGame.data.players[key]
	match operation:
		&"buy":
			var item_id: String = values[1]
			var item := Catalog.item(item_id)
			if item.is_empty():
				return "nao_pode"
			if item_id in player.items:
				return "ja_tem"
			if int(player.tickets) < int(item.price):
				return "sem_ingressos"
			player.tickets = int(player.tickets) - int(item.price)
			player.items.append(item_id)
		&"gift":
			var amount: int = values[1]
			if amount <= 0 or amount > int(player.tickets):
				return "sem_ingressos"
			var partner: Dictionary = SaveGame.data.players[partner_key(key)]
			player.tickets = int(player.tickets) - amount
			partner.tickets = int(partner.tickets) + amount
		&"equip":
			var slot: String = values[1]
			var item_id: String = values[2]
			if slot not in Catalog.SLOTS:
				return "nao_pode"
			if item_id.is_empty():
				if slot not in Catalog.OPTIONAL_SLOTS:
					return "nao_pode"
			elif item_id not in player.items or Catalog.item(item_id).get("slot", "") != slot:
				return "nao_pode"
			player.equipped[slot] = item_id
		_:
			return "nao_pode"
	SaveGame.save_game()
	SaveGame.share()
	SaveGame.changed.emit()
	return ""
