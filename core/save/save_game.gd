extends Node
## Save do jogo (autoload "SaveGame"), um arquivo JSON no PC de quem hospeda (ou de quem
## joga sozinho): chefões vencidos com a melhor nota e o melhor tempo, área atual, e a
## carteira de ingressos, os itens e o equipamento de cada jogador.
## Salva sozinho ao vencer um chefão e ao voltar para o mapa.
## O cliente online não salva nada: o save é do host, que manda uma cópia para o cliente mostrar
## (notas no mapa, ingressos).

## O save mudou (compra, doação, equipamento ou cópia nova vinda do host).
signal changed

const VERSION := 1
## Ingressos (docs/shop.md), para cada jogador.
const TICKETS_FIRST_WIN := 3
const TICKETS_FIRST_A := 1
const TICKETS_FIRST_S := 1
## Cada jogador é guardado pelo personagem (palhaço = jogador 1, acrobata = jogador 2).
const PLAYER_KEYS := ["clown", "acrobat"]

const MAIN_PATH := "user://save.json"
## Modo de teste ("Testar sozinho" no menu, pedido do usuário em 05/10/2026): save à parte, todas as
## atrações abertas, ingressos de sobra e muita vida nas lutas. "Jogar sozinho" e online usam o save normal.
const TEST_PATH := "user://test_save.json"
const TEST_TICKETS := 999

## Os testes trocam o caminho para não mexer no save de verdade.
var path := MAIN_PATH
var test_mode := false
var data := {}
## Cópia que veio do host (cliente online): nunca é gravada no disco.
var _borrowed := false


func _ready() -> void:
	load_game()
	Network.peer_ready.connect(_on_peer_ready)
	# O host manda a cópia assim que o parceiro conecta, antes da ordem de carregar a fase:
	# assim os jogadores dele já nascem com o equipamento certo.
	Network.partner_connected.connect(_on_peer_ready)


func load_game() -> void:
	_borrowed = false
	data = _new_game()
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var loaded: Variant = JSON.parse_string(file.get_as_text())
	if loaded is Dictionary and loaded.get("version", 0) == VERSION:
		_merge(data, loaded)


func save_game() -> void:
	if _borrowed:
		return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Não consegui salvar em %s" % path)
		return
	file.store_string(JSON.stringify(data, "\t"))


## Liga o modo de teste: troca para o save de teste e enche as carteiras.
func start_test_mode() -> void:
	test_mode = true
	path = TEST_PATH
	load_game()
	for key in PLAYER_KEYS:
		data.players[key].tickets = maxi(int(data.players[key].tickets), TEST_TICKETS)
	save_game()
	changed.emit()


## Volta para o save de verdade (jogar sozinho ou online), se o modo de teste estava ligado.
func start_normal() -> void:
	if not test_mode:
		return
	test_mode = false
	path = MAIN_PATH
	load_game()
	changed.emit()


## Quem guarda o save nesta partida: o host, ou o jogo sozinho.
func is_keeper() -> bool:
	return not Network.is_online() or Network.is_host()


## Vitória contra um chefão: atualiza recordes, dá ingressos aos dois e salva.
## Retorna o que mudou, para a tela de fim mostrar: {"tickets", "first_win", "best_grade", "best_time"}.
func record_victory(boss_id: String, grade: String, time: float) -> Dictionary:
	var boss: Dictionary = data.bosses.get(boss_id, {"defeated": false, "best_grade": "", "best_time": 0.0})
	var tickets := 0
	var first_win: bool = not boss.defeated
	if first_win:
		tickets += TICKETS_FIRST_WIN
	var old_rank := FightGrade.rank(boss.best_grade)
	var new_rank := FightGrade.rank(grade)
	if new_rank >= FightGrade.rank("A") and old_rank < FightGrade.rank("A"):
		tickets += TICKETS_FIRST_A
	if new_rank >= FightGrade.rank("S") and old_rank < FightGrade.rank("S"):
		tickets += TICKETS_FIRST_S
	var best_grade := new_rank > old_rank
	var best_time: bool = first_win or time < boss.best_time
	boss.defeated = true
	if best_grade:
		boss.best_grade = grade
	if best_time:
		boss.best_time = time
	data.bosses[boss_id] = boss
	for key in PLAYER_KEYS:
		data.players[key].tickets += tickets
	if is_keeper():
		save_game()
		share()
	return {"tickets": tickets, "first_win": first_win, "best_grade": best_grade, "best_time": best_time}


## Fase de plataforma concluída (conta como "vencida" para os cadeados do mapa) e salva.
## Retorna {"first_win"}.
func record_level(level_id: String) -> Dictionary:
	var first_win := not is_defeated(level_id)
	var level: Dictionary = data.bosses.get(level_id, {"defeated": false, "best_grade": "", "best_time": 0.0})
	level.defeated = true
	data.bosses[level_id] = level
	if is_keeper():
		save_game()
		share()
	return {"first_win": first_win}


## Ingresso escondido achado numa fase. Na primeira vez, +1 para cada jogador. Retorna se era novo.
func record_ticket(ticket_id: String) -> bool:
	var found: Array = data.get("found_tickets", [])
	if ticket_id in found:
		return false
	found.append(ticket_id)
	data.found_tickets = found
	for key in PLAYER_KEYS:
		data.players[key].tickets += 1
	if is_keeper():
		save_game()
		share()
	return true


func has_ticket(ticket_id: String) -> bool:
	return ticket_id in data.get("found_tickets", [])


func is_defeated(boss_id: String) -> bool:
	return data.bosses.get(boss_id, {}).get("defeated", false)


## Host: manda a cópia do save para o parceiro.
func share() -> void:
	if Network.is_online() and Network.is_host():
		for peer_id in Network.ready_peers:
			_receive_data.rpc_id(peer_id, data)


func _on_peer_ready(peer_id: int) -> void:
	if Network.is_host():
		_receive_data.rpc_id(peer_id, data)


@rpc("authority", "call_remote", "reliable")
func _receive_data(value: Dictionary) -> void:
	data = value
	_borrowed = true
	changed.emit()


## Apaga o progresso (começar do zero).
func reset() -> void:
	data = _new_game()
	save_game()


static func _new_game() -> Dictionary:
	var players := {}
	for key in PLAYER_KEYS:
		players[key] = {
			"tickets": 0,
			# Itens iniciais (docs/shop.md): pistola Rolha e truque Cambalhota.
			"items": ["cork_gun", "tumble"],
			"equipped": {"gun": "cork_gun", "trick": "tumble", "prop": "", "duo": ""},
		}
	return {"version": VERSION, "area": 1, "bosses": {}, "found_tickets": [], "players": players}


## Copia o que veio do arquivo por cima do jogo novo (campos novos ganham o valor padrão).
static func _merge(target: Dictionary, source: Dictionary) -> void:
	for key in source:
		if target.has(key) and target[key] is Dictionary and source[key] is Dictionary:
			_merge(target[key], source[key])
		else:
			target[key] = source[key]
